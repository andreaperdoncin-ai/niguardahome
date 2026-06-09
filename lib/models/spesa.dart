class Spesa {
  final String id;
  final String idAppartamento;
  final String idCategoria;
  final double importo;
  final double? kwh; // NUOVO: Opzionale, solo per l'Elettricità
  final DateTime dataPagamento;
  final DateTime dataCompetenzaInizio;
  final DateTime dataCompetenzaFine;
  final String? note;

  Spesa({
    required this.id,
    required this.idAppartamento,
    required this.idCategoria,
    required this.importo,
    this.kwh,
    required this.dataPagamento,
    required this.dataCompetenzaInizio,
    required this.dataCompetenzaFine,
    this.note,
  });

  // Questo calcolo è GIA' PERFETTO per il Punto 6 (Competenza)
  double quotaPerMeseAnno(int anno, int mese) {
    final inizioMeseRichiesto = DateTime(anno, mese, 1);
    final fineMeseRichiesto = DateTime(anno, mese + 1, 0);

    if (dataCompetenzaFine.isBefore(inizioMeseRichiesto) ||
        dataCompetenzaInizio.isAfter(fineMeseRichiesto)) {
      return 0.0;
    }

    final giorniTotaliSpesa = dataCompetenzaFine.difference(dataCompetenzaInizio).inDays + 1;
    if (giorniTotaliSpesa <= 0) return importo;

    final dataInizioIntersezione = dataCompetenzaInizio.isAfter(inizioMeseRichiesto)
        ? dataCompetenzaInizio : inizioMeseRichiesto;

    final dataFineIntersezione = dataCompetenzaFine.isBefore(fineMeseRichiesto)
        ? dataCompetenzaFine : fineMeseRichiesto;

    final giorniIntersezione = dataFineIntersezione.difference(dataInizioIntersezione).inDays + 1;

    return (importo / giorniTotaliSpesa) * giorniIntersezione;
  }

  factory Spesa.fromMap(String docId, Map<String, dynamic> map) {
    return Spesa(
      id: docId,
      idAppartamento: map['idAppartamento'] as String,
      idCategoria: map['idCategoria'] as String,
      importo: (map['importo'] as num).toDouble(),
      kwh: map['kwh'] != null ? (map['kwh'] as num).toDouble() : null, // Legge i kWh
      dataPagamento: DateTime.parse(map['dataPagamento'] as String),
      dataCompetenzaInizio: DateTime.parse(map['dataCompetenzaInizio'] as String),
      dataCompetenzaFine: DateTime.parse(map['dataCompetenzaFine'] as String),
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idAppartamento': idAppartamento,
      'idCategoria': idCategoria,
      'importo': importo,
      'kwh': kwh, // Salva i kWh
      'dataPagamento': dataPagamento.toIso8601String().split('T')[0],
      'dataCompetenzaInizio': dataCompetenzaInizio.toIso8601String().split('T')[0],
      'dataCompetenzaFine': dataCompetenzaFine.toIso8601String().split('T')[0],
      'note': note,
    };
  }
}