import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appartamento.dart';
import '../../providers/app_state_provider.dart';

// I due nuovi import per collegare le funzionalità delle spese
import '../spese/spese_screen.dart';
import '../spese/aggiungi_spesa_screen.dart';

// I due nuovi import per collegare le funzionalità dei contatori
import '../contatori/letture_screen.dart';
import '../contatori/aggiungi_lettura_dialog.dart';

import '../impostazioni/impostazioni_screen.dart';

import '../statistiche/statistiche_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavigationIndex = 0;

  // Elenco dei titoli associati alle varie sezioni della navigazione
  final List<String> _titoliSezioni = [
    'Registro Spese',
    'Letture Contatori',
    'Analisi Statistiche',
    'Impostazioni App',
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final appartamentoAttivo = appState.appartamentoAttivo;

    // Definiamo i widget per il corpo centrale in base alla tab selezionata
    final List<Widget> sezioniEsistenti = [
      const SpeseScreen(),
      const LettureScreen(),
      const StatisticheScreen(), // <-- LA NOSTRA NUOVA SCHERMATA GRAFICI!
      const ImpostazioniScreen(),
    ];

    // Rilevamento della larghezza per l'interfaccia adattiva
    final double larghezzaSchermo = MediaQuery.sizeOf(context).width;
    final bool isTablet = larghezzaSchermo > 720;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titoliSezioni[_currentNavigationIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Selettore dell'appartamento nell'appBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: appartamentoAttivo.id,
                icon: const Icon(Icons.keyboard_arrow_down),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                onChanged: (String? idSelezionato) {
                  if (idSelezionato != null) {
                    final scelto = Appartamento.fromId(idSelezionato);
                    appState.cambiaAppartamento(scelto);
                  }
                },
                items: Appartamento.all.map<DropdownMenuItem<String>>((Appartamento app) {
                  return DropdownMenuItem<String>(
                    value: app.id,
                    child: Text(app.nome),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // NavigationRail laterale per schermi larghi (Tablet)
          if (isTablet) ...[
            NavigationRail(
              selectedIndex: _currentNavigationIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentNavigationIndex = index;
                });
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Spese'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.speed_outlined),
                  selectedIcon: Icon(Icons.speed),
                  label: Text('Contatori'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: Text('Statistiche'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Opzioni'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          // Contenuto principale della sezione selezionata
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: sezioniEsistenti[_currentNavigationIndex],
            ),
          ),
        ],
      ),
      // NavigationBar inferiore per schermi stretti (Smartphone)
      bottomNavigationBar: !isTablet
          ? NavigationBar(
        selectedIndex: _currentNavigationIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentNavigationIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Spese',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Contatori',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Statistiche',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Opzioni',
          ),
        ],
      )
          : null,

      // Pulsante Flottante per aggiungere una nuova spesa
      floatingActionButton: _currentNavigationIndex == 0 || _currentNavigationIndex == 1
          ? FloatingActionButton(
        onPressed: () {
          if (_currentNavigationIndex == 0) {
            // Siamo su Spese
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AggiungiSpesaScreen()));
          } else if (_currentNavigationIndex == 1) {
            // Siamo su Contatori
            mostraDialogAggiungiLettura(context);
          }
        },
        child: const Icon(Icons.add),
      )
          : null, // Nelle altre tab per ora nascondiamo il pulsante
    );
  }
}