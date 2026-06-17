import 'package:flutter/material.dart';

enum TipoPeriodo {
  solare,
  condominiale
}

class PeriodoRiferimento {
  final int annoSelezionato;
  final TipoPeriodo tipo;

  // Parametri di configurazione (es. 8 per Agosto, 1 per il primo del mese)
  // Questi saranno poi letti dalle impostazioni dell'appartamento!
  final int meseInizioCondominiale;
  final int giornoInizioCondominiale;

  PeriodoRiferimento({
    required this.annoSelezionato,
    required this.tipo,
    this.meseInizioCondominiale = 8, // Default: Agosto (come Via Passerini)
    this.giornoInizioCondominiale = 1,
  });

  // Calcola la Data di Inizio assoluta
  DateTime get dataInizio {
    if (tipo == TipoPeriodo.solare) {
      // 1° Gennaio dell'anno selezionato
      return DateTime(annoSelezionato, 1, 1);
    } else {
      // Es: Se ho selezionato 2026 come anno, la gestione condominiale
      // inizia l'anno prima (1 Agosto 2025)
      return DateTime(annoSelezionato - 1, meseInizioCondominiale, giornoInizioCondominiale);
    }
  }

  // Calcola la Data di Fine assoluta
  DateTime get dataFine {
    if (tipo == TipoPeriodo.solare) {
      // 31 Dicembre dell'anno selezionato
      return DateTime(annoSelezionato, 12, 31, 23, 59, 59);
    } else {
      // Es: La gestione condominiale 2026 finisce prima dell'inizio del nuovo ciclo.
      // Trucco di Dart: il giorno "0" del mese X equivale all'ultimo giorno del mese X-1!
      return DateTime(annoSelezionato, meseInizioCondominiale, 0, 23, 59, 59);
    }
  }

  // L'etichetta bella e formattata per la nostra UI (Proposta 2)
  String get etichetta {
    if (tipo == TipoPeriodo.solare) {
      return "$annoSelezionato";
    } else {
      // Formatta in "2025/2026" oppure "'25/'26"
      final annoPrecedente = (annoSelezionato - 1).toString().substring(2);
      final annoCorrente = annoSelezionato.toString().substring(2);
      return "'$annoPrecedente / '$annoCorrente";
    }
  }
}