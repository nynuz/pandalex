import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_constants.dart';
import '../../providers/garante_auth_provider.dart';
import '../../services/eventi_garanti_service.dart';
import '../../models/evento_garante.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/garanti/evento_card_preview.dart';
import 'area_garanti_eventi_list_screen.dart';
import 'area_garanti_evento_detail_screen.dart';
import 'area_garanti_evento_form_screen.dart';
import 'area_garanti_profilo_screen.dart';
import 'area_garanti_group_chat_screen.dart';
import '../../providers/group_chat_provider.dart';

class AreaGarantiDashboardScreen extends StatefulWidget {
  const AreaGarantiDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AreaGarantiDashboardScreen> createState() => _AreaGarantiDashboardScreenState();
}

class _AreaGarantiDashboardScreenState extends State<AreaGarantiDashboardScreen> {
  final EventiGarantiService _eventiService = EventiGarantiService();
  int _eventiCount = 0;
  List<EventoGarante> _ultimiEventi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<GaranteAuthProvider>();
    final garanteId = authProvider.currentGarante?.id;

    if (garanteId != null) {
      final count = await _eventiService.getEventiCount(garanteId);
      final ultimi = await _eventiService.getUltimiEventi(garanteId, limit: 3);

      setState(() {
        _eventiCount = count;
        _ultimiEventi = ultimi;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }

    // Carica il conteggio messaggi non letti per il badge della chat
    if (mounted) {
      context.read<GroupChatProvider>().loadUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<GaranteAuthProvider>();
    final garante = authProvider.currentGarante;

    return Scaffold(
      appBar: TopBar(
        title: 'Dashboard',
        showBackButton: false,
      ),
      endDrawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Naviga al form di creazione evento
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AreaGarantiEventoFormScreen(),
            ),
          );
          
          // Se è stato creato un evento, ricarica i dati
          if (result == true) {
            _loadDashboardData();
          }
        },
        backgroundColor: AppConstants.blueNcs,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Crea Evento',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con benvenuto
                      _buildWelcomeHeader(garante?.nomeCompleto ?? 'Garante'),
                      const SizedBox(height: 12),

                      // Card riepilogo
                      _buildSummaryCard(),
                      const SizedBox(height: 12),

                      // Card accesso chat di gruppo
                      _buildChatAccessCard(),
                      const SizedBox(height: 36),

                      // Sezione ultimi eventi
                      _buildUltimiEventiSection(),
                      const SizedBox(height: 100), // Spazio per FAB
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String nomeGarante) {
    return Card(
      elevation: 0,
      color: AppConstants.blueNcs.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AreaGarantiProfiloScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.blueNcs,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benvenuto,',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.gray600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nomeGarante,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.gray800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Logout',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                      ),
                      content: Text(
                        'Sei sicuro di voler uscire?',
                        style: GoogleFonts.lato(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Annulla', style: GoogleFonts.lato()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Esci',
                            style: GoogleFonts.lato(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await context.read<GaranteAuthProvider>().logout();
                    if (mounted) {
                      Navigator.pop(context); // Il wrapper gestirà il redirect al login
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_note,
                size: 32,
                color: AppConstants.greenDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eventi Creati',
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_eventiCount',
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.gray800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatAccessCard() {
    return Consumer<GroupChatProvider>(
      builder: (context, chatProvider, _) {
        final unread = chatProvider.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                onTap: () {
                  context.read<GroupChatProvider>().initialize();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AreaGarantiGroupChatScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.blueNcs.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 32,
                          color: AppConstants.blueNcs,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chat Garanti',
                              style: GoogleFonts.lato(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.gray800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gruppo riservato ai garanti',
                              style: GoogleFonts.lato(
                                textStyle: AppConstants.cardSubtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppConstants.gray400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Badge messaggi non letti
            if (unread > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUltimiEventiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ultimi Eventi',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.gray800,
                ),
              ),
            ),
            if (_ultimiEventi.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AreaGarantiEventiListScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
                child: Text(
                  'Vedi tutti',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.blueNcs,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_ultimiEventi.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ultimiEventi.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return EventoCardPreview(
                evento: _ultimiEventi[index],
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AreaGarantiEventoDetailScreen(
                        eventoId: _ultimiEventi[index].id,
                      ),
                    ),
                  );
                  if (result == true) _loadDashboardData();
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: AppConstants.gray100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: AppConstants.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun evento creato',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.gray600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea il tuo primo evento cliccando sul pulsante in basso',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.gray500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}