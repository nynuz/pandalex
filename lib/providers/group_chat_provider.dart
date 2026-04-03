import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../services/group_chat_service.dart';

const _kLastReadKey = 'chat_last_read_at';

class GroupChatProvider extends ChangeNotifier {
  final GroupChatService _service = GroupChatService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _channel;
  bool _initialized = false;

  int _unreadCount = 0;
  DateTime _lastReadAt = DateTime.fromMillisecondsSinceEpoch(0);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  /// Carica i messaggi iniziali e attiva la sottoscrizione realtime.
  /// Può essere chiamato più volte: la seconda chiamata è no-op.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final fetched = await _service.fetchMessages();
    _messages = fetched;
    _isLoading = false;
    notifyListeners();

    _channel = _service.subscribeToNewMessages(_onNewMessage);
  }

  /// Carica il conteggio dei messaggi non letti senza inizializzare la chat.
  /// Chiamato dalla dashboard all'avvio.
  Future<void> loadUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastReadKey) ?? 0;
    _lastReadAt = DateTime.fromMillisecondsSinceEpoch(ms);
    _unreadCount = await _service.countMessagesSince(_lastReadAt);
    notifyListeners();
  }

  /// Marca tutti i messaggi come letti e azzera il badge.
  /// Chiamato all'apertura e durante la permanenza nella chat screen.
  Future<void> markAsRead() async {
    if (_unreadCount == 0) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(_kLastReadKey, now.millisecondsSinceEpoch);
    _lastReadAt = now;
    _unreadCount = 0;
    notifyListeners();
  }

  /// Invia un messaggio. [garanteId] è l'UUID del garante autenticato.
  Future<void> sendMessage(String text, String garanteId) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final success = await _service.sendMessage(trimmed, garanteId);
    if (!success) {
      _errorMessage = 'Impossibile inviare il messaggio. Riprova.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _onNewMessage(ChatMessage message) {
    if (_messages.any((m) => m.id == message.id)) return;
    _messages = [..._messages, message];
    // Incrementa solo se il messaggio è arrivato dopo l'ultima lettura
    if (message.createdAt.isAfter(_lastReadAt)) {
      _unreadCount++;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_channel != null) {
      _service.unsubscribe(_channel!);
    }
    super.dispose();
  }
}
