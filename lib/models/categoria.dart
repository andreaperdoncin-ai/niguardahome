import 'package:flutter/material.dart';

class Categoria {
  final String id;
  final String nome;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;
  final List<String> targetAppartamenti;
  final int ordine;

  Categoria({
    required this.id,
    required this.nome,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
    required this.targetAppartamenti,
    required this.ordine,
  });

  // Getter comodi per permettere alla UI di usare IconData e Color facilmente
  IconData get iconData => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  // Da Firebase all'App
  factory Categoria.fromMap(String docId, Map<String, dynamic> map) {
    return Categoria(
      id: docId,
      nome: map['nome'] ?? '',
      iconCodePoint: map['iconCodePoint'] ?? Icons.category.codePoint,
      iconFontFamily: map['iconFontFamily'],
      colorValue: map['colorValue'] ?? Colors.grey.value,
      targetAppartamenti: List<String>.from(map['targetAppartamenti'] ?? []),
      ordine: map['ordine'] ?? 99,
    );
  }

  // Dall'App a Firebase
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'colorValue': colorValue,
      'targetAppartamenti': targetAppartamenti,
      'ordine': ordine,
    };
  }

  // Manteniamo questa lista per evitare che il resto dell'app vada in crash
  // prima di aver aggiornato le vecchie schermate. Fungerà anche da "seme" per Firebase.
  static List<Categoria> get categorieIniziali => [
    Categoria(id: 'cat_elettricita', nome: 'Elettricità', iconCodePoint: Icons.bolt.codePoint, colorValue: Colors.yellow.shade700.value, targetAppartamenti: ['app_passerini', 'app_frugoni'], ordine: 1),
    Categoria(id: 'cat_internet', nome: 'Internet / Fibra', iconCodePoint: Icons.wifi.codePoint, colorValue: Colors.blue.value, targetAppartamenti: ['app_passerini', 'app_frugoni'], ordine: 2),
    Categoria(id: 'cat_condominio', nome: 'Spese Condominiali', iconCodePoint: Icons.location_city.codePoint, colorValue: Colors.deepPurple.value, targetAppartamenti: ['app_passerini', 'app_frugoni'], ordine: 3),
    Categoria(id: 'cat_tari', nome: 'TARI / Rifiuti', iconCodePoint: Icons.delete_outline.codePoint, colorValue: Colors.green.value, targetAppartamenti: ['app_passerini', 'app_frugoni'], ordine: 4),
    Categoria(id: 'cat_assicurazione', nome: 'Assicurazione Casa', iconCodePoint: Icons.security.codePoint, colorValue: Colors.teal.value, targetAppartamenti: ['app_passerini', 'app_frugoni'], ordine: 5),
    Categoria(id: 'cat_imu', nome: 'IMU', iconCodePoint: Icons.account_balance.codePoint, colorValue: Colors.brown.value, targetAppartamenti: ['app_frugoni'], ordine: 6),
  ];
}