class Appartamento {
  final String id; // "passerini" o "frugoni"
  final String nome; // "Via Passerini" o "Via Frugoni"
  final String indirizzo;
  final bool haContatoriCalore; // true per Passerini, false per Frugoni

  const Appartamento({
    required this.id,
    required this.nome,
    required this.indirizzo,
    required this.haContatoriCalore,
  });

  // Istanze statiche predefinite per le nostre due case di Niguarda
  static const Appartamento passerini = Appartamento(
    id: 'passerini',
    nome: 'Via Passerini',
    indirizzo: 'Via Passerini, Milano (Niguarda)',
    haContatoriCalore: true,
  );

  static const Appartamento frugoni = Appartamento(
    id: 'frugoni',
    nome: 'Via Frugoni',
    indirizzo: 'Via Frugoni, Milano (Niguarda)',
    haContatoriCalore: false,
  );

  static List<Appartamento> get all => [passerini, frugoni];

  factory Appartamento.fromId(String id) {
    return all.firstWhere((element) => element.id == id, orElse: () => passerini);
  }
}