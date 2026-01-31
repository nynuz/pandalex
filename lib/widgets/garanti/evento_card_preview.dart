import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app_constants.dart';
import '../../models/evento_garante.dart';

class EventoCardPreview extends StatelessWidget {
  final EventoGarante evento;
  final VoidCallback? onTap;

  const EventoCardPreview({
    Key? key,
    required this.evento,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immagine o placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: evento.immagineUrl != null
                    ? Image.network(
                        evento.immagineUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              
              // Contenuto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titolo
                    Text(
                      evento.titolo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.gray800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Descrizione breve
                    Text(
                      evento.descrizioneBreve,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.gray600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Data e stato
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppConstants.gray400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(evento.dataEvento),
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 11,
                              color: AppConstants.gray500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: evento.pubblicato
                                ? AppConstants.green.withOpacity(0.1)
                                : AppConstants.gray300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            evento.pubblicato ? 'Pubblicato' : 'Bozza',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: evento.pubblicato
                                    ? AppConstants.greenDark
                                    : AppConstants.gray600,
                              ),
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppConstants.gray200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: AppConstants.gray400,
      ),
    );
  }
}