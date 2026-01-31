import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class UserService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _userRoleKey = 'user_role';
  static const String _userEmailKey = 'user_email';
  
  final _supabase = Supabase.instance.client;
  
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  /// Verifica se l'utente ha completato l'onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      print('Errore nel controllo onboarding: $e');
      return false;
    }
  }

  /// Genera una password temporanea casuale
  String _generateTempPassword() {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      12, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
    ));
  }

  /// Salva i dati dell'utente durante l'onboarding usando Supabase Auth
  Future<bool> saveUserData({
    required String email,
    required String role,
  }) async {
    try {
      final cleanEmail = email.toLowerCase().trim();
      
      // Prova sempre a creare nuovo utente (se non esiste)
      try {
        final response = await _supabase.auth.signUp(
          email: cleanEmail,
          password: _generateTempPassword(),
        );

        if (response.user != null) {
          await _supabase.from('user_profiles').insert({
            'id': response.user!.id,
            'email': cleanEmail,
            'role': role,
          });
        }
      } on AuthException catch (authError) {
        // Se l'utente esiste già in auth.users, semplicemente continua
        if (authError.code != 'user_already_exists') {
          rethrow;
        }
        // Per user_already_exists, non fare nulla e continua
      }

      // Gestisci sempre il profilo (sia per utenti nuovi che esistenti)
      final existingProfile = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('email', cleanEmail);
      
      if (existingProfile.isNotEmpty) {
        // Aggiorna profilo esistente
        await _supabase
            .from('user_profiles')
            .update({
              'role': role,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('email', cleanEmail);
      }

      // Salva nelle SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, cleanEmail);
      await prefs.setString(_userRoleKey, role);
      await prefs.setBool(_onboardingKey, true);

      return true;
    } catch (e) {
      print('Errore nel salvataggio dati utente: $e');
      return false;
    }
  }

  /// Recupera il profilo dell'utente
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      final response = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', user.id)
          .single();
      
      return response;
    } catch (e) {
      print('Errore nel recupero profilo: $e');
      return null;
    }
  }

  /// Recupera l'email dell'utente dalle SharedPreferences
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      print('Errore nel recupero email: $e');
      return null;
    }
  }

  /// Recupera il ruolo dell'utente dalle SharedPreferences
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRoleKey);
    } catch (e) {
      print('Errore nel recupero ruolo: $e');
      return null;
    }
  }

  /// Recupera l'utente corrente da Supabase Auth
  Future<User?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      return user;
    } catch (e) {
      print('Errore nel recupero utente corrente: $e');
      return null;
    }
  }

  /// Recupera il ruolo dell'utente dai metadati di Supabase
  Future<String?> getUserRoleFromSupabase() async {
    try {
      final profile = await getUserProfile();
      return profile?['role'] as String?;
    } catch (e) {
      print('Errore nel recupero ruolo: $e');
      return null;
    }
  }

  /// Reset dell'onboarding (per debug/testing)
  Future<void> resetOnboarding() async {
    try {
      // Logout da Supabase
      await _supabase.auth.signOut();
      
      // Rimuovi dalle SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userRoleKey);
    } catch (e) {
      print('Errore nel reset onboarding: $e');
    }
  }

  /// Logout completo
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      await resetOnboarding();
    } catch (e) {
      print('Errore nel logout: $e');
    }
  }
}