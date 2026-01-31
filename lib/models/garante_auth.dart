class GaranteAuth {
  final String id;
  final String email;
  final String nome;
  final String cognome;
  final String? regione;
  final String? provincia;
  final bool attivo;
  final DateTime createdAt;
  final DateTime updatedAt;

  GaranteAuth({
    required this.id,
    required this.email,
    required this.nome,
    required this.cognome,
    this.regione,
    this.provincia,
    required this.attivo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GaranteAuth.fromJson(Map<String, dynamic> json) {
    return GaranteAuth(
      id: json['id'],
      email: json['email'],
      nome: json['nome'],
      cognome: json['cognome'],
      regione: json['regione'],
      provincia: json['provincia'],
      attivo: json['attivo'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'cognome': cognome,
      'regione': regione,
      'provincia': provincia,
      'attivo': attivo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get nomeCompleto => '$nome $cognome';
}