import 'dart:math';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'search_indexer.dart';
import 'text_normalizer.dart';

/// Risultato di ricerca con score
class SearchResult {
  final IndexedDocument document;
  final int score;
  final Map<String, int> scoreBreakdown;
  
  SearchResult({
    required this.document,
    required this.score,
    required this.scoreBreakdown,
  });
}

/// Engine per il calcolo del ranking e scoring dei risultati
class RankingEngine {
  static final RankingEngine _instance = RankingEngine._internal();
  factory RankingEngine() => _instance;
  RankingEngine._internal();

  final TextNormalizer _normalizer = TextNormalizer();
  
  /// Pesi per i diversi campi
  static const int _categoryWeight = 100;
  static const int _typeWeight = 90;
  static const int _titleWeight = 80;
  static const int _contentWeight = 60;
  
  /// Soglia minima per considerare un match
  static const int _minScore = 75;
  
  /// Boost per documenti recenti (percentuale)
  static const double _recencyBoost = 0.10; // 10%

  /// Calcola score per un documento rispetto a una query - VERSIONE RESTRITTIVA
  SearchResult? scoreDocument(
    IndexedDocument doc,
    String normalizedQuery,
    List<String> queryTokens,
  ) {
    final scoreBreakdown = <String, int>{};
    int totalScore = 0;
    
    // FILTRO PRELIMINARE: Per query multi-token, RICHIEDI proximity obbligatoria
    if (queryTokens.length > 1) {
      final significantTokens = queryTokens.where((t) => t.length >= 3 && !_normalizer.isStopWord(t)).toList();
      
      if (significantTokens.length > 1) {
        // DEVE esserci proximity, altrimenti score = 0
        bool hasProximity = _areTokensProximate(doc.normalizedTitle, significantTokens, maxDistance: 30) ||
                          _areTokensProximate(doc.normalizedContent, significantTokens, maxDistance: 100);
        
        if (!hasProximity) {
          // NESSUN MATCH - ritorna subito null
          return null;
        }
      }
    }
    
    // 1. MATCH ESATTO nella query completa
    final exactScore = _calculateExactScore(doc, normalizedQuery, scoreBreakdown);
    totalScore = max(totalScore, exactScore);
    
    // 2. MATCH PER CATEGORIA
    if (doc.normalizedCategory.isNotEmpty && normalizedQuery.length >= 4) {
      final categoryScore = _calculateFieldScore(
        normalizedQuery,
        doc.normalizedCategory,
        _categoryWeight,
      );
      if (categoryScore >= 85) { // Solo match molto buoni
        scoreBreakdown['category'] = categoryScore;
        totalScore = max(totalScore, categoryScore);
      }
    }
    
    // 3. MATCH PER TIPO DOCUMENTO
    if (normalizedQuery.length >= 4) {
      final typeScore = _calculateFieldScore(
        normalizedQuery,
        doc.normalizedType,
        _typeWeight,
      );
      if (typeScore >= 85) { // Solo match molto buoni
        scoreBreakdown['type'] = typeScore;
        totalScore = max(totalScore, typeScore);
      }
    }
    
    // 4. ANALISI TOKEN CON PROXIMITY (già verificata sopra)
    if (queryTokens.isNotEmpty) {
      final tokenScore = _calculateTokenScore(doc, queryTokens, scoreBreakdown);
      totalScore = max(totalScore, tokenScore);
    }
    
    // 5. FUZZY MATCHING - SOLO per query singola parola lunga
    if (totalScore < _minScore && queryTokens.length == 1 && normalizedQuery.length >= 5) {
      final fuzzyScore = _calculateFuzzyScore(doc, normalizedQuery, scoreBreakdown);
      totalScore = max(totalScore, fuzzyScore);
    }
    
    // 6. BOOST PER RECENCY (solo se c'è già uno score valido)
    if (totalScore >= _minScore) {
      final recencyBoost = _calculateRecencyBoost(doc.date);
      scoreBreakdown['recency_boost'] = recencyBoost;
      totalScore += recencyBoost;
    }
    
    // Ritorna null se sotto soglia
    if (totalScore < _minScore) {
      return null;
    }
    
    return SearchResult(
      document: doc,
      score: totalScore,
      scoreBreakdown: scoreBreakdown,
    );
  }

  /// Calcola score per match esatti
  int _calculateExactScore(
    IndexedDocument doc,
    String query,
    Map<String, int> breakdown,
  ) {
    // Query deve essere almeno 5 caratteri per match esatto
    if (query.length < 5) return 0;
    
    if (doc.normalizedTitle.contains(query)) {
      breakdown['exact_title'] = 100;
      return 100;
    }
    if (doc.normalizedContent.contains(query)) {
      breakdown['exact_content'] = 90;
      return 90;
    }
    return 0;
  }

  /// Calcola score per un campo specifico
  int _calculateFieldScore(String query, String field, int weight) {
    if (field.isEmpty) return 0;
    
    if (field.contains(query)) {
      return weight;
    }
    
    // Fuzzy match sul campo
    final similarity = ratio(query, field);
    if (similarity >= 85) {
      return (weight * (similarity / 100)).round();
    }
    
    return 0;
  }

  /// Verifica se i token sono vicini tra loro nel testo (proximity matching)
  bool _areTokensProximate(String text, List<String> tokens, {int maxDistance = 50}) {
    if (tokens.isEmpty) return false;
    if (tokens.length == 1) return text.contains(tokens.first);
    
    // TUTTI i token devono essere presenti
    for (final token in tokens) {
      if (!text.contains(token)) {
        return false; // Se manca anche un solo token, return false
      }
    }
    
    // Trova tutte le posizioni di ogni token
    final positions = <String, List<int>>{};
    
    for (final token in tokens) {
      final tokenPositions = <int>[];
      int index = text.indexOf(token);
      
      while (index != -1) {
        tokenPositions.add(index);
        index = text.indexOf(token, index + 1);
      }
      
      positions[token] = tokenPositions;
    }
    
    // Verifica se esiste una combinazione di posizioni dove tutti i token
    // sono entro maxDistance caratteri l'uno dall'altro
    final firstToken = tokens.first;
    final firstPositions = positions[firstToken]!;
    
    for (final startPos in firstPositions) {
      bool allWithinRange = true;
      int minPos = startPos;
      int maxPos = startPos + tokens.first.length;
      
      for (int i = 1; i < tokens.length; i++) {
        final token = tokens[i];
        final tokenPositions = positions[token]!;
        
        // Cerca la posizione più vicina a questo range
        bool foundNear = false;
        for (final pos in tokenPositions) {
          final distance = (pos - startPos).abs();
          if (distance <= maxDistance) {
            foundNear = true;
            minPos = pos < minPos ? pos : minPos;
            maxPos = (pos + token.length) > maxPos ? (pos + token.length) : maxPos;
            break;
          }
        }
        
        if (!foundNear) {
          allWithinRange = false;
          break;
        }
      }
      
      // Verifica che la distanza totale sia entro il limite
      if (allWithinRange && (maxPos - minPos) <= maxDistance) {
        return true;
      }
    }
    
    return false;
  }

  /// Calcola score basato su token con PROXIMITY MATCHING
  int _calculateTokenScore(
    IndexedDocument doc,
    List<String> queryTokens,
    Map<String, int> breakdown,
  ) {
    final significantTokens = queryTokens.where((t) => t.length >= 3).toList();
    
    if (significantTokens.isEmpty) return 0;
    
    // Per query multi-token, richiedi PROXIMITY
    if (significantTokens.length > 1) {
      // Verifica proximity nel titolo
      bool titleProximity = _areTokensProximate(
        doc.normalizedTitle, 
        significantTokens, 
        maxDistance: 30  // Massimo 30 caratteri di distanza nel titolo
      );
      
      if (titleProximity) {
        breakdown['token_proximity_title'] = 95;
        return 95;
      }
      
      // Verifica proximity nel contenuto
      bool contentProximity = _areTokensProximate(
        doc.normalizedContent, 
        significantTokens, 
        maxDistance: 100  // Massimo 100 caratteri di distanza nel contenuto
      );
      
      if (contentProximity) {
        breakdown['token_proximity_content'] = 85;
        return 85;
      }
      
      // Se non c'è proximity, return 0
      breakdown['token_match'] = 0;
      return 0;
    }
    
    // Query singolo token - logica esistente
    final token = significantTokens.first;
    
    if (doc.normalizedTitle.contains(token)) {
      breakdown['single_title'] = 95;
      return 95;
    }
    if (doc.normalizedContent.contains(token)) {
      breakdown['single_content'] = 85;
      return 85;
    }
    
    // Fuzzy match
    if (_hasWordMatch(token, doc.titleKeywords, threshold: 90)) {
      breakdown['single_fuzzy_title'] = 88;
      return 88;
    }
    if (_hasWordMatch(token, doc.contentKeywords, threshold: 90)) {
      breakdown['single_fuzzy_content'] = 78;
      return 78;
    }
    
    return 0;
  }

  /// Calcola score per singolo token
  int _calculateSingleTokenScore(
    IndexedDocument doc,
    String token,
    Map<String, int> breakdown,
  ) {
    if (doc.normalizedTitle.contains(token)) {
      breakdown['single_title'] = 95;
      return 95;
    }
    if (doc.normalizedContent.contains(token)) {
      breakdown['single_content'] = 85;
      return 85;
    }
    
    // Fuzzy match
    if (_hasWordMatch(token, doc.titleKeywords)) {
      breakdown['single_fuzzy_title'] = 90;
      return 90;
    }
    if (_hasWordMatch(token, doc.contentKeywords)) {
      breakdown['single_fuzzy_content'] = 80;
      return 80;
    }
    
    return 0;
  }

  /// Calcola score fuzzy (fallback)
  int _calculateFuzzyScore(
    IndexedDocument doc,
    String query,
    Map<String, int> breakdown,
  ) {
    final titleScore = tokenSortPartialRatio(query, doc.normalizedTitle);
    final contentScore = partialRatio(query, doc.normalizedContent);
    
    final maxScore = max(titleScore, contentScore);
    
    // Applica una soglia minima anche al fuzzy score
    // Se il fuzzy score è troppo basso, non è un match valido
    if (maxScore < 75) {  // Soglia minima per fuzzy matching
      return 0;
    }
    
    if (titleScore > contentScore) {
      breakdown['fuzzy_title'] = titleScore;
    } else {
      breakdown['fuzzy_content'] = contentScore;
    }
    
    return maxScore;
  }

  /// Verifica match fuzzy tra parole
  bool _hasWordMatch(String token, List<String> words, {int threshold = 90}) {  // Da 85 a 90
    for (final word in words) {
      if (word.length < 3) continue;
      
      // Substring match - SOLO se il token è sufficientemente lungo
      if (token.length >= 4 && (word.contains(token) || token.contains(word))) {
        return true;
      }
      
      // Fuzzy match con soglia più alta
      final similarity = ratio(token, word);
      if (similarity >= threshold) {
        return true;
      }
    }
    return false;
  }

  /// Calcola boost per documenti recenti
  int _calculateRecencyBoost(DateTime date) {
    final now = DateTime.now();
    final age = now.difference(date).inDays;
    
    // Documenti dell'ultimo anno: +10 punti
    if (age <= 365) {
      return 10;
    }
    // Documenti degli ultimi 3 anni: +5 punti
    if (age <= 1095) {
      return 5;
    }
    // Documenti degli ultimi 5 anni: +2 punti
    if (age <= 1825) {
      return 2;
    }
    
    return 0;
  }

  /// Calcola penalità per titoli generici/ripetitivi
  int _calculateGenericPenalty(String title) {
    // Titoli che iniziano con pattern ripetitivi
    final genericPatterns = [
      'proroga dell',
      'modifica',
      'integrazione',
      'disposizioni in materia',
    ];
    
    for (final pattern in genericPatterns) {
      if (title.startsWith(pattern)) {
        return 5; // Penalità di 5 punti
      }
    }
    
    return 0;
  }

  /// Ordina i risultati per score decrescente
  List<SearchResult> sortResults(List<SearchResult> results) {
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}