/// Servizio per espandere le query con sinonimi e acronimi
class QueryExpander {
  static final QueryExpander _instance = QueryExpander._internal();
  factory QueryExpander() => _instance;
  QueryExpander._internal();

  /// Mappa dei sinonimi per termini comuni
  static const Map<String, List<String>> _synonyms = {
    'cane': ['cani', 'canino', 'canidi', 'animale domestico'],
    'gatto': ['gatti', 'felino', 'felidi'],
    'animale': ['animali', 'fauna', 'bestiame'],
    'maltrattamento': ['maltrattamenti', 'abuso', 'violenza', 'sevizie', 'crudeltà'],
    'abbandono': ['abbandoni', 'abbandona', 'abbandonare'],
    'randagio': ['randagi', 'randagismo', 'vagante', 'vaganti'],
    'custodia': ['detenzione', 'possesso', 'mantenimento'],
    'benessere': ['tutela', 'protezione', 'salute', 'cura'],
    'avvelenamento': ['avvelenato', 'avvelenati', 'avvelenata', 'avvelenate', 'veleno'],
    'esca': ['esche', 'boccone', 'bocconi'],
    'circolo': ['circhi', 'spettacolo', 'intrattenimento'],
    'canile': ['canili', 'rifugio', 'ricovero'],
    'microchip': ['chip', 'identificazione', 'registrazione'],
    'sterilizzazione': ['sterilizzare', 'castrazione', 'castrare'],
    'veterinario': ['veterinaria', 'vet', 'medico veterinario'],
    'ordinanza': ['ordinanze', 'disposizione', 'provvedimento'],
    'legge': ['leggi', 'normativa', 'normative', 'legislazione'],
    'decreto': ['decreti', 'provvedimento', 'disposizione'],
    'regolamento': ['regolamenti', 'disciplina', 'norme'],
    'sanzione': ['sanzioni', 'multa', 'multe', 'penale', 'penali'],
    'reato': ['reati', 'crimine', 'crimini', 'illecito'],
  };

  /// Mappa degli acronimi legali
  static const Map<String, String> _acronyms = {
    'dpr': 'decreto del presidente della repubblica',
    'dl': 'decreto legge',
    'dlgs': 'decreto legislativo',
    'dpcm': 'decreto del presidente del consiglio dei ministri',
    'guri': 'gazzetta ufficiale della repubblica italiana',
    'cp': 'codice penale',
    'cc': 'codice civile',
    'tua': 'testo unico ambientale',
    'iaa': 'interventi assistiti con animali',
    'asl': 'azienda sanitaria locale',
    'enpa': 'ente nazionale protezione animali',
    'lav': 'lega anti vivisezione',
    'lndc': 'lega nazionale per la difesa del cane',
  };

  /// Espande una query con sinonimi e acronimi
  List<String> expandQuery(String query) {
    final List<String> expandedTerms = [query]; // Include sempre la query originale
    final tokens = query.toLowerCase().split(RegExp(r'\s+'));
    
    for (final token in tokens) {
      // Espandi acronimi
      if (_acronyms.containsKey(token)) {
        expandedTerms.add(_acronyms[token]!);
      }
      
      // Espandi sinonimi
      if (_synonyms.containsKey(token)) {
        expandedTerms.addAll(_synonyms[token]!);
      }
      
      // Cerca sinonimi che contengono il token come radice
      _synonyms.forEach((key, values) {
        if (key.startsWith(token) || token.startsWith(key)) {
          expandedTerms.addAll(values);
        }
      });
    }
    
    return expandedTerms.toSet().toList(); // Rimuovi duplicati
  }

  /// Ottieni sinonimi per un singolo termine
  List<String> getSynonyms(String term) {
    final termLower = term.toLowerCase();
    
    if (_synonyms.containsKey(termLower)) {
      return _synonyms[termLower]!;
    }
    
    // Cerca sinonimi dove il termine è nella lista dei valori
    for (final entry in _synonyms.entries) {
      if (entry.value.contains(termLower)) {
        return [entry.key, ...entry.value.where((s) => s != termLower)];
      }
    }
    
    return [];
  }

  /// Espandi un acronimo
  String? expandAcronym(String acronym) {
    return _acronyms[acronym.toLowerCase()];
  }

  /// Verifica se una stringa è un acronimo conosciuto
  bool isKnownAcronym(String text) {
    return _acronyms.containsKey(text.toLowerCase());
  }

  /// Ottieni termini correlati per suggerimenti
  List<String> getRelatedTerms(String query) {
    final Set<String> related = {};
    final tokens = query.toLowerCase().split(RegExp(r'\s+'));
    
    for (final token in tokens) {
      // Aggiungi sinonimi diretti
      if (_synonyms.containsKey(token)) {
        related.addAll(_synonyms[token]!);
      }
      
      // Aggiungi espansioni acronimi
      if (_acronyms.containsKey(token)) {
        related.add(_acronyms[token]!);
      }
    }
    
    return related.toList();
  }
}