import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../app_constants.dart';
import '../models/evento_garante.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/app_drawer.dart';

class EventoPubblicoDetailScreen extends StatefulWidget {
  final EventoGarante evento;

  const EventoPubblicoDetailScreen({
    Key? key,
    required this.evento,
  }) : super(key: key);

  @override
  State<EventoPubblicoDetailScreen> createState() => _EventoPubblicoDetailScreenState();
}

class _EventoPubblicoDetailScreenState extends State<EventoPubblicoDetailScreen> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(
        title: 'Dettaglio Evento',
        showBackButton: true,
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => setState(() => _selectedIndex = index),
      ),
      endDrawer: const AppDrawer(),
      body: BackgroundWrapper( // MODIFICATO: usa BackgroundWrapper
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Immagine principale
              if (widget.evento.immagineUrl != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.evento.immagineUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain, // CAMBIATO da cover a contain
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: AppConstants.gray200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: AppConstants.gray400,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Card contenuto con background bianco
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // Badge Nazionale o Regione
                    if (widget.evento.regione != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: widget.evento.regione!.toUpperCase() == 'NAZIONALE'
                              ? AppConstants.orange.withOpacity(0.1)
                              : AppConstants.blueNcs.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: widget.evento.regione!.toUpperCase() == 'NAZIONALE'
                              ? Border.all(color: AppConstants.orange, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.evento.regione!.toUpperCase() == 'NAZIONALE'
                                  ? Icons.public
                                  : Icons.location_on,
                              size: 14,
                              color: widget.evento.regione!.toUpperCase() == 'NAZIONALE'
                                  ? AppConstants.orange
                                  : AppConstants.blueNcs,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.evento.regione!.toUpperCase() == 'NAZIONALE'
                                  ? 'EVENTO NAZIONALE'
                                  : widget.evento.regione!,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: widget.evento.regione!.toUpperCase() == 'NAZIONALE'
                                    ? AppConstants.orange
                                    : AppConstants.blueNcs,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Data
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppConstants.blueNcs,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMMM yyyy', 'it_IT').format(widget.evento.dataEvento),
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.blueNcs,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Titolo
                    Text(
                      widget.evento.titolo,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.gray800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 2,
                      width: 60,
                      color: AppConstants.blueNcs,
                    ),
                    const SizedBox(height: 20),

                    // Descrizione
                    Text(
                      widget.evento.descrizione,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: AppConstants.gray700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info aggiuntive
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.gray100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppConstants.blueNcs,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pubblicato il ${DateFormat('dd/MM/yyyy', 'it_IT').format(widget.evento.createdAt)}',
                              style: GoogleFonts.lato(
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppConstants.gray600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Spazio finale
            ],
          ),
        ),
      ),
    );
  }
}