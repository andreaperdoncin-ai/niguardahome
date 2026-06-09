import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/spesa_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../models/spesa.dart';
import '../../models/categoria.dart';

class StatisticheScreen extends StatefulWidget {
  const StatisticheScreen({super.key});

  @override
  State<StatisticheScreen> createState() => _StatisticheScreenState();
}

class _StatisticheScreenState extends State<StatisticheScreen> {
  int _annoSelezionato = DateTime.now().year;

  // Usa la formattazione italiana: punto per le migliaia, virgola per i decimali
  String _formattaValore(double valore) {
    final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '');
    return formatter.format(valore).trim();
  }

  @override
  Widget build(BuildContext context) {
    final appartamentoAttivo = context.watch<AppStateProvider>().appartamentoAttivo;

    return StreamBuilder<List<Spesa>>(
        stream: context.read<SpesaProvider>().streamSpese(appartamentoAttivo.id),
        builder: (context, snapshotSpese) {
          return StreamBuilder<List<Categoria>>(
              stream: context.read<CategoriaProvider>().streamCategorie(),
              builder: (context, snapshotCat) {

                if (!snapshotSpese.hasData || !snapshotCat.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final spese = snapshotSpese.data!;
                final categorie = snapshotCat.data!;

                Map<String, double> totaliPerCategoria = {};

                // Struttura aggiornata per impilare il grafico: { mese: { idCategoria : valore } }
                Map<int, Map<String, double>> speseMensiliPerCategoria = {for (var i = 1; i <= 12; i++) i: {}};
                double totaleAnno = 0;

                for (var spesa in spese) {
                  int mesiTotali = (spesa.dataCompetenzaFine.year - spesa.dataCompetenzaInizio.year) * 12 +
                      spesa.dataCompetenzaFine.month - spesa.dataCompetenzaInizio.month + 1;
                  if (mesiTotali <= 0) mesiTotali = 1;

                  double quotaMensile = spesa.importo / mesiTotali;

                  for (int i = 0; i < mesiTotali; i++) {
                    int meseCorrente = spesa.dataCompetenzaInizio.month + i;
                    int annoCorrente = spesa.dataCompetenzaInizio.year;

                    while (meseCorrente > 12) {
                      meseCorrente -= 12;
                      annoCorrente++;
                    }

                    if (annoCorrente == _annoSelezionato) {
                      totaliPerCategoria[spesa.idCategoria] = (totaliPerCategoria[spesa.idCategoria] ?? 0) + quotaMensile;

                      speseMensiliPerCategoria[meseCorrente]![spesa.idCategoria] =
                          (speseMensiliPerCategoria[meseCorrente]![spesa.idCategoria] ?? 0) + quotaMensile;

                      totaleAnno += quotaMensile;
                    }
                  }
                }

                double mediaMensile = totaleAnno / 12;

                // Troviamo il tetto massimo del grafico mensile sommando i valori di tutte le categorie in un mese
                double maxSpesaMensile = 0;
                for (var vociMese in speseMensiliPerCategoria.values) {
                  double totaleMese = vociMese.values.fold(0, (sum, item) => sum + item);
                  if (totaleMese > maxSpesaMensile) maxSpesaMensile = totaleMese;
                }
                double maxYSpese = maxSpesaMensile > 0 ? ((maxSpesaMensile * 1.2) / 10).ceil() * 10.0 : 100.0;

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // SELETTORE ANNO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left, size: 32), onPressed: () => setState(() => _annoSelezionato--)),
                        Text('$_annoSelezionato', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.chevron_right, size: 32), onPressed: () => setState(() => _annoSelezionato++)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // BOX RIASSUNTIVI ECONOMICI
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  const Text('Totale Anno', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('€ ${_formattaValore(totaleAnno)}',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  const Text('Media Mensile', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('€ ${_formattaValore(mediaMensile)}',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (totaleAnno > 0) ...[
                      // GRAFICO A TORTA E DETTAGLIO
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Ripartizione Spese', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: totaliPerCategoria.entries.map((entry) {
                                      final cat = categorie.firstWhere((c) => c.id == entry.key, orElse: () => Categoria(id: '', nome: 'Altro', iconCodePoint: Icons.help.codePoint, colorValue: Colors.grey.value, targetAppartamenti: [], ordine: 99));
                                      final percentuale = (entry.value / totaleAnno) * 100;
                                      return PieChartSectionData(color: cat.color, value: entry.value, title: '${percentuale.toStringAsFixed(1)}%', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white));
                                    }).toList(),
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                              const Divider(height: 32),
                              const Text('Dettaglio Categorie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ...(totaliPerCategoria.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                                  .map((entry) {
                                final cat = categorie.firstWhere((c) => c.id == entry.key, orElse: () => Categoria(id: '', nome: 'Altro', iconCodePoint: Icons.help.codePoint, colorValue: Colors.grey.value, targetAppartamenti: [], ordine: 99));
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(radius: 12, backgroundColor: cat.color),
                                  title: Text(cat.nome),
                                  trailing: Text('€ ${_formattaValore(entry.value)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // NUOVO GRAFICO A BARRE IMPILATO (STACKED BAR CHART)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Andamento Mensile Spese (€)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 220,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxYSpese,
                                    barGroups: speseMensiliPerCategoria.entries.map((entry) {
                                      int mese = entry.key;
                                      Map<String, double> datiMese = entry.value;

                                      double currentY = 0;
                                      List<BarChartRodStackItem> stackItems = [];

                                      // Ordiniamo le voci per valore decrescente così il blocco più grosso sta alla base
                                      var listOrdinata = datiMese.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

                                      for (var item in listOrdinata) {
                                        if (item.value > 0) {
                                          final catColor = categorie.firstWhere(
                                                  (c) => c.id == item.key,
                                              orElse: () => Categoria(id: '', nome: 'Altro', iconCodePoint: Icons.help.codePoint, colorValue: Colors.grey.value, targetAppartamenti: [], ordine: 99)
                                          ).color;

                                          stackItems.add(BarChartRodStackItem(currentY, currentY + item.value, catColor));
                                          currentY += item.value;
                                        }
                                      }

                                      return BarChartGroupData(
                                          x: mese - 1,
                                          barRods: [
                                            BarChartRodData(
                                              toY: currentY,
                                              rodStackItems: stackItems,
                                              width: 16,
                                              color: Colors.transparent, // Sfondo trasparente per far vedere i blocchi colorati
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), // Raggio solo in cima alla pila
                                            )
                                          ]
                                      );
                                    }).toList(),
                                    borderData: FlBorderData(show: false),
                                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 46, getTitlesWidget: (double value, TitleMeta meta) {
                                        if (value == 0) return const SizedBox.shrink();
                                        return Text(_formattaValore(value), style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.right);
                                      })),
                                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) {
                                        const mesiNomi = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
                                        if (value.toInt() >= 0 && value.toInt() < 12) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(mesiNomi[value.toInt()], style: const TextStyle(fontSize: 10)));
                                        return const Text('');
                                      })),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const Padding(padding: EdgeInsets.only(top: 64.0), child: Center(child: Text('Nessuna spesa registrata per questo anno.', style: TextStyle(color: Colors.grey, fontSize: 16))))
                    ],

                    // GRAFICO kWh
                    const SizedBox(height: 24),
                    _buildGraficoKwh(spese),
                  ],
                );
              }
          );
        }
    );
  }

  Widget _buildGraficoKwh(List<Spesa> spese) {
    final speseKwh = spese.where((s) => s.kwh != null && s.kwh! > 0).toList();
    if (speseKwh.isEmpty) return const SizedBox.shrink();

    Map<int, double> kwhMensili = {for (var i = 1; i <= 12; i++) i: 0.0};

    for (var spesa in speseKwh) {
      int mesiTotali = (spesa.dataCompetenzaFine.year - spesa.dataCompetenzaInizio.year) * 12 +
          spesa.dataCompetenzaFine.month - spesa.dataCompetenzaInizio.month + 1;
      if (mesiTotali <= 0) mesiTotali = 1;

      double quotaKwh = spesa.kwh! / mesiTotali;

      for (int i = 0; i < mesiTotali; i++) {
        int meseCorrente = spesa.dataCompetenzaInizio.month + i;
        int annoCorrente = spesa.dataCompetenzaInizio.year;
        while (meseCorrente > 12) { meseCorrente -= 12; annoCorrente++; }

        if (annoCorrente == _annoSelezionato) kwhMensili[meseCorrente] = (kwhMensili[meseCorrente] ?? 0) + quotaKwh;
      }
    }

    double maxKwhMensile = kwhMensili.values.reduce((a, b) => a > b ? a : b);
    if (maxKwhMensile == 0) return const SizedBox.shrink();
    double maxYKwh = ((maxKwhMensile * 1.2) / 10).ceil() * 10.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Andamento Consumi Elettrici (kWh)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxYKwh,
                  barGroups: kwhMensili.entries.map((entry) {
                    return BarChartGroupData(x: entry.key - 1, barRods: [BarChartRodData(toY: entry.value, color: Colors.amber.shade600, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]);
                  }).toList(),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42, getTitlesWidget: (double value, TitleMeta meta) {
                      if (value == 0) return const SizedBox.shrink();
                      // Qui non serve il punto delle migliaia per i kWh, bastano i numeri puri
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.right);
                    })),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) {
                      const mesiNomi = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
                      if (value.toInt() >= 0 && value.toInt() < 12) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(mesiNomi[value.toInt()], style: const TextStyle(fontSize: 10)));
                      return const Text('');
                    })),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}