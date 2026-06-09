import 'package:flutter/material.dart';
import '../models/appartamento.dart';

class AppStateProvider with ChangeNotifier {
  // Impostiamo Via Passerini come default all'avvio
  Appartamento _appartamentoAttivo = Appartamento.passerini;

  Appartamento get appartamentoAttivo => _appartamentoAttivo;

  void cambiaAppartamento(Appartamento nuovoAppartamento) {
    if (_appartamentoAttivo.id != nuovoAppartamento.id) {
      _appartamentoAttivo = nuovoAppartamento;
      // Notifica a tutti i widget in ascolto di ridisegnarsi
      // (es. le liste spese si aggiorneranno per filtrare solo i dati della nuova casa)
      notifyListeners();
    }
  }

  // Helper utile per l'UI: restituisce true se l'app deve mostrare i contatori calore
  bool get mostraContatoriCalore => _appartamentoAttivo.haContatoriCalore;
}