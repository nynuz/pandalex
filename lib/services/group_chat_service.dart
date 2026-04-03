import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import 'chat_encryption_service.dart';

class GroupChatService {
  static final GroupChatService _instance = GroupChatService._internal();
  factory GroupChatService() => _instance;
  GroupChatService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ChatEncryptionService _encryption = ChatEncryptionService();

  // Cache locale: garanteId → {nome, cognome}
  final Map<String, Map<String, String?>> _senderCache = {};

  /// Carica gli ultimi [limit] messaggi.
  /// Risolve i nomi dei mittenti con una query separata sulla tabella garanti
  /// (il FK garante_id → auth.users non consente il JOIN automatico con garanti).
  Future<List<ChatMessage>> fetchMessages({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('group_chat_messages')
          .select()
          .order('created_at', ascending: true)
          .limit(limit);

      if ((response as List).isEmpty) return [];

      // Raccoglie gli id univoci dei mittenti e recupera i loro nomi
      final garanteIds = response
          .map((r) => r['garante_id'] as String)
          .toSet()
          .toList();

      await _cacheSenderNames(garanteIds);

      final messages = <ChatMessage>[];
      for (final json in response) {
        try {
          final mutableJson = Map<String, dynamic>.from(json);
          final garanteId = json['garante_id'] as String;
          _injectSenderFromCache(mutableJson, garanteId);

          final decrypted = _encryption.decryptMessage(
            json['content'] as String,
            json['iv'] as String,
          );
          messages.add(ChatMessage.fromJson(mutableJson, decrypted));
        } catch (e) {
          debugPrint('Errore decifratura messaggio ${json['id']}: $e');
        }
      }
      return messages;
    } catch (e) {
      debugPrint('Errore fetch messaggi chat: $e');
      return [];
    }
  }

  /// Invia un messaggio cifrandolo prima dell'invio.
  Future<bool> sendMessage(String plaintext, String garanteId) async {
    try {
      final encrypted = _encryption.encryptMessage(plaintext.trim());
      await _supabase.from('group_chat_messages').insert({
        'garante_id': garanteId,
        'content': encrypted.ciphertext,
        'iv': encrypted.iv,
      });
      return true;
    } catch (e) {
      debugPrint('Errore invio messaggio chat: $e');
      return false;
    }
  }

  /// Sottoscrizione Realtime per i nuovi messaggi INSERT.
  /// Se il mittente non è in cache (primo messaggio dopo l'apertura),
  /// recupera il nome prima di notificare.
  RealtimeChannel subscribeToNewMessages(
    void Function(ChatMessage message) onMessage,
  ) {
    final channel = _supabase
        .channel('group_chat_room')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_chat_messages',
          callback: (PostgresChangePayload payload) async {
            try {
              final json = Map<String, dynamic>.from(payload.newRecord);
              final garanteId = json['garante_id'] as String;

              if (!_senderCache.containsKey(garanteId)) {
                await _cacheSenderNames([garanteId]);
              }
              _injectSenderFromCache(json, garanteId);

              final decrypted = _encryption.decryptMessage(
                json['content'] as String,
                json['iv'] as String,
              );
              onMessage(ChatMessage.fromJson(json, decrypted));
            } catch (e) {
              debugPrint('Errore realtime chat: $e');
            }
          },
        )
        .subscribe();
    return channel;
  }

  /// Conta i messaggi creati dopo [since] (per il badge messaggi non letti).
  Future<int> countMessagesSince(DateTime since) async {
    try {
      final response = await _supabase
          .from('group_chat_messages')
          .select('id')
          .gt('created_at', since.toUtc().toIso8601String());
      return (response as List).length;
    } catch (e) {
      debugPrint('Errore conteggio messaggi non letti: $e');
      return 0;
    }
  }

  /// Rimuove la sottoscrizione realtime.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  // ---------------------------------------------------------------------------
  // Helpers privati
  // ---------------------------------------------------------------------------

  /// Recupera nome e cognome per una lista di garante_id e li salva in cache.
  Future<void> _cacheSenderNames(List<String> garanteIds) async {
    try {
      final result = await _supabase
          .from('garanti')
          .select('id, nome, cognome')
          .inFilter('id', garanteIds);

      for (final row in result as List) {
        _senderCache[row['id'] as String] = {
          'nome': row['nome'] as String?,
          'cognome': row['cognome'] as String?,
        };
      }
    } catch (e) {
      debugPrint('Errore recupero nomi garanti: $e');
    }
  }

  /// Inietta nel JSON del messaggio i campi garanti dalla cache.
  void _injectSenderFromCache(Map<String, dynamic> json, String garanteId) {
    final cached = _senderCache[garanteId];
    if (cached != null) {
      json['garanti'] = {
        'nome': cached['nome'],
        'cognome': cached['cognome'],
      };
    }
  }
}
