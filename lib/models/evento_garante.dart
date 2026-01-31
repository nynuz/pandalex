class EventoGarante {
  final String id;
  final String garanteId;
  final String titolo;
  final String descrizione;
  final String? immagineUrl;
  final bool pubblicato;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? regione;
  final DateTime dataEvento;

  EventoGarante({
    required this.id,
    required this.garanteId,
    required this.titolo,
    required this.descrizione,
    this.immagineUrl,
    required this.pubblicato,
    required this.createdAt,
    required this.updatedAt,
    this.regione,
    required this.dataEvento,
  });

  factory EventoGarante.fromJson(Map<String, dynamic> json) {
    return EventoGarante(
      id: json['id'],
      garanteId: json['garante_id'],
      titolo: json['titolo'],
      descrizione: json['descrizione'],
      immagineUrl: json['immagine_url'],
      pubblicato: json['pubblicato'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      regione: json['regione'],
      dataEvento: DateTime.parse(json['data_evento']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'garante_id': garanteId,
      'titolo': titolo,
      'descrizione': descrizione,
      'immagine_url': immagineUrl,
      'pubblicato': pubblicato,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'regione': regione,
      'data_evento': dataEvento.toIso8601String(),
    };
  }

  String get descrizioneBreve {
    if (descrizione.length <= 100) return descrizione;
    return '${descrizione.substring(0, 100)}...';
  }
}