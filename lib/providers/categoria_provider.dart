import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria.dart';

class CategoriaProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CategoriaProvider() {
    _controllaEInizializza(); // All'avvio controlla subito se Firebase è vuoto
  }

  // Ascolta le categorie dal cloud ordinandole per il campo "ordine"
  Stream<List<Categoria>> streamCategorie() {
    return _db
        .collection('categorie')
        .orderBy('ordine')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Categoria.fromMap(doc.id, doc.data()))
        .toList());
  }

  // Salva una nuova categoria o ne aggiorna una esistente
  Future<void> salvaCategoria(Categoria categoria) async {
    if (categoria.id.isEmpty) {
      await _db.collection('categorie').add(categoria.toMap());
    } else {
      await _db.collection('categorie').doc(categoria.id).set(categoria.toMap(), SetOptions(merge: true));
    }
  }

  // Elimina una categoria
  Future<void> eliminaCategoria(String id) async {
    await _db.collection('categorie').doc(id).delete();
  }

  // Aggiorna l'ordine di tutte le categorie (chiamato dopo il Drag&Drop)
  Future<void> aggiornaOrdine(List<Categoria> categorie) async {
    WriteBatch batch = _db.batch();
    for (int i = 0; i < categorie.length; i++) {
      final docRef = _db.collection('categorie').doc(categorie[i].id);
      batch.update(docRef, {'ordine': i});
    }
    await batch.commit();
  }

  // Il "motore magico": se la raccolta non esiste, la crea usando le basi
  Future<void> _controllaEInizializza() async {
    final snapshot = await _db.collection('categorie').limit(1).get();
    if (snapshot.docs.isEmpty) {
      debugPrint("Inizializzazione categorie su Firebase in corso...");
      WriteBatch batch = _db.batch();
      for (var cat in Categoria.categorieIniziali) {
        final docRef = _db.collection('categorie').doc(cat.id);
        batch.set(docRef, cat.toMap());
      }
      await batch.commit();
      debugPrint("Categorie inizializzate con successo!");
    }
  }
}