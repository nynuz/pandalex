class ChatMessage {
  final String id;
  final String garanteId;
  final String contentEncrypted;
  final String iv;
  final String contentDecrypted;
  final DateTime createdAt;
  final String? senderNome;
  final String? senderCognome;

  const ChatMessage({
    required this.id,
    required this.garanteId,
    required this.contentEncrypted,
    required this.iv,
    required this.contentDecrypted,
    required this.createdAt,
    this.senderNome,
    this.senderCognome,
  });

  String get senderDisplay {
    if (senderNome != null && senderCognome != null) {
      return '$senderNome $senderCognome';
    }
    if (senderNome != null) return senderNome!;
    return garanteId.length >= 8 ? garanteId.substring(0, 8) : garanteId;
  }

  factory ChatMessage.fromJson(
    Map<String, dynamic> json,
    String decryptedContent,
  ) {
    String? nome;
    String? cognome;
    if (json['garanti'] is Map) {
      nome = json['garanti']['nome'] as String?;
      cognome = json['garanti']['cognome'] as String?;
    }
    return ChatMessage(
      id: json['id'] as String,
      garanteId: json['garante_id'] as String,
      contentEncrypted: json['content'] as String,
      iv: json['iv'] as String,
      contentDecrypted: decryptedContent,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      senderNome: nome,
      senderCognome: cognome,
    );
  }
}
