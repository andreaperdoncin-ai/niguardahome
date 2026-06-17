import 'package:flutter/material.dart';
import 'gestione_categorie_screen.dart';
import 'offset_contatori_screen.dart';
import 'configurazione_periodo_screen.dart';
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
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
              const Divider(height: 1, indent: 70),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.calendar_month_outlined),
                ),
                title: const Text('Configurazione Periodo'),
                subtitle: const Text('Imposta il mese di inizio dell\'anno condominiale'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConfigurazionePeriodoScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // SEZIONE 2: CONTATORI
        Text(
          'Contatori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
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
                  child: Icon(Icons.tune_outlined),
                ),
                title: const Text('Offset Contatori'),
                subtitle: const Text('Imposta i valori di partenza per il calcolo dei consumi'),
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
        const SizedBox(height: 16),

        // SEZIONE 3: DATI E BACKUP
        Text(
          'Dati e Backup',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
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
                  child: Icon(Icons.download_for_offline_outlined),
                ),
                title: const Text('Esporta in CSV'),
                subtitle: const Text('Genera e condividi il file Excel/CSV con tutte le spese'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await generaECondividiCSV(context);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),

        // VERSIONE DELL'APP (STILE MINIMALISTA IN FONDO)
        Center(
          child: Column(
            children: [
              Text(
                'Niguarda Home',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Versione 2.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}