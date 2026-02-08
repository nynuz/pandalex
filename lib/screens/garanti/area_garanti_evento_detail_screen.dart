import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app_constants.dart';
import '../../services/eventi_garanti_service.dart';
import '../../models/evento_garante.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/app_drawer.dart';
import 'area_garanti_evento_form_screen.dart';

class AreaGarantiEventoDetailScreen extends StatefulWidget {
  final String eventoId;

  const AreaGarantiEventoDetailScreen({
    Key? key,
    required this.eventoId,
  }) : super(key: key);

  @override
  State<AreaGarantiEventoDetailScreen> createState() => _AreaGarantiEventoDetailScreenState();
}

class _AreaGarantiEventoDetailScreenState extends State<AreaGarantiEventoDetailScreen> {
  final EventiGarantiService _eventiService = EventiGarantiService();
  EventoGarante? _evento;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvento();
  }

  Future<void> _loadEvento() async {
    setState(() => _isLoading = true);
    final evento = await _eventiService.getEvento(widget.eventoId);
    setState(() {
      _evento = evento;
      _isLoading = false;
    });
  }

  Future<void> _eliminaEvento() async {
    if (_evento == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Evento', style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
        content: Text(
          'Sei sicuro di voler eliminare questo evento?',
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
      final result = await _eventiService.eliminaEvento(_evento!.id, _evento!.immagineUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? AppConstants.green : Colors.red,
          ),
        );

        if (result['success']) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(
        title: 'Evento',
        showBackButton: true,
      ),
      endDrawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _evento == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppConstants.gray400),
                      const SizedBox(height: 16),
                      Text(
                        'Evento non trovato',
                        style: GoogleFonts.lato(fontSize: 18, color: AppConstants.gray600),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Immagine
                      if (_evento!.immagineUrl != null)
                        Image.network(
                          _evento!.immagineUrl!,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 300,
                            color: AppConstants.gray200,
                            child: Icon(Icons.broken_image, size: 64, color: AppConstants.gray400),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stato
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _evento!.pubblicato
                                    ? AppConstants.green.withOpacity(0.1)
                                    : AppConstants.gray300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _evento!.pubblicato ? 'Pubblicato' : 'Bozza',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _evento!.pubblicato
                                      ? AppConstants.greenDark
                                      : AppConstants.gray600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Titolo
                            Text(
                              _evento!.titolo,
                              style: GoogleFonts.lato(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.gray800,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Data Evento
                            Row(
                              children: [
                                Icon(Icons.event, size: 16, color: AppConstants.blueNcs),
                                const SizedBox(width: 8),
                                Text(
                                  'Data evento: ${DateFormat('dd MMMM yyyy', 'it_IT').format(_evento!.dataEvento!)}',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.blueNcs,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Date di sistema
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: AppConstants.gray500),
                                const SizedBox(width: 8),
                                Text(
                                  'Creato: ${DateFormat('dd/MM/yyyy HH:mm').format(_evento!.createdAt)}',
                                  style: GoogleFonts.lato(fontSize: 13, color: AppConstants.gray600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.update, size: 16, color: AppConstants.gray500),
                                const SizedBox(width: 8),
                                Text(
                                  'Modificato: ${DateFormat('dd/MM/yyyy HH:mm').format(_evento!.updatedAt)}',
                                  style: GoogleFonts.lato(fontSize: 13, color: AppConstants.gray600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Descrizione
                            Text(
                              'Descrizione',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.gray800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _evento!.descrizione,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                height: 1.6,
                                color: AppConstants.gray700,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Bottoni Azione
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AreaGarantiEventoFormScreen(
                                            evento: _evento,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadEvento();
                                      }
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: Text('Modifica', style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.blueNcs,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _eliminaEvento,
                                    icon: const Icon(Icons.delete),
                                    label: Text('Elimina', style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      side: const BorderSide(color: Colors.red),
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
    );
  }
}