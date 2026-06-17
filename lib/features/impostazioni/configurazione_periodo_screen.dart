import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../models/appartamento.dart';

class ConfigurazionePeriodoScreen extends StatefulWidget {
  const ConfigurazionePeriodoScreen({super.key});

  @override
  State<ConfigurazionePeriodoScreen> createState() => _ConfigurazionePeriodoScreenState();
}

class _ConfigurazionePeriodoScreenState extends State<ConfigurazionePeriodoScreen> {
  late String _idAppartamentoSelezionato;

  @override
  void initState() {
    super.initState();
    _idAppartamentoSelezionato = Provider.of<AppStateProvider>(context, listen: false).appartamentoAttivo.id;
  }

  String _getNomeMese(int mese) {
    return DateFormat('MMMM', 'it_IT').format(DateTime(2024, mese));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final appartamento = Appartamento.all.firstWhere((a) => a.id == _idAppartamentoSelezionato);
    
    // Il mese corrente impostato per l'appartamento selezionato
    // Se è quello attivo lo prendiamo da appState.appartamentoAttivo.meseInizioCondominiale
    // ma per semplicità e coerenza con la logica multiappartamento, sarebbe meglio
    // avere un getter o metodo nel provider che restituisce il mese per un ID specifico
    // senza dover cambiare l'appartamento attivo.
    // Tuttavia, AppStateProvider già gestisce _mesiInizioCondominiale internamente.
    // Usiamo il valore dell'appartamento attivo se l'ID coincide, altrimenti 1 (default).
    
    int meseInizio = 1;
    if (_idAppartamentoSelezionato == appState.appartamentoAttivo.id) {
      meseInizio = appState.appartamentoAttivo.meseInizioCondominiale;
    } else {
      // Fallback per altri appartamenti non attivi (legge dal provider se possibile)
      // In AppStateProvider non c'è un getter pubblico per la mappa, ma il getter 
      // appartamentoAttivo costruisce l'appartamento con il mese corretto.
      // Per ora, assumiamo che l'utente stia configurando l'appartamento che sta visualizzando
      // o aggiungiamo un getter veloce se serve.
      meseInizio = appState.appartamentoAttivo.meseInizioCondominiale; 
    }

    int meseFine = meseInizio - 1;
    if (meseFine == 0) meseFine = 12;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurazione Periodo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Definisci quando inizia l\'anno contabile (condominiale) per questo appartamento. Questo influenzerà i grafici nelle statistiche.',
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

          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Anno Condominiale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Mese di Inizio',
                      border: OutlineInputBorder(),
                    ),
                    value: meseInizio,
                    items: List.generate(12, (index) => index + 1).map((m) {
                      String nome = _getNomeMese(m);
                      return DropdownMenuItem(value: m, child: Text(nome[0].toUpperCase() + nome.substring(1)));
                    }).toList(),
                    onChanged: (nuovoMese) {
                      if (nuovoMese != null) {
                        appState.aggiornaMeseInizioCondominiale(_idAppartamentoSelezionato, nuovoMese);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Il periodo sarà: ${_getNomeMese(meseInizio)} - ${_getNomeMese(meseFine)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
