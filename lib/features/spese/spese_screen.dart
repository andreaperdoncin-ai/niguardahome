import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/spesa.dart';
import '../../models/categoria.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/spesa_provider.dart';
import '../../providers/categoria_provider.dart'; // <-- AGGIUNTO L'IMPORT
import 'aggiungi_spesa_screen.dart';

class SpeseScreen extends StatelessWidget {
  const SpeseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appartamentoAttivo = context.watch<AppStateProvider>().appartamentoAttivo;
    final spesaProvider = context.read<SpesaProvider>();

    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return StreamBuilder<List<Spesa>>(
      stream: spesaProvider.streamSpese(appartamentoAttivo.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        }

        final spese = snapshot.data ?? [];

        // PUNTO 1 E 6: CALCOLO TOTALI PER COMPETENZA
        double totaleMese = 0.0;
        double totaleAnno = 0.0;
        final now = DateTime.now();

        for (var spesa in spese) {
          // Aggiunge la quota del mese corrente in base alla data di inizio/fine competenza
          totaleMese += spesa.quotaPerMeseAnno(now.year, now.month);
          // Somma la quota di tutti i 12 mesi dell'anno corrente
          for (int m = 1; m <= 12; m++) {
            totaleAnno += spesa.quotaPerMeseAnno(now.year, m);
          }
        }

        // <-- AGGIUNTO LO STREAMBUILDER PER LE CATEGORIE DA FIREBASE -->
        return StreamBuilder<List<Categoria>>(
            stream: context.read<CategoriaProvider>().streamCategorie(),
            builder: (context, snapshotCat) {
              final categorie = snapshotCat.data ?? [];

              return Column(
                children: [
                  // BARRA DEI TOTALI IN ALTO
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Totale Mese', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(currencyFormat.format(totaleMese), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: Colors.white30),
                        Column(
                          children: [
                            const Text('Totale Anno', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(currencyFormat.format(totaleAnno), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // LISTA DELLE SPESE
                  Expanded(
                    child: spese.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Nessuna spesa per ${appartamentoAttivo.nome}.', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: spese.length,
                      itemBuilder: (context, index) {
                        final spesa = spese[index];

                        // <-- RISOLTO BUG: CERCA NELLA LISTA DI FIREBASE -->
                        final categoria = categorie.isNotEmpty
                            ? categorie.firstWhere(
                              (c) => c.id == spesa.idCategoria,
                          orElse: () => Categoria.categorieIniziali.first,
                        )
                            : Categoria.categorieIniziali.first;

                        return Dismissible(
                          key: Key(spesa.id),
                          direction: DismissDirection.horizontal, // Permette swipe in entrambe le direzioni
                          // PUNTO 7: SWIPE DA SINISTRA A DESTRA (MODIFICA)
                          background: Container(
                            color: Colors.blue.shade600,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                          // SWIPE DA DESTRA A SINISTRA (ELIMINA)
                          secondaryBackground: Container(
                            color: Theme.of(context).colorScheme.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Se ho swipato per modificare, apro la schermata e NON elimino la riga
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AggiungiSpesaScreen(spesaEsistente: spesa)),
                              );
                              return false;
                            } else {
                              // Se ho swipato per eliminare, chiedo conferma
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminare la spesa?'),
                                  content: Text('Sei sicuro di voler eliminare questa spesa in ${categoria.nome}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
                                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Elimina')),
                                  ],
                                ),
                              );
                            }
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              spesaProvider.eliminaSpesa(spesa.id);
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 1,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: categoria.color.withOpacity(0.15),
                                child: Icon(categoria.iconData, color: categoria.color),
                              ),
                              title: Text(categoria.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Pagato il ${dateFormat.format(spesa.dataPagamento)}\nComp: ${dateFormat.format(spesa.dataCompetenzaInizio)} - ${dateFormat.format(spesa.dataCompetenzaFine)}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(spesa.importo),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (spesa.kwh != null)
                                    Text('${spesa.kwh} kWh', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
        );
      },
    );
  }
}