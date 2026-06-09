import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spesa.dart';

class SpesaProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. LETTURA IN TEMPO REALE (Stream)
  // Restituisce un flusso continuo di dati filtrato per l'appartamento attivo
  Stream<List<Spesa>> streamSpese(String idAppartamento) {
    return _db
        .collection('spese')
        .where('idAppartamento', isEqualTo: idAppartamento) // Il filtro asimmetrico!
        .orderBy('dataPagamento', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Spesa.fromMap(doc.id, doc.data()))
        .toList());
  }

  // 2. SCRITTURA
  // Aggiunge o aggiorna una spesa su Firebase
  Future<void> salvaSpesa(Spesa spesa) async {
    try {
      // Se l'id è vuoto (nuova spesa), Firestore genera un ID univoco.
      // Se l'id esiste già (modifica), Firestore sovrascrive quel documento.
      final docRef = spesa.id.isEmpty
          ? _db.collection('spese').doc()
          : _db.collection('spese').doc(spesa.id);

      // Convertiamo il nostro modello nel formato Map richiesto da Firebase
      await docRef.set(spesa.toMap());
    } catch (e) {
      debugPrint("Errore durante il salvataggio della spesa: $e");
      rethrow;
    }
  }

  // 3. ELIMINAZIONE
  Future<void> eliminaSpesa(String idSpesa) async {
    try {
      await _db.collection('spese').doc(idSpesa).delete();
    } catch (e) {
      debugPrint("Errore durante l'eliminazione della spesa: $e");
      rethrow;
    }
  }
}