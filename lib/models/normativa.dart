class Normativa {
  final int id;
  final String title;
  final String date;
  final String typeDoc;
  final String content;
  final String? categoria;
  final String? num;
  final String? numDoc;
  final String? pdf;
  final String? searchSnippet;
  final List<int>? highlightPositions;

  Normativa({
    required this.id,
    required this.title,
    required this.date,
    required this.typeDoc,
    required this.content,
    this.categoria,
    this.num,
    this.numDoc,
    this.pdf,
    this.searchSnippet,
    this.highlightPositions,
  });

  factory Normativa.fromJson(Map<String, dynamic> json) {
    return Normativa(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      typeDoc: json['type_doc']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      categoria: json['categoria']?.toString(),
      num: json['num']?.toString(),
      numDoc: json['num_doc']?.toString(),
      pdf: json['pdf']?.toString(),
    );
  }
  
  // Helper per verificare se ha un PDF
  bool get hasPdf => pdf?.isNotEmpty == true;

  // Helper per decodificare entità HTML
  String get decodedTitle {
    return _decodeHtmlEntities(title);
  }

  String get decodedContent {
    return _decodeHtmlEntities(content);
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

  Normativa copyWith({
    int? id,
    String? title,
    String? date,
    String? typeDoc,
    String? content,
    String? categoria,
    String? num,
    String? numDoc,
    String? pdf,
    String? searchSnippet,
    List<int>? highlightPositions,
  }) {
    return Normativa(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      typeDoc: typeDoc ?? this.typeDoc,
      content: content ?? this.content,
      categoria: categoria ?? this.categoria,
      num: num ?? this.num,
      numDoc: numDoc ?? this.numDoc,
      pdf: pdf ?? this.pdf,
      searchSnippet: searchSnippet ?? this.searchSnippet,
      highlightPositions: highlightPositions ?? this.highlightPositions,
    );
  }
}