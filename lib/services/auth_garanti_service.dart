import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/garante_auth.dart';

class AuthGarantiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Login con email e password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Autenticazione con Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (authResponse.user == null) {
        return {
          'success': false,
          'message': 'Errore durante l\'autenticazione',
        };
      }

      // Recupera i dati del garante dalla tabella garanti
      final garanteData = await _supabase
          .from('garanti')
          .select()
          .eq('email', email.trim())
          .single();

      if (garanteData == null) {
        await _supabase.auth.signOut();
        return {
          'success': false,
          'message': 'Garante non trovato',
        };
      }

      // Verifica se il garante è attivo
      if (garanteData['attivo'] != true) {
        await _supabase.auth.signOut();
        return {
          'success': false,
          'message': 'Account non attivo. Contatta l\'amministratore.',
        };
      }

      final garante = GaranteAuth.fromJson(garanteData);

      return {
        'success': true,
        'garante': garante,
        'message': 'Login effettuato con successo',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.message),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante il login: ${e.toString()}',
      };
    }
  }

  // Recupera i dati del garante loggato
  Future<GaranteAuth?> getGaranteCorrente() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final garanteData = await _supabase
          .from('garanti')
          .select()
          .eq('id', user.id)
          .single();

      if (garanteData == null) return null;

      return GaranteAuth.fromJson(garanteData);
    } catch (e) {
      debugPrint('Errore recupero garante corrente: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Verifica se l'utente è autenticato
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // Ottieni l'utente corrente
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Elimina l'account del garante corrente
  // NOTA: Non fa logout automatico, deve essere gestito dal chiamante
  Future<Map<String, dynamic>> eliminaAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'Utente non autenticato',
        };
      }

      // Chiama la funzione RPC per eliminare l'account
      final response = await _supabase.rpc('delete_garante_account');

      if (response != null && response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Account eliminato con successo',
          'deleted_eventi': response['deleted_eventi'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': response?['message'] ?? 'Errore durante l\'eliminazione',
        };
      }
    } catch (e) {
      debugPrint('Errore eliminazione account: $e');
      return {
        'success': false,
        'message': 'Errore durante l\'eliminazione: ${e.toString()}',
      };
    }
  }

  // Messaggio di errore user-friendly
  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email o password non corretti';
    } else if (error.contains('Email not confirmed')) {
      return 'Email non confermata';
    } else if (error.contains('User not found')) {
      return 'Utente non trovato';
    } else {
      return 'Errore durante l\'autenticazione';
    }
  }
}