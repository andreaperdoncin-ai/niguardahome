import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/lettura.dart';
import '../../providers/lettura_provider.dart';
import '../../providers/app_state_provider.dart';

// MODIFICA: Ora la funzione accetta opzionalmente una Lettura esistente
void mostraDialogAggiungiLettura(BuildContext context, {Lettura? letturaEsistente}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: _FormLettura(letturaEsistente: letturaEsistente),
    ),
  );
}

class _FormLettura extends StatefulWidget {
  final Lettura? letturaEsistente;
  const _FormLettura({this.letturaEsistente});

  @override
  State<_FormLettura> createState() => _FormLetturaState();
}

class _FormLetturaState extends State<_FormLettura> {
  late TextEditingController _valoreController;
  late TextEditingController _noteController;
  late DateTime _dataLettura;
  String? _tipoSelezionato;

  @override
  void initState() {
    super.initState();
    final l = widget.letturaEsistente;

    // Se stiamo modificando, precompilamo i campi con i valori esistenti
    _valoreController = TextEditingController(text: l != null ? l.valore.toString() : '');
    _noteController = TextEditingController(text: l?.note ?? '');
    _dataLettura = l?.dataLettura ?? DateTime.now();
    _tipoSelezionato = l?.tipo;
  }

  @override
  void dispose() {
    _valoreController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final bool completi = appState.mostraContatoriCalore;

    final Map<String, String> tipiDisponibili = completi
        ? {'afs': 'Acqua Fredda', 'acs': 'Acqua Calda', 'riscaldamento': 'Riscaldamento', 'raffrescamento': 'Raffrescamento'}
        : {'afs': 'Acqua Fredda (AFS)'};

    if (!completi && _tipoSelezionato == null) _tipoSelezionato = 'afs';

    final dateFormat = DateFormat('dd/MM/yyyy');
    final bool isModifica = widget.letturaEsistente != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isModifica ? 'Modifica Lettura' : 'Nuova Lettura',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Tipo Contatore', border: OutlineInputBorder()),
          value: _tipoSelezionato,
          items: tipiDisponibili.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          // Se stiamo modificando, blocchiamo il cambio del tipo per evitare casini nel database
          onChanged: isModifica ? null : (val) => setState(() => _tipoSelezionato = val),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _valoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valore', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: ListTile(
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                title: const Text('Data', style: TextStyle(fontSize: 12)),
                subtitle: Text(dateFormat.format(_dataLettura), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final scelta = await showDatePicker(
                    context: context, initialDate: _dataLettura, firstDate: DateTime(2020), lastDate: DateTime.now(), locale: const Locale('it', 'IT'),
                  );
                  if (scelta != null) setState(() => _dataLettura = scelta);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: 'Note (opzionale)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () {
            if (_tipoSelezionato != null && _valoreController.text.isNotEmpty) {
              final lettura = Lettura(
                // Se è una modifica, passiamo il VECCHIO ID, così Firebase lo sovrascrive invece di crearne uno nuovo!
                id: widget.letturaEsistente?.id ?? '',
                idAppartamento: appState.appartamentoAttivo.id,
                tipo: _tipoSelezionato!,
                valore: double.parse(_valoreController.text.replaceAll(',', '.')),
                dataLettura: _dataLettura,
                note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
              );
              context.read<LetturaProvider>().salvaLettura(lettura);
              Navigator.pop(context);
            }
          },
          child: Text(isModifica ? 'AGGIORNA LETTURA' : 'SALVA LETTURA'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}