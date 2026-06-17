import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/spesa_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../models/spesa.dart';
import '../../models/categoria.dart';

enum TipoVisualizzazione {
  solare,
  condominiale
}

class StatisticheScreen extends StatefulWidget {
  const StatisticheScreen({super.key});

  @override
  State<StatisticheScreen> createState() => _StatisticheScreenState();
}

class _StatisticheScreenState extends State<StatisticheScreen> {
  int _annoSelezionato = DateTime.now().year;
  TipoVisualizzazione _vistaCorrente = TipoVisualizzazione.solare;

  String _formattaValore(double valore) {
    final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    return formatter.format(valore).trim();
  }

  // =========================================================================
  // LOGICA DEI MESI DEL PERIODO
  // =========================================================================

  List<DateTime> _getMesiPeriodo(int meseInizio) {
    List<DateTime> mesi = [];
    if (_vistaCorrente == TipoVisualizzazione.solare) {
      for (int i = 1; i <= 12; i++) {
        mesi.add(DateTime(_annoSelezionato, i, 1));
      }
    } else {
      for (int i = 0; i < 12; i++) {
        int mese = meseInizio + i;
        int anno = _annoSelezionato - 1;
        if (mese > 12) {
          mese -= 12;
          anno += 1;
        }
        mesi.add(DateTime(anno, mese, 1));
      }
    }
    return mesi;
  }

  String _descrizionePeriodo(int meseInizio) {
    if (_vistaCorrente == TipoVisualizzazione.solare) {
      return _annoSelezionato.toString();
    } else {
      String nomeInizio = DateFormat('MMMM', 'it_IT').format(DateTime(2020, meseInizio));
      int meseFine = meseInizio - 1;
      if (meseFine == 0) meseFine = 12;
      String nomeFine = DateFormat('MMMM', 'it_IT').format(DateTime(2020, meseFine));
      
      nomeInizio = nomeInizio[0].toUpperCase() + nomeInizio.substring(1);
      nomeFine = nomeFine[0].toUpperCase() + nomeFine.substring(1);

      return "Gestione: $nomeInizio ${_annoSelezionato - 1} - $nomeFine $_annoSelezionato";
    }
  }

  // =========================================================================
  // BUILD SCHERMATA
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final appartamentoAttivo = context.watch<AppStateProvider>().appartamentoAttivo;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche')),
      body: StreamBuilder<List<Categoria>>(
        stream: context.read<CategoriaProvider>().streamCategorie(),
        builder: (context, catSnapshot) {
          if (!catSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final categorie = catSnapshot.data!;

          return StreamBuilder<List<Spesa>>(
            stream: context.read<SpesaProvider>().streamSpese(appartamentoAttivo.id),
            builder: (context, spesaSnapshot) {
              if (!spesaSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final tutteLeSpese = spesaSnapshot.data!;
              final meseInizio = appartamentoAttivo.meseInizioCondominiale;
              final mesi = _getMesiPeriodo(meseInizio);

              // MODIFICA CRUCIALI: Calcoliamo i totali di questo periodo interamente per COMPETENZA
              final Map<String, double> raggruppamentoCompetenza = {};
              for (var mese in mesi) {
                for (var s in tutteLeSpese) {
                  double quota = s.quotaPerMeseAnno(mese.year, mese.month);
                  if (quota > 0) {
                    raggruppamentoCompetenza[s.idCategoria] = (raggruppamentoCompetenza[s.idCategoria] ?? 0) + quota;
                  }
                }
              }

              final totalePeriodo = raggruppamentoCompetenza.values.fold(0.0, (sum, val) => sum + val);

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [

                  // SELETTORE VISTA
                  Center(
                    child: SegmentedButton<TipoVisualizzazione>(
                      segments: const [
                        ButtonSegment(value: TipoVisualizzazione.solare, label: Text('Anno Solare'), icon: Icon(Icons.calendar_month)),
                        ButtonSegment(value: TipoVisualizzazione.condominiale, label: Text('Condominiale'), icon: Icon(Icons.account_balance)),
                      ],
                      selected: {_vistaCorrente},
                      onSelectionChanged: (Set<TipoVisualizzazione> newSelection) {
                        setState(() { _vistaCorrente = newSelection.first; });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CONTROLLI FRECCE ANNO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _annoSelezionato--)),
                      Expanded(child: Text(_descrizionePeriodo(meseInizio), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _annoSelezionato++)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (tutteLeSpese.isEmpty || totalePeriodo <= 0)
                    const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Nessuna spesa di competenza in questo periodo.")))
                  else ...[

                    // 1. I DUE BOX
                    Row(
                      children: [
                        Expanded(child: _buildBoxStatistica('Totale Anno', totalePeriodo)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildBoxStatistica('Media Mensile', totalePeriodo / 12)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 2. TORTA CON % INTERNE E LISTA DETTAGLIO
                    _buildTitoloSezione('Ripartizione Spese'),
                    _buildGraficoTorta(raggruppamentoCompetenza, categorie, totalePeriodo),
                    const SizedBox(height: 16),
                    _buildListaDettaglioCategorie(raggruppamentoCompetenza, categorie),
                    const SizedBox(height: 40),

                    // 3. BARRE IMPILATE SPESE (CON ASSE Y)
                    _buildTitoloSezione('Andamento Mensile Spese (€)'),
                    _buildAndamentoMensileCompetenza(tutteLeSpese, categorie, mesi),
                    const SizedBox(height: 40),

                    // 4. KWH (CON ASSE Y)
                    _buildTitoloSezione('Andamento Consumi Elettrici (kWh)'),
                    _buildGraficoKwh(tutteLeSpese, mesi),
                    const SizedBox(height: 32),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBoxStatistica(String titolo, double valore) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(titolo, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimaryContainer), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_formattaValore(valore), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTitoloSezione(String titolo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(titolo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
    );
  }

  // =========================================================================
  // WIDGET COMPONENTI DEI GRAFICI
  // =========================================================================

  // --- GRAFICO A TORTA ---
  Widget _buildGraficoTorta(Map<String, double> raggruppamento, List<Categoria> categorie, double totale) {
    var entryList = raggruppamento.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sezioni = entryList.map((entry) {
      final categoria = categorie.firstWhere((c) => c.id == entry.key, orElse: () => Categoria(id: 'err', nome: 'Sconosciuta', iconCodePoint: Icons.category.codePoint, colorValue: Colors.grey.value, targetAppartamenti: [], ordine: 99));

      final double percentuale = (entry.value / totale) * 100;
      final String testoPercentuale = percentuale >= 1 ? '${percentuale.toStringAsFixed(0)}%' : '<1%';

      return PieChartSectionData(
        color: categoria.color,
        value: entry.value,
        title: testoPercentuale,
        radius: 80,
        titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: sezioni)),
    );
  }

  // --- LISTA DETTAGLIO CATEGORIE ---
  Widget _buildListaDettaglioCategorie(Map<String, double> raggruppamento, List<Categoria> categorie) {
    var entryList = raggruppamento.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entryList.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entryList[index];
          final categoria = categorie.firstWhere((c) => c.id == entry.key, orElse: () => Categoria(id: 'err', nome: 'Sconosciuta', iconCodePoint: Icons.category.codePoint, colorValue: Colors.grey.value, targetAppartamenti: [], ordine: 99));

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: categoria.color,
              child: Icon(categoria.iconData, color: Colors.white, size: 20),
            ),
            title: Text(categoria.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text(_formattaValore(entry.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          );
        },
      ),
    );
  }

  // --- GRAFICO A BARRE IMPILATE SPESE ---
  Widget _buildAndamentoMensileCompetenza(List<Spesa> tutteLeSpese, List<Categoria> categorie, List<DateTime> mesi) {
    List<BarChartGroupData> gruppi = [];

    for (int i = 0; i < mesi.length; i++) {
      final mese = mesi[i];
      Map<String, double> quoteCategoria = {};

      for (var s in tutteLeSpese) {
        double quota = s.quotaPerMeseAnno(mese.year, mese.month);
        if (quota > 0) {
          quoteCategoria[s.idCategoria] = (quoteCategoria[s.idCategoria] ?? 0) + quota;
        }
      }

      List<BarChartRodStackItem> stackItems = [];
      double currentY = 0;

      for (var c in categorie) {
        double q = quoteCategoria[c.id] ?? 0;
        if (q > 0) {
          stackItems.add(BarChartRodStackItem(currentY, currentY + q, c.color));
          currentY += q;
        }
      }

      gruppi.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: currentY,
                width: 16,
                borderRadius: BorderRadius.zero,
                rodStackItems: stackItems,
              )
            ],
          )
      );
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: gruppi,
          titlesData: _buildTitoliAssiGrafico(mesi, prefissoValore: '€'),
          gridData: _buildLineeGrigliaOrizzontali(),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // --- GRAFICO KWH (ARANCIONE) ---
  Widget _buildGraficoKwh(List<Spesa> tutteLeSpese, List<DateTime> mesi) {
    // Filtriamo le bollette elettriche la cui data fine competenza ricade dentro l'intervallo visivo
    DateTime dataInizioPeriodo = mesi.first;
    DateTime dataFinePeriodo = DateTime(mesi.last.year, mesi.last.month + 1, 0, 23, 59, 59);

    final speseKwhPeriodo = tutteLeSpese.where((s) {
      if (s.kwh == null || s.kwh! <= 0) return false;
      return s.dataCompetenzaFine.isAfter(dataInizioPeriodo.subtract(const Duration(seconds: 1))) &&
          s.dataCompetenzaFine.isBefore(dataFinePeriodo.add(const Duration(seconds: 1)));
    }).toList();

    if (speseKwhPeriodo.isEmpty) return const SizedBox.shrink();

    List<BarChartGroupData> gruppi = [];

    for (int i = 0; i < mesi.length; i++) {
      final mese = mesi[i];

      double totaleKwhMese = speseKwhPeriodo
          .where((s) => s.dataCompetenzaFine.year == mese.year && s.dataCompetenzaFine.month == mese.month)
          .fold(0.0, (sum, item) => sum + item.kwh!);

      gruppi.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: totaleKwhMese,
                color: Colors.orange,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          )
      );
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: gruppi,
          titlesData: _buildTitoliAssiGrafico(mesi, prefissoValore: ' kWh'),
          gridData: _buildLineeGrigliaOrizzontali(),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // =========================================================================
  // ABBELLIMENTI ASSI E GRIGLIE (PUNTO 2 RICHIESTO)
  // =========================================================================

  // Configura l'asse X e l'asse Y (Arrotondato senza decimali)
  FlTitlesData _buildTitoliAssiGrafico(List<DateTime> mesi, {required String prefissoValore}) {
    return FlTitlesData(
      show: true,
      // ASSE X (Mesi)
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < mesi.length) {
              String etichetta = DateFormat('MMM', 'it_IT').format(mesi[value.toInt()]);
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                child: Text(
                  etichetta,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
      // MODIFICA 2: ATTIVAZIONE ASSE Y PULITO (Solo numeri interi leggibili)
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45,
          getTitlesWidget: (value, meta) {
            // Elimina passaggi intermedi con numeri decimali fastidiosi (es. 12.5)
            if (value % 1 != 0) return const SizedBox.shrink();
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              child: Text(
                '${value.toStringAsFixed(0)}$prefissoValore',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  // Genera linee di riferimento orizzontali per dare profondità e leggibilità matematica al grafico
  FlGridData _buildLineeGrigliaOrizzontali() {
    return FlGridData(
      show: true,
      drawVerticalLine: false, // Solo righe orizzontali per non affollare la UI
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
          strokeWidth: 1,
        );
      },
    );
  }
}