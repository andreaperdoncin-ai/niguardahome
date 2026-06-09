import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

Future<void> generaECondividiCSV(BuildContext context) async {
  try {
    // Mostriamo un avviso mentre l'app frulla i dati
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generazione file in corso... attendi.')),
    );

    final db = FirebaseFirestore.instance;

    // 1. Peschiamo tutto dal database
    final speseSnap = await db.collection('spese').orderBy('dataPagamento', descending: true).get();
    final lettureSnap = await db.collection('letture').orderBy('dataLettura', descending: true).get();
    final categorieSnap = await db.collection('categorie').get();

    // Mappiamo le categorie per avere il nome leggibile ("Elettricità" invece di "cat_elettricita")
    Map<String, String> mappaCategorie = {};
    for (var doc in categorieSnap.docs) {
      mappaCategorie[doc.id] = doc.data()['nome'] ?? doc.id;
    }

    Map<String, String> mappaAppartamenti = {
      'app_passerini': 'Via Passerini',
      'app_frugoni': 'Via Frugoni',
    };

    final dateFormat = DateFormat('dd/MM/yyyy');

    // 2. Costruiamo l'intestazione delle colonne CSV (usiamo ; per Excel Italiano)
    String csvString = "TIPO;APPARTAMENTO;CATEGORIA_CONTATORE;IMPORTO_VALORE;DATA;COMPETENZA_INIZIO;COMPETENZA_FINE;KWH;NOTE\n";

    // 3. Aggiungiamo tutte le righe delle Spese
    for (var doc in speseSnap.docs) {
      final data = doc.data();
      String app = mappaAppartamenti[data['idAppartamento']] ?? data['idAppartamento'];
      String cat = mappaCategorie[data['idCategoria']] ?? data['idCategoria'];
      String importo = data['importo'].toString().replaceAll('.', ','); // Convertiamo in virgola
      String dataPag = dateFormat.format(DateTime.parse(data['dataPagamento']));
      String compInizio = dateFormat.format(DateTime.parse(data['dataCompetenzaInizio']));
      String compFine = dateFormat.format(DateTime.parse(data['dataCompetenzaFine']));
      String kwh = data['kwh'] != null ? data['kwh'].toString().replaceAll('.', ',') : '';

      // Se ci sono ; nelle note, li rimpiazziamo per non sballare le colonne di Excel
      String note = (data['note'] ?? '').replaceAll(';', ',');

      csvString += "SPESA;$app;$cat;€ $importo;$dataPag;$compInizio;$compFine;$kwh;$note\n";
    }

    // 4. Aggiungiamo tutte le righe delle Letture
    for (var doc in lettureSnap.docs) {
      final data = doc.data();
      String app = mappaAppartamenti[data['idAppartamento']] ?? data['idAppartamento'];

      // Formattiamo il nome del contatore
      String tipo = data['tipo'].toString().toUpperCase();
      if (tipo == 'RISCALDAMENTO' || tipo == 'RAFFRESCAMENTO') {
        tipo = "$tipo (MWh)";
      } else {
        tipo = "$tipo (m³)";
      }

      String valore = data['valore'].toString().replaceAll('.', ',');
      String dataLet = dateFormat.format(DateTime.parse(data['dataLettura']));
      String note = (data['note'] ?? '').replaceAll(';', ',');

      // Le colonne delle competenze e KWH restano vuote per le letture
      csvString += "LETTURA;$app;$tipo;$valore;$dataLet;;;;$note\n";
    }

    // 5. Creiamo il file fisico nella memoria temporanea del telefono
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/NiguardaHome_Export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvString);

    // 6. Richiamiamo la condivisione di Android
    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Backup Dati NiguardaHome',
      );
    }

  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'esportazione: $e')),
      );
    }
  }
}