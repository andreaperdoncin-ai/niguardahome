import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/lettura_provider.dart';
import '../../models/lettura.dart';

class LettureScreen extends StatelessWidget {
  const LettureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appartamentoAttivo = context.watch<AppStateProvider>().appartamentoAttivo;
    final idAppartamento = appartamentoAttivo.id;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: false,
            tabs: [
              Tab(text: 'AFS', icon: Icon(Icons.water_drop, color: Colors.blue)),
              Tab(text: 'ACS', icon: Icon(Icons.water_drop, color: Colors.red)),
              Tab(text: 'Caldo', icon: Icon(Icons.local_fire_department, color: Colors.orange)),
              Tab(text: 'Freddo', icon: Icon(Icons.ac_unit, color: Colors.blueAccent)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _LettureTabView(idAppartamento: idAppartamento, tipo: 'afs', isAcqua: true),
                _LettureTabView(idAppartamento: idAppartamento, tipo: 'acs', isAcqua: true),
                _LettureTabView(idAppartamento: idAppartamento, tipo: 'riscaldamento', isAcqua: false),
                _LettureTabView(idAppartamento: idAppartamento, tipo: 'raffrescamento', isAcqua: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LettureTabView extends StatelessWidget {
  final String idAppartamento;
  final String tipo;
  final bool isAcqua;

  const _LettureTabView({
    required this.idAppartamento,
    required this.tipo,
    required this.isAcqua,
  });

  String _formatta(double valore) {
    return valore.toStringAsFixed(3).replaceAll('.', ',');
  }

  String _formattaDiff(double valore) {
    String prefisso = valore > 0 ? '+' : '';
    return prefisso + valore.toStringAsFixed(3).replaceAll('.', ',');
  }

  // Nuova formattazione specifica per la Media: taglia i decimali se è Acqua
  String _formattaMedia(double valore) {
    if (isAcqua) {
      return valore.round().toString(); // Arrotonda al litro intero
    }
    return valore.toStringAsFixed(3).replaceAll('.', ','); // Mantiene i millesimi per Gas/Caldo/Freddo
  }

  @override
  Widget build(BuildContext context) {
    final colorValore = Theme.of(context).brightness == Brightness.dark
        ? Colors.greenAccent.shade400
        : Colors.green.shade700;

    return StreamBuilder<List<Lettura>>(
        stream: context.read<LetturaProvider>().streamLetture(idAppartamento, tipo),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final letture = snapshot.data!;

          if (letture.isEmpty) {
            return const Center(
              child: Text('Nessuna lettura registrata', style: TextStyle(color: Colors.grey)),
            );
          }

          final ultimaLettura = letture.first;
          final penultimaLettura = letture.length > 1 ? letture[1] : null;

          double diffRecente = 0.0;
          int giorniRecenti = 0;
          if (penultimaLettura != null) {
            diffRecente = ultimaLettura.valore - penultimaLettura.valore;
            giorniRecenti = ultimaLettura.dataLettura.difference(penultimaLettura.dataLettura).inDays;
          }

          double mediaRecente = 0.0;
          if (giorniRecenti > 0) {
            mediaRecente = diffRecente / giorniRecenti;
            if (isAcqua) mediaRecente *= 1000.0;
          }

          final String unit = (tipo == 'riscaldamento' || tipo == 'raffrescamento') ? 'MWh' : 'm³';
          final String unitMedia = isAcqua ? 'L/gg' : '$unit/gg';

          return Column(
            children: [
              // BOX RIASSUNTIVO IN CIMA
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Ultima Lettura', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('${_formatta(ultimaLettura.valore)} $unit', style: TextStyle(color: colorValore, fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd/MM/yyyy').format(ultimaLettura.dataLettura), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                              ],
                            ),
                          ),
                          VerticalDivider(color: Theme.of(context).dividerColor, thickness: 1, indent: 8, endIndent: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Ultimo Consumo', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('${_formattaDiff(diffRecente)} $unit', style: TextStyle(color: colorValore, fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${_formattaMedia(mediaRecente)} $unitMedia', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // LISTA DELLE LETTURE
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: letture.length,
                  itemBuilder: (context, index) {
                    final letturaCorrente = letture[index];
                    final letturaPrecedente = (index + 1 < letture.length) ? letture[index + 1] : null;

                    double diffCard = 0.0;
                    int giorniCard = 0;
                    if (letturaPrecedente != null) {
                      diffCard = letturaCorrente.valore - letturaPrecedente.valore;
                      giorniCard = letturaCorrente.dataLettura.difference(letturaPrecedente.dataLettura).inDays;
                    }

                    double mediaCard = 0.0;
                    if (giorniCard > 0) {
                      mediaCard = diffCard / giorniCard;
                      if (isAcqua) mediaCard *= 1000.0;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorValore.withOpacity(0.15),
                              radius: 18,
                              child: Icon(Icons.speed, color: colorValore, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              DateFormat('dd/MM/yyyy').format(letturaCorrente.dataLettura),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatta(letturaCorrente.valore)} $unit',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                if (letturaPrecedente != null)
                                  Row(
                                    children: [
                                      Text('Media: ${_formattaMedia(mediaCard)} $unitMedia', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
                                      const SizedBox(width: 8),
                                      Text('${_formattaDiff(diffCard)} $unit', style: TextStyle(color: colorValore, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  )
                                else
                                  Text('Lettura iniziale', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                              ],
                            ),
                          ],
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
  }
}