import 'package:flutter/material.dart';

import 'gestione_categorie_screen.dart';
import 'offset_contatori_screen.dart';
import 'esporta_csv.dart';

class ImpostazioniScreen extends StatelessWidget {
  const ImpostazioniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // SEZIONE 1: GESTIONE SPESE E CATEGORIE
        Text(
            'Spese e Categorie',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.category_outlined),
                ),
                title: const Text('Gestione Categorie'),
                subtitle: const Text('Aggiungi, rinomina e riordina le categorie di spesa'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GestioneCategorieScreen()),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // SEZIONE 2: IMPIANTI E CONTATORI
        Text(
            'Impianti e Contatori',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.speed_outlined),
                ),
                title: const Text('Valori di Partenza (Offset)'),
                subtitle: const Text('Imposta le letture iniziali per le case con impianti già avviati'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OffsetContatoriScreen()),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // SEZIONE 3: DATI E BACKUP
        Text(
            'Dati App',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.cloud_download_outlined),
                ),
                title: const Text('Esporta in CSV'),
                subtitle: const Text('Scarica i dati per visualizzarli su Excel'),
                onTap: () {
                  generaECondividiCSV(context);
                },
              ),
            ],
          ),
        ),

        // --- AGGIUNTA NUMERO DI VERSIONE QUI ---
        const SizedBox(height: 48), // Spazio per staccarlo dai menu
        const Center(
          child: Text(
            'Versione 1.2',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 1.2, // Un leggero stacco tra le lettere per eleganza
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}