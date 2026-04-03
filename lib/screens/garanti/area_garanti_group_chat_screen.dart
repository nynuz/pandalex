import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_constants.dart';
import '../../providers/garante_auth_provider.dart';
import '../../providers/group_chat_provider.dart';
import '../../models/chat_message.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/app_drawer.dart';

class AreaGarantiGroupChatScreen extends StatefulWidget {
  const AreaGarantiGroupChatScreen({Key? key}) : super(key: key);

  @override
  State<AreaGarantiGroupChatScreen> createState() =>
      _AreaGarantiGroupChatScreenState();
}

class _AreaGarantiGroupChatScreenState
    extends State<AreaGarantiGroupChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() => setState(() {}));
    // Azzera il badge dei messaggi non letti appena si apre la chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupChatProvider>().markAsRead();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    final authProvider = context.read<GaranteAuthProvider>();
    final garanteId = authProvider.currentGarante?.id;
    if (garanteId == null) return;

    setState(() => _isSending = true);
    _inputController.clear();

    await context.read<GroupChatProvider>().sendMessage(text, garanteId);

    if (mounted) {
      setState(() => _isSending = false);
      // Scorri all'ultimo messaggio dopo l'invio
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: 'Chat Garanti', showBackButton: true),
      endDrawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Consumer<GroupChatProvider>(
      builder: (context, chatProvider, _) {
        // Azzera badge se arrivano nuovi messaggi mentre la chat è aperta
        if (chatProvider.unreadCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) chatProvider.markAsRead();
          });
        }

        // Mostra errori tramite SnackBar
        if (chatProvider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(chatProvider.errorMessage!),
                backgroundColor: Colors.red.shade700,
              ),
            );
            chatProvider.clearError();
          });
        }

        if (chatProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.blueNcs),
          );
        }

        if (chatProvider.messages.isEmpty) {
          return _buildEmptyState();
        }

        final messages = chatProvider.messages;
        // Scorri al fondo alla prima ricezione messaggi
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final currentUserId =
                context.read<GaranteAuthProvider>().currentGarante?.id;
            final isOwn = msg.garanteId == currentUserId;
            return _buildMessageBubble(msg, isOwn);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 200;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(compact ? AppConstants.paddingMedium : AppConstants.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: compact ? 32 : 48,
                      color: AppConstants.gray400,
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Text(
                      'Nessun messaggio ancora.',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.gray700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inizia la conversazione!',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppConstants.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isOwn) {
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);
    final bubbleColor =
        isOwn ? AppConstants.blueNcs : AppConstants.gray200;
    final textColor = isOwn ? Colors.white : AppConstants.gray800;
    final timestampColor =
        isOwn ? Colors.white70 : AppConstants.gray500;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(AppConstants.borderRadiusLarge),
      topRight: const Radius.circular(AppConstants.borderRadiusLarge),
      bottomLeft: isOwn
          ? const Radius.circular(AppConstants.borderRadiusLarge)
          : Radius.zero,
      bottomRight: isOwn
          ? Radius.zero
          : const Radius.circular(AppConstants.borderRadiusLarge),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isOwn) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                  child: Text(
                    msg.senderDisplay,
                    style: GoogleFonts.lato(
                      textStyle: AppConstants.cardSubtitle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.blueNcs,
                      ),
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      msg.contentDecrypted,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: timestampColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final canSend =
        _inputController.text.trim().isNotEmpty && !_isSending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppConstants.gray200, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMedium,
        AppConstants.paddingSmall,
        AppConstants.paddingSmall,
        AppConstants.paddingSmall +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: AppConstants.gray800,
              ),
              decoration: InputDecoration(
                hintText: 'Scrivi un messaggio...',
                hintStyle: GoogleFonts.lato(
                  fontSize: 15,
                  color: AppConstants.gray400,
                ),
                filled: true,
                fillColor: AppConstants.gray100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusXLarge,
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusXLarge,
                  ),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusXLarge,
                  ),
                  borderSide: const BorderSide(
                    color: AppConstants.blueNcs,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: canSend ? (_) => _sendMessage() : null,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: canSend ? AppConstants.blueNcs : AppConstants.gray300,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: canSend ? _sendMessage : null,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
