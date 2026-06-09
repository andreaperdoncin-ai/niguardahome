import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/categoria.dart';
import '../../providers/categoria_provider.dart';

class GestioneCategorieScreen extends StatefulWidget {
  const GestioneCategorieScreen({super.key});

  @override
  State<GestioneCategorieScreen> createState() => _GestioneCategorieScreenState();
}

class _GestioneCategorieScreenState extends State<GestioneCategorieScreen> {
// Lista di icone predefinite utili per l'app
  final List<IconData> _iconeDisponibili = [
    Icons.label_important,
    Icons.cleaning_services, // Pulizie
    Icons.sanitizer,         // Igienizzante (al posto del mocio)
    Icons.wash,              // Lavaggio
    Icons.home,
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.local_fire_department,
    Icons.wifi,
    Icons.directions_car,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.pets,
    Icons.health_and_safety,
    Icons.build,
    Icons.school,
    Icons.flight,
    Icons.receipt_long,
  ];

  // Finestra a comparsa per aggiungere o rinominare una categoria
  void _mostraDialog(BuildContext context, {Categoria? categoria}) {
    final nomeController = TextEditingController(text: categoria?.nome ?? '');

    int colorValue = categoria?.colorValue ?? Colors.blueGrey.value;
    int iconCode = categoria?.iconCodePoint ?? Icons.label_important.codePoint;
    List<String> target = categoria?.targetAppartamenti ?? ['app_passerini', 'app_frugoni'];

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder è necessario per aggiornare l'icona selezionata dentro il dialog
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(categoria == null ? 'Nuova Categoria' : 'Modifica Categoria'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Categoria',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 24),
                      const Text('Seleziona un\'icona:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _iconeDisponibili.map((icona) {
                          final isSelected = icona.codePoint == iconCode;
                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              setStateDialog(() {
                                iconCode = icona.codePoint;
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                icona,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nomeController.text.trim().isNotEmpty) {
                        final nuovaCat = Categoria(
                          id: categoria?.id ?? '', // Se è vuoto, Firebase ne genera uno nuovo
                          nome: nomeController.text.trim(),
                          iconCodePoint: iconCode,
                          colorValue: colorValue,
                          targetAppartamenti: target,
                          ordine: categoria?.ordine ?? 99, // Finirà in fondo
                        );
                        context.read<CategoriaProvider>().salvaCategoria(nuovaCat);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Salva'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Categorie'),
      ),
      body: StreamBuilder<List<Categoria>>(
        stream: context.read<CategoriaProvider>().streamCategorie(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          final categorie = snapshot.data ?? [];

          if (categorie.isEmpty) {
            return const Center(child: Text('Nessuna categoria presente.'));
          }

          // Lista speciale che permette il Drag & Drop
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 88, top: 8),
            itemCount: categorie.length,
            onReorder: (oldIndex, newIndex) {
              // Flutter richiede questo piccolo aggiustamento logico negli indici
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = categorie.removeAt(oldIndex);
              categorie.insert(newIndex, item);

              // Salviamo immediatamente il nuovo ordine sul cloud!
              context.read<CategoriaProvider>().aggiornaOrdine(categorie);
            },
            itemBuilder: (context, index) {
              final cat = categorie[index];
              return Card(
                key: ValueKey(cat.id), // Fondamentale per il Drag&Drop
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cat.color.withOpacity(0.15),
                    child: Icon(cat.iconData, color: cat.color),
                  ),
                  title: Text(cat.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => _mostraDialog(context, categoria: cat),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        onPressed: () {
                          context.read<CategoriaProvider>().eliminaCategoria(cat.id);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.drag_indicator, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostraDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuova'),
      ),
    );
  }
}