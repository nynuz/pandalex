class CasoSentenza {
  final int id;
  final String title;
  final String? excerpt;
  final String? content;
  final String date;
  final String? imageUrl;
  final String? pdf;
  final String? blogUrl;

  CasoSentenza({
    required this.id,
    required this.title,
    required this.date,
    this.excerpt,
    this.content,
    this.imageUrl,
    this.pdf,
    this.blogUrl,
  });

  factory CasoSentenza.fromJson(Map<String, dynamic> json) {
    return CasoSentenza(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      excerpt: json['excerpt']?.toString(),
      content: json['content']?.toString(),
      date: json['date']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      pdf: json['pdf']?.toString(),
      blogUrl: json['blog_url']?.toString(),
    );
  }

  // Helper per verificare se ha un PDF scaricabile
  bool get hasPdf => pdf?.isNotEmpty == true;

  // Helper per verificare se ha un articolo da leggere
  bool get hasBlogUrl => blogUrl?.isNotEmpty == true;

  // Helper per verificare se ha un'immagine
  bool get hasImage => imageUrl?.isNotEmpty == true;

  // Helper per decodificare entità HTML
  String get decodedTitle {
    return _decodeHtmlEntities(title);
  }
  String get decodedExcerpt {
    return _decodeHtmlEntities(excerpt ?? '');
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#8217;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'^Privato:\s*', caseSensitive: false), '');
  }
}