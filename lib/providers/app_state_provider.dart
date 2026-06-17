import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Nuovo import
import '../models/appartamento.dart';

class AppStateProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Impostiamo Via Passerini come default all'avvio
  Appartamento _appartamentoAttivo = Appartamento.passerini;

  // Una mappa per tenere in memoria i mesi personalizzati di ogni casa
  final Map<String, int> _mesiInizioCondominiale = {
    'passerini': 8, // Default fallback
    'frugoni': 1,   // Default fallback
  };

  AppStateProvider() {
    _ascoltaImpostazioni();
  }

  // Costruisce l'appartamento attivo iniettando il mese aggiornato da Firebase
  Appartamento get appartamentoAttivo {
    return Appartamento(
      id: _appartamentoAttivo.id,
      nome: _appartamentoAttivo.nome,
      indirizzo: _appartamentoAttivo.indirizzo,
      haContatoriCalore: _appartamentoAttivo.haContatoriCalore,
      meseInizioCondominiale: _mesiInizioCondominiale[_appartamentoAttivo.id] ?? 1,
    );
  }

  void cambiaAppartamento(Appartamento nuovoAppartamento) {
    if (_appartamentoAttivo.id != nuovoAppartamento.id) {
      _appartamentoAttivo = nuovoAppartamento;
      notifyListeners();
    }
  }

  bool get mostraContatoriCalore => _appartamentoAttivo.haContatoriCalore;

  // --- LOGICA FIREBASE ---

  // 1. Ascolta i cambiamenti in tempo reale
  void _ascoltaImpostazioni() {
    _db.collection('configurazioni_appartamenti').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        if (doc.data().containsKey('meseInizioCondominiale')) {
          _mesiInizioCondominiale[doc.id] = doc['meseInizioCondominiale'] as int;
        }
      }
      notifyListeners(); // Aggiorna tutta l'app istantaneamente se Firebase cambia
    });
  }

  // 2. Salva la scelta dell'utente su Firebase
  Future<void> aggiornaMeseInizioCondominiale(String idAppartamento, int nuovoMese) async {
    // Aggiornamento locale per feedback visivo istantaneo
    _mesiInizioCondominiale[idAppartamento] = nuovoMese;
    notifyListeners();

    // Salvataggio su Cloud (crea il documento se non esiste, altrimenti lo unisce)
    await _db.collection('configurazioni_appartamenti').doc(idAppartamento).set(
      {'meseInizioCondominiale': nuovoMese},
      SetOptions(merge: true),
    );
  }
}