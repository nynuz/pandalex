import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import '../models/normativa.dart';

class FuzzySearchService {
  static final FuzzySearchService _instance = FuzzySearchService._internal();
  factory FuzzySearchService() => _instance;
  FuzzySearchService._internal();

  /// Soglia minima di similarità
  static const int _minScore = 75;

  /// Cerca normative usando strategia multipla
  List<Normativa> searchNormativeAdvanced(String query, List<Normativa> allNormative) {
    if (query.trim().isEmpty) {
      return [];
    }

    final queryLower = query.toLowerCase().trim();
    final queryTokens = queryLower.split(RegExp(r'\s+')).where((t) => t.length >= 3).toList();
    
    final results = <({Normativa normativa, int score})>[];

    for (final normativa in allNormative) {
      final titleLower = normativa.decodedTitle.toLowerCase();
      final contentLower = normativa.decodedContent.toLowerCase();
      
      int maxScore = 0;

      // STRATEGIA 1: Match esatto della query completa
      if (titleLower.contains(queryLower)) {
        maxScore = 100;
      } else if (contentLower.contains(queryLower)) {
        maxScore = 90;
      } else if (queryTokens.length > 1) {
        // STRATEGIA 2: Query multi-parola - analizza token con fuzzy
        final tokenResult = _analyzeTokensWithFuzzy(queryTokens, titleLower, contentLower);
        maxScore = tokenResult.score;
      } else {
        // STRATEGIA 3: Query singola parola - fuzzy matching
        final singleTokenScore = _analyzeSingleToken(queryLower, titleLower, contentLower);
        maxScore = singleTokenScore;
      }

      // Aggiungi ai risultati solo se supera la soglia
      if (maxScore >= _minScore) {
        results.add((normativa: normativa, score: maxScore));
      }
    }

    // Ordina per data decrescente (più recenti prima) mantenendo l'ordine per score
    // Per risultati con lo stesso score, ordina per data
    results.sort((a, b) {
    // Prima ordina per data (più recente prima)
    try {
      final dateA = DateTime.parse(a.normativa.date);
      final dateB = DateTime.parse(b.normativa.date);
      final dateComparison = dateB.compareTo(dateA);
      if (dateComparison != 0) return dateComparison;
    } catch (e) {
      // Se il parsing fallisce, continua con lo score
    }
    
    // Se le date sono uguali, ordina per score
    return b.score.compareTo(a.score);
  });

    // Genera snippet per ogni risultato
    final resultsWithSnippets = results.map((r) {
      final snippet = _extractSnippet(
        r.normativa.decodedContent, 
        query,
        contextLength: 80
      );
      
      final highlightPos = _findHighlightPositions(snippet, query);
      
      // Se la query non è stata trovata nello snippet, non mostrare snippet
      final shouldShowSnippet = highlightPos.isNotEmpty;
      
      // Crea una nuova istanza con snippet
      return r.normativa.copyWith(
        searchSnippet: shouldShowSnippet ? snippet : null,
        highlightPositions: shouldShowSnippet ? highlightPos : null,
      );
    }).toList();

    return resultsWithSnippets;
  }

  /// Analizza token con fuzzy matching per variazioni grammaticali
  ({int score, bool allTokensFound}) _analyzeTokensWithFuzzy(
    List<String> queryTokens, 
    String titleLower, 
    String contentLower
  ) {
    if (queryTokens.isEmpty) {
      return (score: 0, allTokensFound: false);
    }

    int foundInTitle = 0;
    int foundInContent = 0;
    int fuzzyFoundInTitle = 0;
    int fuzzyFoundInContent = 0;

    // Estrai le parole dal titolo e contenuto
    final titleWords = titleLower.split(RegExp(r'\W+')).where((w) => w.length >= 3).toList();
    final contentWords = contentLower.split(RegExp(r'\W+')).where((w) => w.length >= 3).toList();

    for (final token in queryTokens) {
      bool foundExactInTitle = false;
      bool foundExactInContent = false;
      bool foundFuzzyInTitle = false;
      bool foundFuzzyInContent = false;

      // Match esatto
      if (titleLower.contains(token)) {
        foundExactInTitle = true;
        foundInTitle++;
      }
      if (contentLower.contains(token)) {
        foundExactInContent = true;
        foundInContent++;
      }

      // Se non trovato esatto, cerca fuzzy (per variazioni grammaticali)
      if (!foundExactInTitle) {
        for (final word in titleWords) {
          if (_areSimilarWords(token, word)) {
            foundFuzzyInTitle = true;
            fuzzyFoundInTitle++;
            break;
          }
        }
      }

      if (!foundExactInContent && !foundFuzzyInTitle) {
        for (final word in contentWords) {
          if (_areSimilarWords(token, word)) {
            foundFuzzyInContent = true;
            fuzzyFoundInContent++;
            break;
          }
        }
      }
    }

    final totalTokens = queryTokens.length;
    final totalFoundInTitle = foundInTitle + fuzzyFoundInTitle;
    final totalFoundInContent = foundInContent + fuzzyFoundInContent;
    
    // Tutti i token devono essere trovati (esatti o fuzzy)
    final allTokensFound = (totalFoundInTitle >= totalTokens) || (totalFoundInContent >= totalTokens);

    int score = 0;

    if (!allTokensFound) {
      // Se non tutti i token sono trovati, score molto basso
      score = 0;
    } else {
      // Calcola score in base a dove sono stati trovati
      if (totalFoundInTitle >= totalTokens) {
        // Tutti nel titolo
        if (foundInTitle == totalTokens) {
          score = 95; // Tutti esatti nel titolo
        } else {
          score = 90; // Tutti nel titolo (alcuni fuzzy)
        }
      } else if (totalFoundInContent >= totalTokens) {
        // Tutti nel contenuto
        if (foundInContent == totalTokens) {
          score = 85; // Tutti esatti nel contenuto
        } else {
          score = 80; // Tutti nel contenuto (alcuni fuzzy)
        }
      }
    }

    return (score: score, allTokensFound: allTokensFound);
  }

  /// Analizza singolo token
  int _analyzeSingleToken(String token, String titleLower, String contentLower) {
    // Match esatto
    if (titleLower.contains(token)) {
      return 95;
    }
    if (contentLower.contains(token)) {
      return 85;
    }

    // Match fuzzy
    final titleWords = titleLower.split(RegExp(r'\W+')).where((w) => w.length >= 3);
    for (final word in titleWords) {
      if (_areSimilarWords(token, word)) {
        return 90;
      }
    }

    final contentWords = contentLower.split(RegExp(r'\W+')).where((w) => w.length >= 3);
    for (final word in contentWords) {
      if (_areSimilarWords(token, word)) {
        return 80;
      }
    }

    // Fallback: usa fuzzywuzzy SOLO sul titolo (più affidabile)
    // Il contenuto è troppo lungo e genera falsi positivi
    final titleScore = tokenSortPartialRatio(token, titleLower);
    
    // Soglia molto alta per evitare falsi positivi
    if (titleScore >= 90) {
      return titleScore;
    }
    
    return 0;  // Nessun match trovato
  }

  /// Verifica se due parole sono simili (per gestire variazioni grammaticali)
  bool _areSimilarWords(String word1, String word2) {
    
    // Calcola similarità usando Levenshtein
    final similarity = ratio(word1, word2);
    
    // Soglia basata sulla lunghezza delle parole
    if (word1.length >= 8 || word2.length >= 8) {
      // Parole lunghe: accetta 85% di similarità (es: "avvelenate" vs "avvelenati")
      return similarity >= 85;
    } else if (word1.length >= 5 || word2.length >= 5) {
      // Parole medie: richiede 90% di similarità
      return similarity >= 90;
    } else {
      // Parole corte: richiede 95% di similarità (per evitare falsi positivi)
      return similarity >= 95;
    }
  }

  /// Ricerca semplice (per compatibilità)
  List<Normativa> searchNormative(String query, List<Normativa> allNormative) {
    return searchNormativeAdvanced(query, allNormative);
  }

  String _extractSnippet(String content, String query, {int contextLength = 100}) {
    // Prima rimuovi i tag HTML dal contenuto
    final cleanContent = _removeHtmlTags(content);
    
    final contentLower = cleanContent.toLowerCase();
    final queryLower = query.toLowerCase();
    
    // Trova la posizione della query nel contenuto
    int position = contentLower.indexOf(queryLower);
    
    if (position == -1) {
      // Se non trova la query esatta, cerca il primo token
      final tokens = queryLower.split(RegExp(r'\s+'));
      for (final token in tokens) {
        position = contentLower.indexOf(token);
        if (position != -1) break;
      }
    }
    
    if (position == -1) {
      // Fallback: ritorna l'inizio del contenuto pulito
      return cleanContent.length > contextLength * 2 
          ? '${cleanContent.substring(0, contextLength * 2)}...' 
          : cleanContent;
    }
    
    // Calcola inizio e fine dello snippet
    int start = (position - contextLength).clamp(0, cleanContent.length);
    int end = (position + queryLower.length + contextLength).clamp(0, cleanContent.length);
    
    // Cerca di non tagliare a metà parola
    if (start > 0) {
      // Cerca lo spazio più vicino prima
      int spacePos = cleanContent.lastIndexOf(' ', start);
      if (spacePos > start - 20) start = spacePos + 1;
    }
    
    if (end < cleanContent.length) {
      // Cerca lo spazio più vicino dopo
      int spacePos = cleanContent.indexOf(' ', end);
      if (spacePos != -1 && spacePos < end + 20) end = spacePos;
    }
    
    String snippet = cleanContent.substring(start, end).trim();
    
    // Aggiungi ellissi
    if (start > 0) snippet = '...$snippet';
    if (end < cleanContent.length) snippet = '$snippet...';
    
    return snippet;
  }

  /// Rimuove i tag HTML e pulisce il testo
  String _removeHtmlTags(String htmlText) {
    // Rimuovi tutti i tag HTML
    String cleanText = htmlText.replaceAll(RegExp(r'<[^>]*>'), ' ');
    
    // Decodifica le entità HTML comuni
    cleanText = cleanText
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#8217;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&egrave;', 'è')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&agrave;', 'à')
        .replaceAll('&ograve;', 'ò')
        .replaceAll('&igrave;', 'ì')
        .replaceAll('&ugrave;', 'ù');
    
    // Rimuovi spazi multipli e va a capo
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleanText;
  }

  /// Trova le posizioni esatte della query nello snippet per l'highlight
  List<int> _findHighlightPositions(String snippet, String query) {
    final snippetLower = snippet.toLowerCase();
    final queryLower = query.toLowerCase();
    
    int start = snippetLower.indexOf(queryLower);
    
    if (start == -1) {
      // Cerca il primo token
      final tokens = queryLower.split(RegExp(r'\s+'));
      for (final token in tokens) {
        start = snippetLower.indexOf(token);
        if (start != -1) {
          return [start, start + token.length];
        }
      }
      return [];
    }
    
    return [start, start + queryLower.length];
  }
}