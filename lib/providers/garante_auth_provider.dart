import 'package:flutter/material.dart';
import '../models/garante_auth.dart';
import '../services/auth_garanti_service.dart';

class GaranteAuthProvider with ChangeNotifier {
  final AuthGarantiService _authService = AuthGarantiService();
  
  GaranteAuth? _currentGarante;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  GaranteAuth? get currentGarante => _currentGarante;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Inizializza e verifica se l'utente è già autenticato
  Future<void> checkAuth() async { // RINOMINATO da initialize
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = _authService.isAuthenticated();
    
    // Se autenticato, recupera i dati del garante
    if (_isAuthenticated) {
      _currentGarante = await _authService.getGaranteCorrente();
      // Se non trova il garante, effettua logout
      if (_currentGarante == null) {
        await logout();
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success']) {
      _currentGarante = result['garante'];
      _isAuthenticated = true;
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentGarante = null;
    _isAuthenticated = false;

    _isLoading = false;
    notifyListeners();
  }
}