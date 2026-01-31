// widgets/emergency_banner.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_constants.dart';
import '../services/emergency_service.dart';

class EmergencyBanner extends StatefulWidget {
  const EmergencyBanner({Key? key}) : super(key: key);

  @override
  State<EmergencyBanner> createState() => _EmergencyBannerState();
}

class _EmergencyBannerState extends State<EmergencyBanner> with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  final EmergencyService _emergencyService = EmergencyService();
  PoliziaLocaleInfo? _poliziaInfo;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters per i dati da visualizzare
  String get nomeComando => _poliziaInfo?.nome ?? "Ricerca in corso...";
  String get indirizzo => _poliziaInfo?.indirizzo ?? "...";
  String get distanza => _poliziaInfo?.distanza != null 
    ? "${_poliziaInfo!.distanza!.toStringAsFixed(1)} km" 
    : "...";
  String? get numeroTelefono => _poliziaInfo?.telefono;

  String get displayText {
    if (_isLoading) {
      return '🚨 Ricerca Polizia Locale in corso...';
    }
    if (_errorMessage != null) {
      return '🚨 Emergenza: Chiama 112';
    }
    if (_poliziaInfo != null && _poliziaInfo!.distanza != null) {
      return '🚨 Emergenza: Polizia Locale (${_poliziaInfo!.distanza!.toStringAsFixed(1)} km)';
    }
    return '🚨 Emergenza: Polizia Locale';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    // Carica info polizia locale
    _loadPoliziaLocale();
  }

  Future<void> _loadPoliziaLocale() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final info = await _emergencyService.findNearestPoliziaLocale();
      
      if (mounted) {
        setState(() {
          _poliziaInfo = info;
          _isLoading = false;
          
          if (info == null) {
            _errorMessage = 'Nessuna Polizia Locale trovata nelle vicinanze';
          }
        });
      }
    } catch (e) {
      print('Errore caricamento polizia: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Errore nel recupero dei dati';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _handleCall() async {
    if (numeroTelefono == null || numeroTelefono!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numero di telefono non disponibile'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Rimuovi spazi e caratteri speciali dal numero
      final cleanNumber = numeroTelefono!
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '');
      
      final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);
      
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        throw 'Impossibile effettuare la chiamata';
      }
    } catch (e) {
      print('Errore nella chiamata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: impossibile chiamare $numeroTelefono'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleCallFallback(String number) async {
    try {
      final Uri telUri = Uri(scheme: 'tel', path: number);
      
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    } catch (e) {
      print('Errore nella chiamata fallback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.orange,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra collassata
          InkWell(
            onTap: _toggleExpanded,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Icona emergenza o loading
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.emergency,
                          color: Colors.white,
                          size: 24,
                        ),
                  const SizedBox(width: 12),
                  
                  // Testo
                  Expanded(
                    child: Text(
                      displayText,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Freccia
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenuto espanso
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppConstants.orangeDark,
                    width: 2,
                  ),
                ),
              ),
              child: _buildExpandedContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    // Stato di caricamento
    if (_isLoading) {
      return Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.orange),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Ricerca in corso...',
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                fontSize: 16,
                color: AppConstants.gray600,
              ),
            ),
          ),
        ],
      );
    }

    // Errore o nessun risultato - Fallback su 112
    if (_poliziaInfo == null || _errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Servizio Emergenze',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.gray800,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _errorMessage ?? 'Dati non disponibili',
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                fontSize: 14,
                color: AppConstants.gray600,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleCallFallback('112'),
              icon: const Icon(Icons.phone, size: 24),
              label: Text(
                'CHIAMA 112',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      );
    }

    // Contenuto normale con dati
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome comando
        Text(
          nomeComando,
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.gray800,
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingSmall),
        
        // Indirizzo
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppConstants.gray600,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                indirizzo,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.gray600,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Distanza
        Row(
          children: [
            const Icon(
              Icons.directions_walk,
              size: 18,
              color: AppConstants.gray600,
            ),
            const SizedBox(width: 4),
            Text(
              'Distanza: $distanza',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.gray600,
                ),
              ),
            ),
          ],
        ),
        
        // Telefono (se disponibile)
        if (numeroTelefono != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 18,
                  color: AppConstants.gray600,
                ),
                const SizedBox(width: 4),
                Text(
                  numeroTelefono!,
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
          ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        // Pulsante chiamata
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleCall,
            icon: const Icon(Icons.phone, size: 24),
            label: Text(
              'CHIAMA ORA',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}