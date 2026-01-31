class Garante {
  final int id;
  final String latitudine;
  final String longitudine;
  final String? citta;
  final String regione;
  final String? garante1;
  final String? garante2;
  final String? garante3;
  final String? email1;
  final String? email2;
  final String? email3;

  Garante({
    required this.id,
    required this.latitudine,
    required this.longitudine,
    this.citta,
    required this.regione,
    this.garante1,
    this.garante2,
    this.garante3,
    this.email1,
    this.email2,
    this.email3,
  });

  factory Garante.fromJson(Map<String, dynamic> json) {
    return Garante(
      id: json['id'] ?? 0,
      latitudine: json['latitudine']?.toString() ?? '0',
      longitudine: json['longitudine']?.toString() ?? '0',
      citta: json['citta']?.toString(),
      regione: json['regione']?.toString() ?? '',
      garante1: json['garante1']?.toString(),
      garante2: json['garante2']?.toString(),
      garante3: json['garante3']?.toString(),
      email1: json['email1']?.toString(),
      email2: json['email2']?.toString(),
      email3: json['email3']?.toString(),
    );
  }

  // Getter per verificare se ha coordinate valide
  bool get hasValidCoordinates {
    final lat = double.tryParse(latitudine);
    final lng = double.tryParse(longitudine);
    return lat != null && lng != null && lat != 0 && lng != 0;
  }

  // Getter per ottenere latitudine come double
  double get latDouble => double.tryParse(latitudine) ?? 0.0;

  // Getter per ottenere longitudine come double  
  double get lngDouble => double.tryParse(longitudine) ?? 0.0;
}