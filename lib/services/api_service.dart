import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/garante.dart';
import '../models/caso_sentenza.dart';
import '../models/normativa.dart';

class ApiService {
  static const String baseUrl = 'https://pandalex.associazionepanda.it/wp-json';
  
  // Singleton pattern per riutilizzare l'istanza
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Recupera tutte le strutture/garanti
  Future<List<Garante>> getAllGaranti() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/strutture/v1/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => Garante.fromJson(item))
            .where((garante) => garante.hasValidCoordinates) // Filtra solo quelli con coordinate valide
            .toList();
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nel recupero delle Garante: $e');
    }
  }

  /// Recupera tutti i casi e sentenze
  Future<List<CasoSentenza>> getCasiSentenze() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/xml-importer/v1/casi-sentenze'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => CasoSentenza.fromJson(item))
            .toList();
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nel recupero dei casi e sentenze: $e');
    }
  }

  /// Recupera i dettagli di un singolo caso/sentenza
  Future<CasoSentenza> getCasoSentenzaDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/xml-importer/v1/caso-sentenza/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return CasoSentenza.fromJson(jsonData);
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nel recupero del dettaglio caso/sentenza: $e');
    }
  }

  /// Recupera le normative in evidenza (top 10)
  Future<List<Normativa>> getNormativeInEvidenza() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/xml-importer/v1/recent-articles'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .take(10) // Prendi solo le prime 10
            .map((item) => Normativa.fromJson(item))
            .toList();
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nel recupero delle normative in evidenza: $e');
    }
  }
  
  /// Recupera tutti gli articoli per la ricerca nei preferiti
  Future<List<Normativa>> getAllArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/xml-importer/v1/all-articles'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => Normativa.fromJson(item))
            .toList();
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nel recupero di tutti gli articoli: $e');
    }
  }

  /// Ricerca articoli per keyword
  Future<List<Normativa>> searchArticles(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/xml-importer/v1/search-articles?keyword=${Uri.encodeComponent(keyword)}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => Normativa.fromJson(item))
            .toList();
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nella ricerca degli articoli: $e');
    }
  }

  /// Recupera le categorie degli articoli per i filtri
  Future<List<String>> getArticleCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/xml-importer/v1/article-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.cast<String>();
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nel recupero delle categorie: $e');
    }
  }

  /// Recupera i dettagli di un singolo articolo
  Future<Normativa> getArticleDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/xml-importer/v1/article/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Normativa.fromJson(jsonData);
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nel recupero del dettaglio articolo: $e');
    }
  }
}