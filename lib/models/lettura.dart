class Lettura {
  final String id;
  final String idAppartamento;
  final String tipo; // Sarà: 'afs', 'acs', 'riscaldamento' o 'raffrescamento'
  final double valore;
  final DateTime dataLettura;
  final String? note;

  Lettura({
    required this.id,
    required this.idAppartamento,
    required this.tipo,
    required this.valore,
    required this.dataLettura,
    this.note,
  });

  // Da Firebase all'App
  factory Lettura.fromMap(String docId, Map<String, dynamic> map) {
    return Lettura(
      id: docId,
      idAppartamento: map['idAppartamento'] as String,
      tipo: map['tipo'] as String,
      valore: (map['valore'] as num).toDouble(),
      dataLettura: DateTime.parse(map['dataLettura'] as String),
      note: map['note'] as String?,
    );
  }

  // Dall'App a Firebase
  Map<String, dynamic> toMap() {
    return {
      'idAppartamento': idAppartamento,
      'tipo': tipo,
      'valore': valore,
      'dataLettura': dataLettura.toIso8601String().split('T')[0], // Salviamo solo la data
      'note': note,
    };
  }
}