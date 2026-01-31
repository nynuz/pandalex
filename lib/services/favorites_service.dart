import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites';
  
  // Singleton pattern
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  /// Carica i preferiti salvati
  Future<List<int>> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        return favoritesList.cast<int>();
      }
      return [];
    } catch (e) {
      print('Errore nel caricamento dei preferiti: $e');
      return [];
    }
  }

  /// Salva i preferiti
  Future<void> saveFavorites(List<int> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(favorites);
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Errore nel salvataggio dei preferiti: $e');
    }
  }

  /// Aggiunge/rimuove un preferito
  Future<List<int>> toggleFavorite(int articleId, List<int> currentFavorites) async {
    List<int> updatedFavorites;
    
    if (currentFavorites.contains(articleId)) {
      updatedFavorites = currentFavorites.where((id) => id != articleId).toList();
    } else {
      updatedFavorites = [...currentFavorites, articleId];
    }
    
    await saveFavorites(updatedFavorites);
    return updatedFavorites;
  }

  /// Controlla se un articolo è tra i preferiti
  bool isFavorite(int articleId, List<int> favorites) {
    return favorites.contains(articleId);
  }
}