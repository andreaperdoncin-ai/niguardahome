enum TipoContatore {
  riscaldamento,
  raffrescamento,
  acquaFredda,
  acquaCalda;

  String get nome {
    switch (this) {
      case TipoContatore.riscaldamento:  return 'Riscaldamento';
      case TipoContatore.raffrescamento: return 'Raffrescamento';
      case TipoContatore.acquaFredda:    return 'Acqua Fredda Sanitaria';
      case TipoContatore.acquaCalda:     return 'Acqua Calda Sanitaria';
    }
  }

  String get nomeBreve {
    switch (this) {
      case TipoContatore.riscaldamento:  return 'Risc.';
      case TipoContatore.raffrescamento: return 'Raffr.';
      case TipoContatore.acquaFredda:    return 'AFS';
      case TipoContatore.acquaCalda:     return 'ACS';
    }
  }

  String get unitaMisura {
    switch (this) {
      case TipoContatore.riscaldamento:
      case TipoContatore.raffrescamento: return 'MWh';
      case TipoContatore.acquaFredda:
      case TipoContatore.acquaCalda:     return 'm³';
    }
  }

  bool get isAcqua => this == TipoContatore.acquaFredda || this == TipoContatore.acquaCalda;

  String get dbValue {
    switch (this) {
      case TipoContatore.riscaldamento:  return 'riscaldamento';
      case TipoContatore.raffrescamento: return 'raffrescamento';
      case TipoContatore.acquaFredda:    return 'acqua_fredda';
      case TipoContatore.acquaCalda:     return 'acqua_calda';
    }
  }

  static TipoContatore fromDb(String value) {
    return TipoContatore.values.firstWhere(
          (e) => e.dbValue == value,
      orElse: () => TipoContatore.acquaFredda,
    );
  }

  // Ritorna i contatori abilitati in base alle caratteristiche dell'appartamento
  static List<TipoContatore> sottoInsiemePerAppartamento(bool haCalore) {
    if (haCalore) {
      return TipoContatore.values; // Tutti e 4 per Via Passerini
    } else {
      return [TipoContatore.acquaFredda]; // Solo AFS per Via Frugoni
    }
  }
}

class LetturaContatore {
  final String id;
  final String idAppartamento; // "passerini" o "frugoni"
  final TipoContatore tipo;
  final DateTime data;
  final double valore;
  final String? note;

  LetturaContatore({
    required this.id,
    required this.idAppartamento,
    required this.tipo,
    required this.data,
    required this.valore,
    this.note,
  });

  factory LetturaContatore.fromMap(String docId, Map<String, dynamic> map) {
    return LetturaContatore(
      id: docId,
      idAppartamento: map['idAppartamento'] as String,
      tipo: TipoContatore.fromDb(map['tipo'] as String),
      data: DateTime.parse(map['data'] as String),
      valore: (map['valore'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idAppartamento': idAppartamento,
      'tipo': tipo.dbValue,
      'data': data.toIso8601String().split('T')[0],
      'valore': valore,
      'note': note,
    };
  }
}