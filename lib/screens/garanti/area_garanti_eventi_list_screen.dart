import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_constants.dart';
import '../../providers/garante_auth_provider.dart';
import '../../services/eventi_garanti_service.dart';
import '../../models/evento_garante.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/app_drawer.dart';
import 'area_garanti_evento_detail_screen.dart';
import 'area_garanti_evento_form_screen.dart';

class AreaGarantiEventiListScreen extends StatefulWidget {
  const AreaGarantiEventiListScreen({Key? key}) : super(key: key);

  @override
  State<AreaGarantiEventiListScreen> createState() => _AreaGarantiEventiListScreenState();
}

class _AreaGarantiEventiListScreenState extends State<AreaGarantiEventiListScreen> {
  final EventiGarantiService _eventiService = EventiGarantiService();
  List<EventoGarante> _eventi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventi();
  }

  Future<void> _loadEventi() async {
    setState(() => _isLoading = true);

    final garanteId = context.read<GaranteAuthProvider>().currentGarante?.id;
    if (garanteId != null) {
      final eventi = await _eventiService.getTuttiEventi(garanteId);
      setState(() {
        _eventi = eventi;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminaEvento(EventoGarante evento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Evento', style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
        content: Text(
          'Sei sicuro di voler eliminare "${evento.titolo}"?',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annulla', style: GoogleFonts.lato()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Elimina', style: GoogleFonts.lato(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _eventiService.eliminaEvento(evento.id, evento.immagineUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? AppConstants.green : Colors.red,
          ),
        );

        if (result['success']) {
          _loadEventi();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(
        title: 'Eventi',
        showBackButton: true,
      ),
      endDrawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AreaGarantiEventoFormScreen(),
            ),
          );
          if (result == true) _loadEventi();
        },
        backgroundColor: AppConstants.blueNcs,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEventi,
              child: _eventi.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _eventi.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildEventoCard(_eventi[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEventoCard(EventoGarante evento) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AreaGarantiEventoDetailScreen(eventoId: evento.id),
            ),
          );
          if (result == true) _loadEventi();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immagine
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: evento.immagineUrl != null
                    ? Image.network(
                        evento.immagineUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              
              // Contenuto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titolo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.gray800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: AppConstants.gray400),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(evento.dataEvento),
                          style: GoogleFonts.lato(fontSize: 11, color: AppConstants.gray500),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: evento.pubblicato
                                ? AppConstants.green.withOpacity(0.1)
                                : AppConstants.gray300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            evento.pubblicato ? 'Pubblicato' : 'Bozza',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: evento.pubblicato
                                  ? AppConstants.greenDark
                                  : AppConstants.gray600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Azioni
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AreaGarantiEventoFormScreen(evento: evento),
                                ),
                              );
                              if (result == true) _loadEventi();
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text('Modifica', style: GoogleFonts.lato(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.blueNcs,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _eliminaEvento(evento),
                            icon: const Icon(Icons.delete, size: 16),
                            label: Text('Elimina', style: GoogleFonts.lato(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppConstants.gray200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_outlined, size: 40, color: AppConstants.gray400),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 80, color: AppConstants.gray400),
            const SizedBox(height: 16),
            Text(
              'Nessun evento creato',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea il tuo primo evento cliccando sul pulsante in basso',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 14, color: AppConstants.gray500),
            ),
          ],
        ),
      ),
    );
  }
}