class Appartamento {
  final String id;
  final String nome;
  final String indirizzo;
  final bool haContatoriCalore;

  // NUOVO: Definisce quando inizia l'anno contabile/condominiale (1 = Gennaio, 8 = Agosto)
  final int meseInizioCondominiale;

  const Appartamento({
    required this.id,
    required this.nome,
    required this.indirizzo,
    required this.haContatoriCalore,
    // Di default impostiamo Gennaio se non specificato diversamente
    this.meseInizioCondominiale = 1,
  });

  // Aggiorniamo le istanze statiche di base
  static const Appartamento passerini = Appartamento(
    id: 'passerini',
    nome: 'Via Passerini',
    indirizzo: 'Via Passerini, Milano (Niguarda)',
    haContatoriCalore: true,
    meseInizioCondominiale: 8, // Via Passerini parte dal 1° Agosto
  );

  static const Appartamento frugoni = Appartamento(
    id: 'frugoni',
    nome: 'Via Frugoni',
    indirizzo: 'Via Frugoni, Milano (Niguarda)',
    haContatoriCalore: false,
    meseInizioCondominiale: 1, // Supponiamo Gennaio per Frugoni, modificabile
  );

  static List<Appartamento> get all => [passerini, frugoni];

  factory Appartamento.fromId(String id) {
    return all.firstWhere((element) => element.id == id, orElse: () => passerini);
  }
}