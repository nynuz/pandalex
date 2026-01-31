/// Servizio per normalizzare e pulire il testo prima della ricerca
class TextNormalizer {
  static final TextNormalizer _instance = TextNormalizer._internal();
  factory TextNormalizer() => _instance;
  TextNormalizer._internal();

  /// Mappa degli HTML entities comuni
  static const Map<String, String> _htmlEntities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#039;': "'",
    '&#8217;': "'",
    '&nbsp;': ' ',
    '&hellip;': '...',
    '&#8220;': '"',
    '&#8221;': '"',
    '&agrave;': 'à',
    '&egrave;': 'è',
    '&eacute;': 'é',
    '&igrave;': 'ì',
    '&ograve;': 'ò',
    '&ugrave;': 'ù',
  };

  /// Mappa delle abbreviazioni legali comuni
  static const Map<String, String> _abbreviations = {
    'art.': 'articolo',
    'artt.': 'articoli',
    'dpr': 'decreto del presidente della repubblica',
    'd.p.r.': 'decreto del presidente della repubblica',
    'dl': 'decreto legge',
    'd.l.': 'decreto legge',
    'dlgs': 'decreto legislativo',
    'd.lgs.': 'decreto legislativo',
    'dpcm': 'decreto del presidente del consiglio dei ministri',
    'd.p.c.m.': 'decreto del presidente del consiglio dei ministri',
    'l.': 'legge',
    'n.': 'numero',
    'c.p.': 'codice penale',
    'c.c.': 'codice civile',
  };

  /// Normalizza un testo completo
  String normalize(String text) {
    if (text.isEmpty) return '';
    
    String normalized = text;
    
    // 1. Rimuovi prefisso "Privato:"
    normalized = _removePrivatePrefix(normalized);
    
    // 2. Decodifica HTML entities
    normalized = _decodeHtmlEntities(normalized);
    
    // 3. Normalizza abbreviazioni
    normalized = _expandAbbreviations(normalized);
    
    // 4. Lowercase e trim
    normalized = normalized.toLowerCase().trim();
    
    // 5. Normalizza spazi multipli
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    return normalized;
  }

  /// Normalizza solo per matching (più aggressivo)
  String normalizeForMatching(String text) {
    String normalized = normalize(text);
    
    // Rimuovi punteggiatura
    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), ' ');
    
    // Normalizza spazi
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return normalized;
  }

  /// Rimuove il prefisso "Privato:" dai titoli
  String _removePrivatePrefix(String text) {
    return text.replaceAll(RegExp(r'^Privato:\s*', caseSensitive: false), '');
  }

  /// Decodifica HTML entities
  String _decodeHtmlEntities(String text) {
    String decoded = text;
    
    _htmlEntities.forEach((entity, char) {
      decoded = decoded.replaceAll(entity, char);
    });
    
    return decoded;
  }

  /// Espande le abbreviazioni legali comuni
  String _expandAbbreviations(String text) {
    String expanded = text;
    
    _abbreviations.forEach((abbr, full) {
      // Match con word boundary per evitare false sostituzioni
      expanded = expanded.replaceAll(
        RegExp(r'\b' + RegExp.escape(abbr) + r'\b', caseSensitive: false),
        full,
      );
    });
    
    return expanded;
  }

  /// Estrae solo parole significative (>= 3 caratteri)
  List<String> extractSignificantWords(String text) {
    final normalized = normalizeForMatching(text);
    final words = normalized.split(RegExp(r'\s+'));
    
    return words
        .where((word) => word.length >= 3)
        .where((word) => !isStopWord(word))
        .toList();
  }

  /// Verifica se una parola è uno stopword italiano
  bool isStopWord(String word) {
    // Stopwords italiane comuni
    const stopWords = {
      'del', 'della', 'dei', 'delle', 'dal', 'dalla', 'dai', 'dalle',
      'con', 'per', 'tra', 'fra', 'nel', 'nella', 'nei', 'nelle', 'in',
      'sul', 'sulla', 'sui', 'sulle', 'come', 'anche', 'alla',
      'allo', 'agli', 'alle', 'uno', 'una', 'gli', 'le', 'lo', 'la',
      'sia', 'sono', 'essere', 'avere', 'fare', 'questo', 'quella',
    };
    
    return stopWords.contains(word);
  }

  /// Ottieni la radice di una parola (stemming semplice italiano)
  String stem(String word) {
    if (word.length <= 4) return word;
    
    // Suffissi italiani comuni
    final suffixes = ['zione', 'zioni', 'mente', 'ità', 'ale', 'ali', 'are', 'ire', 'ere', 'ato', 'ita', 'ito', 'ate', 'ati', 'ite', 'iti'];
    
    for (final suffix in suffixes) {
      if (word.endsWith(suffix) && word.length > suffix.length + 2) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    
    // Plurali
    if (word.endsWith('i') && word.length > 3) {
      return word.substring(0, word.length - 1);
    }
    if (word.endsWith('e') && word.length > 3) {
      return word.substring(0, word.length - 1);
    }
    
    return word;
  }
}