import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import '../../models/normativa.dart';
import 'text_normalizer.dart';
import 'query_expander.dart';
import 'search_indexer.dart';
import 'ranking_engine.dart';

/// Servizio principale per la ricerca fuzzy avanzata
class FuzzySearchService {
  static final FuzzySearchService _instance = FuzzySearchService._internal();
  factory FuzzySearchService() => _instance;
  FuzzySearchService._internal();

  // Servizi modulari
  final TextNormalizer _normalizer = TextNormalizer();
  final QueryExpander _expander = QueryExpander();
  final SearchIndexer _indexer = SearchIndexer();
  final RankingEngine _ranker = RankingEngine();
  
  /// Indicizza le normative (chiamare una volta all'avvio)
  void indexNormative(List<Normativa> normative) {
    _indexer.indexDocuments(normative);
    print('🔍 Motore di ricerca pronto con ${normative.length} documenti');
  }

  /// Ricerca avanzata con tutti i miglioramenti
  List<Normativa> searchNormativeAdvanced(String query, List<Normativa> allNormative) {
    if (query.trim().isEmpty) {
      return [];
    }

    // Indicizza se non già fatto
    if (!_indexer.isIndexed) {
      indexNormative(allNormative);
    }

    // 1. NORMALIZZA QUERY
    final normalizedQuery = _normalizer.normalize(query);
    final queryTokens = _normalizer.extractSignificantWords(normalizedQuery);
    
    // 2. ESPANDI QUERY (sinonimi e acronimi)
    final expandedTerms = _expander.expandQuery(normalizedQuery);
    
    // 3. CERCA E CALCOLA SCORE
    final results = <SearchResult>[];
    final documents = _indexer.getAllIndexedDocuments();
    
    for (final doc in documents) {
      // Prova con query originale
      final result = _ranker.scoreDocument(doc, normalizedQuery, queryTokens);
      if (result != null) {
        results.add(result);
        continue;
      }
      
      // Prova con termini espansi
      for (final expandedTerm in expandedTerms) {
        if (expandedTerm == normalizedQuery) continue;
        
        final expandedTokens = _normalizer.extractSignificantWords(expandedTerm);
        final expandedResult = _ranker.scoreDocument(doc, expandedTerm, expandedTokens);
        
        if (expandedResult != null) {
          results.add(expandedResult);
          break;
        }
      }
    }
    
    // 4. ORDINA PER SCORE
    final sortedResults = _ranker.sortResults(results);
    
    // 5. RITORNA LE NORMATIVE ORIGINALI
    return sortedResults.map((r) => r.document.original).toList();
  }

  /// Ricerca per metadata (categoria, tipo, data)
  List<Normativa> searchByMetadata({
    String? category,
    String? type,
    DateTime? dateStart,
    DateTime? dateEnd,
  }) {
    if (!_indexer.isIndexed) {
      return [];
    }

    List<IndexedDocument> results = _indexer.getAllIndexedDocuments();
    
    // Filtra per categoria
    if (category != null && category.isNotEmpty) {
      results = _indexer.searchByCategory(category);
    }
    
    // Filtra per tipo
    if (type != null && type.isNotEmpty) {
      final typeResults = _indexer.searchByType(type);
      results = results.where((doc) => typeResults.any((t) => t.id == doc.id)).toList();
    }
    
    // Filtra per data
    if (dateStart != null || dateEnd != null) {
      final dateResults = _indexer.searchByDateRange(dateStart, dateEnd);
      results = results.where((doc) => dateResults.any((d) => d.id == doc.id)).toList();
    }
    
    // Ordina per data decrescente
    results.sort((a, b) => b.date.compareTo(a.date));
    
    return results.map((doc) => doc.original).toList();
  }

  /// Ottieni suggerimenti per una query parziale
  List<String> getSuggestions(String partialQuery) {
    if (partialQuery.length < 3) return [];
    
    final suggestions = <String>{};
    final normalized = _normalizer.normalize(partialQuery);
    
    // Aggiungi termini correlati
    final related = _expander.getRelatedTerms(normalized);
    suggestions.addAll(related);
    
    // Aggiungi categorie che matchano
    final categories = _indexer.getUniqueCategories();
    for (final category in categories) {
      final normalizedCategory = _normalizer.normalize(category);
      if (normalizedCategory.contains(normalized)) {
        suggestions.add(category);
      }
    }
    
    return suggestions.take(10).toList();
  }

  /// Ottieni statistiche sull'indice
  Map<String, dynamic> getSearchStats() {
    return _indexer.getIndexStats();
  }

  /// Ricerca semplice (per compatibilità)
  List<Normativa> searchNormative(String query, List<Normativa> allNormative) {
    return searchNormativeAdvanced(query, allNormative);
  }

  /// Pulisci cache e indice
  void clearCache() {
    _indexer.clearIndex();
  }
}