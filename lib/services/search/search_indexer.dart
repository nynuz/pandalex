import '../../models/normativa.dart';
import 'text_normalizer.dart';

/// Classe per rappresentare un documento indicizzato
class IndexedDocument {
  final int id;
  final String normalizedTitle;
  final String normalizedContent;
  final String normalizedType;
  final String normalizedCategory;
  final List<String> titleKeywords;
  final List<String> contentKeywords;
  final DateTime date;
  final Normativa original;
  
  IndexedDocument({
    required this.id,
    required this.normalizedTitle,
    required this.normalizedContent,
    required this.normalizedType,
    required this.normalizedCategory,
    required this.titleKeywords,
    required this.contentKeywords,
    required this.date,
    required this.original,
  });
}

/// Servizio per indicizzare le normative
class SearchIndexer {
  static final SearchIndexer _instance = SearchIndexer._internal();
  factory SearchIndexer() => _instance;
  SearchIndexer._internal();

  final TextNormalizer _normalizer = TextNormalizer();
  
  /// Cache degli indici
  final Map<int, IndexedDocument> _indexCache = {};
  bool _isIndexed = false;

  /// Indicizza tutte le normative
  void indexDocuments(List<Normativa> normative) {
    _indexCache.clear();
    
    for (final normativa in normative) {
      final indexed = _indexDocument(normativa);
      _indexCache[normativa.id] = indexed;
    }
    
    _isIndexed = true;
    print('✅ Indicizzate ${_indexCache.length} normative');
  }

  /// Indicizza un singolo documento
  IndexedDocument _indexDocument(Normativa normativa) {
    // Normalizza i campi
    final normalizedTitle = _normalizer.normalize(normativa.decodedTitle);
    final normalizedContent = _normalizer.normalize(
      normativa.decodedContent.length > 2000 
        ? normativa.decodedContent.substring(0, 2000)
        : normativa.decodedContent
    );
    final normalizedType = _normalizer.normalize(normativa.typeDoc);
    final normalizedCategory = _normalizer.normalize(normativa.categoria ?? '');
    
    // Estrai keywords
    final titleKeywords = _normalizer.extractSignificantWords(normalizedTitle);
    final contentKeywords = _normalizer.extractSignificantWords(normalizedContent);
    
    // Parsing data
    DateTime date;
    try {
      date = DateTime.parse(normativa.date);
    } catch (e) {
      date = DateTime(1900); // Data fallback per normative senza data valida
    }
    
    return IndexedDocument(
      id: normativa.id,
      normalizedTitle: normalizedTitle,
      normalizedContent: normalizedContent,
      normalizedType: normalizedType,
      normalizedCategory: normalizedCategory,
      titleKeywords: titleKeywords,
      contentKeywords: contentKeywords,
      date: date,
      original: normativa,
    );
  }

  /// Ottieni un documento indicizzato
  IndexedDocument? getIndexedDocument(int id) {
    return _indexCache[id];
  }

  /// Ottieni tutti i documenti indicizzati
  List<IndexedDocument> getAllIndexedDocuments() {
    return _indexCache.values.toList();
  }

  /// Verifica se l'indice è stato creato
  bool get isIndexed => _isIndexed;

  /// Cerca documenti per categoria
  List<IndexedDocument> searchByCategory(String category) {
    final normalizedCategory = _normalizer.normalize(category);
    
    return _indexCache.values
        .where((doc) => doc.normalizedCategory.contains(normalizedCategory))
        .toList();
  }

  /// Cerca documenti per tipo
  List<IndexedDocument> searchByType(String type) {
    final normalizedType = _normalizer.normalize(type);
    
    return _indexCache.values
        .where((doc) => doc.normalizedType.contains(normalizedType))
        .toList();
  }

  /// Cerca documenti per range di date
  List<IndexedDocument> searchByDateRange(DateTime? start, DateTime? end) {
    return _indexCache.values.where((doc) {
      if (start != null && doc.date.isBefore(start)) return false;
      if (end != null && doc.date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// Ottieni le categorie uniche
  Set<String> getUniqueCategories() {
    return _indexCache.values
        .map((doc) => doc.original.categoria ?? 'Uncategorized')
        .toSet();
  }

  /// Ottieni i tipi di documento unici
  Set<String> getUniqueTypes() {
    return _indexCache.values
        .map((doc) => doc.original.typeDoc)
        .toSet();
  }

  /// Pulisci la cache
  void clearIndex() {
    _indexCache.clear();
    _isIndexed = false;
  }

  /// Ottieni statistiche sull'indice
  Map<String, dynamic> getIndexStats() {
    if (!_isIndexed) {
      return {'indexed': false};
    }
    
    return {
      'indexed': true,
      'total_documents': _indexCache.length,
      'unique_categories': getUniqueCategories().length,
      'unique_types': getUniqueTypes().length,
      'date_range': {
        'earliest': _indexCache.values
            .map((d) => d.date)
            .reduce((a, b) => a.isBefore(b) ? a : b),
        'latest': _indexCache.values
            .map((d) => d.date)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      },
    };
  }
}