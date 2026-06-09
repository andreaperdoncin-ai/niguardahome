import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lettura.dart';

class LetturaProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ascolta in tempo reale le letture filtrando per casa e per tipo di contatore
  Stream<List<Lettura>> streamLetture(String idAppartamento, String tipo) {
    return _db
        .collection('letture')
        .where('idAppartamento', isEqualTo: idAppartamento)
        .where('tipo', isEqualTo: tipo)
        .orderBy('dataLettura', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Lettura.fromMap(doc.id, doc.data()))
        .toList());
  }

  // Salva o aggiorna una lettura
  Future<void> salvaLettura(Lettura lettura) async {
    try {
      if (lettura.id.isEmpty) {
        await _db.collection('letture').add(lettura.toMap());
      } else {
        await _db.collection('letture').doc(lettura.id).update(lettura.toMap());
      }
    } catch (e) {
      debugPrint("Errore salvataggio lettura: $e");
      rethrow;
    }
  }

  // Elimina una lettura
  Future<void> eliminaLettura(String id) async {
    await _db.collection('letture').doc(id).delete();
  }
  // --- GESTIONE OFFSET (Valori di partenza) ---

  // Salva il valore iniziale del contatore
  Future<void> salvaOffset(String idAppartamento, String tipo, double valore) async {
    // Usiamo un ID univoco composto per trovare subito il documento
    String docId = '${idAppartamento}_$tipo';
    await _db.collection('offset_contatori').doc(docId).set({
      'idAppartamento': idAppartamento,
      'tipo': tipo,
      'valore': valore,
    });
  }

  // Ascolta in tempo reale l'offset impostato
  Stream<double?> streamOffset(String idAppartamento, String tipo) {
    String docId = '${idAppartamento}_$tipo';
    return _db.collection('offset_contatori').doc(docId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['valore'] as num).toDouble();
      }
      return null; // Se non c'è, partirà da 0
    });
  }
}