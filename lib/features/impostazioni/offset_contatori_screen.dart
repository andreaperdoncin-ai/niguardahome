import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/lettura_provider.dart';
import '../../models/appartamento.dart';

class OffsetContatoriScreen extends StatefulWidget {
  const OffsetContatoriScreen({super.key});

  @override
  State<OffsetContatoriScreen> createState() => _OffsetContatoriScreenState();
}

class _OffsetContatoriScreenState extends State<OffsetContatoriScreen> {
  late String _idAppartamentoSelezionato;

  @override
  void initState() {
    super.initState();
    _idAppartamentoSelezionato = Provider.of<AppStateProvider>(context, listen: false).appartamentoAttivo.id;
  }

  @override
  Widget build(BuildContext context) {
    // Troviamo l'oggetto Appartamento esatto per essere sicuri dei contatori da mostrare
    final appartamento = Appartamento.all.firstWhere((a) => a.id == _idAppartamentoSelezionato);
    final bool completi = appartamento.nome.toLowerCase().contains('passerini');

    final Map<String, String> contatori = completi
        ? {'afs': 'Acqua Fredda (m³)', 'acs': 'Acqua Calda (m³)', 'riscaldamento': 'Riscaldamento (MWh)', 'raffrescamento': 'Raffrescamento (MWh)'}
        : {'afs': 'Acqua Fredda (m³)'};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Valori di Partenza'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Imposta le letture iniziali dei contatori. Per i nuovi impianti ti basta salvare lo 0.00 come partenza.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Seleziona Appartamento',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
            value: _idAppartamentoSelezionato,
            items: Appartamento.all.map((app) => DropdownMenuItem(value: app.id, child: Text(app.nome))).toList(),
            onChanged: (val) {
              setState(() {
                _idAppartamentoSelezionato = val!;
              });
            },
          ),
          const SizedBox(height: 24),

          // Generiamo i campi assegnando una Key univoca per forzare l'aggiornamento visivo
          ...contatori.entries.map((entry) => _RigaOffset(
            key: ValueKey('${_idAppartamentoSelezionato}_${entry.key}'),
            idAppartamento: _idAppartamentoSelezionato,
            tipo: entry.key,
            etichetta: entry.value,
          )),
        ],
      ),
    );
  }
}

class _RigaOffset extends StatefulWidget {
  final String idAppartamento;
  final String tipo;
  final String etichetta;

  const _RigaOffset({super.key, required this.idAppartamento, required this.tipo, required this.etichetta});

  @override
  State<_RigaOffset> createState() => _RigaOffsetState();
}

class _RigaOffsetState extends State<_RigaOffset> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letturaProvider = context.read<LetturaProvider>();

    return StreamBuilder<double?>(
      stream: letturaProvider.streamOffset(widget.idAppartamento, widget.tipo),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData && snapshot.data != null) {
            // Se c'è un valore salvato, lo mostriamo
            if (_controller.text.isEmpty || _controller.text == '0.00') {
              _controller.text = snapshot.data!.toStringAsFixed(2);
            }
          } else {
            // Se non c'è nulla, forziamo il default a 0
            if (_controller.text.isEmpty) {
              _controller.text = '0.00';
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(widget.etichetta, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.save, color: Theme.of(context).colorScheme.primary), // <-- TOLTO IL "const"
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          double valore = double.parse(_controller.text.replaceAll(',', '.'));
                          letturaProvider.salvaOffset(widget.idAppartamento, widget.tipo, valore);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Valore di ${widget.etichetta} salvato!')));
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}