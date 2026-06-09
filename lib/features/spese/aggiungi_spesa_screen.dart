import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/spesa.dart';
import '../../models/categoria.dart';
import '../../models/appartamento.dart';
import '../../providers/spesa_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../providers/app_state_provider.dart';

class AggiungiSpesaScreen extends StatefulWidget {
  final Spesa? spesaEsistente;

  const AggiungiSpesaScreen({super.key, this.spesaEsistente});

  @override
  State<AggiungiSpesaScreen> createState() => _AggiungiSpesaScreenState();
}

class _AggiungiSpesaScreenState extends State<AggiungiSpesaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _importoController = TextEditingController();
  final _noteController = TextEditingController();
  final _kwhController = TextEditingController();

  String? _categoriaSelezionata;
  late String _appartamentoSelezionato;

  late DateTime _dataPagamento;
  late DateTime _dataCompetenzaInizio;
  late DateTime _dataCompetenzaFine;

  // Logica Spesa Ricorrente
  bool _isRicorrente = false;
  int _mesiRipetizione = 12;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();

    final appAttivo = Provider.of<AppStateProvider>(context, listen: false).appartamentoAttivo;

    if (widget.spesaEsistente != null) {
      final s = widget.spesaEsistente!;
      _importoController.text = s.importo.toStringAsFixed(2).replaceAll('.', ',');
      _noteController.text = s.note ?? '';
      _kwhController.text = s.kwh?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      _categoriaSelezionata = s.idCategoria;
      _appartamentoSelezionato = s.idAppartamento;
      _dataPagamento = s.dataPagamento;
      _dataCompetenzaInizio = s.dataCompetenzaInizio;
      _dataCompetenzaFine = s.dataCompetenzaFine;
    } else {
      _appartamentoSelezionato = appAttivo.id;
      _dataPagamento = DateTime.now();
      _dataCompetenzaInizio = DateTime(DateTime.now().year, DateTime.now().month, 1);
      _dataCompetenzaFine = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    }
  }

  @override
  void dispose() {
    _importoController.dispose();
    _noteController.dispose();
    _kwhController.dispose();
    super.dispose();
  }

  Future<void> _selezionaData(BuildContext context, DateTime dataIniziale, Function(DateTime) onDataSelezionata) async {
    final DateTime? scelta = await showDatePicker(
      context: context,
      initialDate: dataIniziale,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (scelta != null) {
      setState(() {
        onDataSelezionata(scelta);
      });
    }
  }

  void _salva() {
    if (_formKey.currentState!.validate()) {
      if (_categoriaSelezionata == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleziona una categoria')));
        return;
      }

      double importo = double.parse(_importoController.text.replaceAll(',', '.'));
      double? kwh = _kwhController.text.isNotEmpty ? double.tryParse(_kwhController.text.replaceAll(',', '.')) : null;

      int iterazioni = _isRicorrente ? _mesiRipetizione : 1;

      for (int i = 0; i < iterazioni; i++) {
        // Calcoliamo lo slittamento dei mesi per le spese ricorrenti
        DateTime inizio = DateTime(_dataCompetenzaInizio.year, _dataCompetenzaInizio.month + i, _dataCompetenzaInizio.day);
        // La fine calcola automaticamente l'ultimo giorno del mese slittato se l'originale era a fine mese
        DateTime fine = DateTime(_dataCompetenzaFine.year, _dataCompetenzaFine.month + i, _dataCompetenzaFine.day);
        DateTime pagamento = DateTime(_dataPagamento.year, _dataPagamento.month + i, _dataPagamento.day);

        final spesa = Spesa(
          id: widget.spesaEsistente?.id ?? '', // Se è ricorrente, lascerà generare nuovi ID a Firebase
          idAppartamento: _appartamentoSelezionato,
          idCategoria: _categoriaSelezionata!,
          importo: importo,
          dataPagamento: pagamento,
          dataCompetenzaInizio: inizio,
          dataCompetenzaFine: fine,
          note: iterazioni > 1 ? '${_noteController.text.trim()} (Rata ${i + 1}/$iterazioni)' : _noteController.text.trim(),
          kwh: kwh,
        );

        context.read<SpesaProvider>().salvaSpesa(spesa);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spesaEsistente == null ? 'Nuova Spesa' : 'Modifica Spesa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. APPARTAMENTO
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Appartamento', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
              value: _appartamentoSelezionato,
              items: Appartamento.all.map((app) => DropdownMenuItem(value: app.id, child: Text(app.nome))).toList(),
              onChanged: (val) { if (val != null) setState(() => _appartamentoSelezionato = val); },
            ),
            const SizedBox(height: 16),

            // 2. CATEGORIA (Gestione robusta per evitare bug salvataggio)
            StreamBuilder<List<Categoria>>(
                stream: context.read<CategoriaProvider>().streamCategorie(),
                builder: (context, snapshot) {
                  final categorie = snapshot.data ?? [];

                  // Sicurezza: se la categoria selezionata non esiste più, resettala
                  if (_categoriaSelezionata != null && categorie.isNotEmpty) {
                    bool esiste = categorie.any((c) => c.id == _categoriaSelezionata);
                    if (!esiste) _categoriaSelezionata = null;
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                    value: _categoriaSelezionata,
                    onChanged: categorie.isEmpty ? null : (val) => setState(() => _categoriaSelezionata = val),
                    items: categorie.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.nome))).toList(),
                    validator: (value) => value == null ? 'Seleziona una categoria' : null,
                  );
                }
            ),
            const SizedBox(height: 16),

            // 3. IMPORTO
            TextFormField(
              controller: _importoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Importo (€)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.euro)),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Inserisci l\'importo';
                if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Importo non valido';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 4. DATA PAGAMENTO E COMPETENZA
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade400)),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data Pagamento'),
              subtitle: Text(_dateFormat.format(_dataPagamento), style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => _selezionaData(context, _dataPagamento, (data) => _dataPagamento = data),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade400)),
                    title: const Text('Competenza Dal', style: TextStyle(fontSize: 12)),
                    subtitle: Text(_dateFormat.format(_dataCompetenzaInizio), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _selezionaData(context, _dataCompetenzaInizio, (data) => _dataCompetenzaInizio = data),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade400)),
                    title: const Text('Competenza Al', style: TextStyle(fontSize: 12)),
                    subtitle: Text(_dateFormat.format(_dataCompetenzaFine), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _selezionaData(context, _dataCompetenzaFine, (data) => _dataCompetenzaFine = data),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. KWH (Visibile SOLO se la categoria scelta è Elettricità/Luce)
            StreamBuilder<List<Categoria>>(
                stream: context.read<CategoriaProvider>().streamCategorie(),
                builder: (context, snapshot) {
                  final categorie = snapshot.data ?? [];
                  String nomeCat = '';

                  if (_categoriaSelezionata != null && categorie.isNotEmpty) {
                    try {
                      nomeCat = categorie.firstWhere((c) => c.id == _categoriaSelezionata).nome.toLowerCase();
                    } catch (_) {}
                  }

                  bool mostraKwh = nomeCat.contains('elettricità') || nomeCat.contains('luce') || _categoriaSelezionata == 'cat_elettricita';

                  if (!mostraKwh) return const SizedBox.shrink();

                  return Column(
                    children: [
                      TextFormField(
                        controller: _kwhController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Consumo (kWh) - Opzionale', border: OutlineInputBorder(), prefixIcon: Icon(Icons.bolt)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
            ),

            // 6. SPESA RICORRENTE
            if (widget.spesaEsistente == null) ...[
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Spesa Ricorrente'),
                      subtitle: const Text('Es. Abbonamento Internet mensile'),
                      value: _isRicorrente,
                      onChanged: (val) => setState(() => _isRicorrente = val),
                    ),
                    if (_isRicorrente)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Row(
                          children: [
                            const Text('Per quanti mesi?'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Slider(
                                value: _mesiRipetizione.toDouble(),
                                min: 2,
                                max: 24,
                                divisions: 22,
                                label: _mesiRipetizione.toString(),
                                onChanged: (val) => setState(() => _mesiRipetizione = val.toInt()),
                              ),
                            ),
                            Text('$_mesiRipetizione', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 7. NOTE
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (Opzionale)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // BOTTONE SALVA
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _salva,
                icon: const Icon(Icons.save),
                label: const Text('SALVA SPESA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}