// widgets/emergency_modal.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_constants.dart';
import '../services/emergency_service.dart';

class EmergencyModal extends StatefulWidget {
  const EmergencyModal({Key? key}) : super(key: key);

  @override
  State<EmergencyModal> createState() => _EmergencyModalState();
}

class _EmergencyModalState extends State<EmergencyModal> {
  final EmergencyService _emergencyService = EmergencyService();
  PoliziaLocaleInfo? _poliziaInfo;
  bool _isLoading = true;
  String? _errorMessage;

  String get nomeComando => _poliziaInfo?.nome ?? "Ricerca in corso...";
  String get indirizzo => _poliziaInfo?.indirizzo ?? "...";
  String get distanza => _poliziaInfo?.distanza != null 
    ? "${_poliziaInfo!.distanza!.toStringAsFixed(1)} km" 
    : "...";
  String? get numeroTelefono => _poliziaInfo?.telefono;

  @override
  void initState() {
    super.initState();
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

  Future<void> _handleCall() async {
    if (numeroTelefono == null || numeroTelefono!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numero di telefono non disponibile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final cleanNumber = numeroTelefono!
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '');
      
      final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);
      
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        Navigator.pop(context);
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
        Navigator.pop(context);
      }
    } catch (e) {
      print('Errore nella chiamata fallback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          gradient: const LinearGradient(
            colors: [AppConstants.orange, AppConstants.orangeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  const Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SOS EMERGENZA',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.orange),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Ricerca Polizia Locale in corso...',
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

    if (_poliziaInfo == null || _errorMessage != null) {
      return Column(
        children: [
          const Icon(
            Icons.phone_in_talk,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Servizio Emergenze',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppConstants.gray800,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _errorMessage ?? 'Dati non disponibili',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                fontSize: 14,
                color: AppConstants.gray600,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleCallFallback('112'),
              icon: const Icon(Icons.phone, size: 28),
              label: Text(
                'CHIAMA 112',
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome comando
        Text(
          nomeComando,
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.gray800,
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        // Indirizzo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: AppConstants.gray600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                indirizzo,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 15,
                    color: AppConstants.gray600,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Distanza
        Row(
          children: [
            const Icon(
              Icons.directions_walk,
              size: 20,
              color: AppConstants.gray600,
            ),
            const SizedBox(width: 8),
            Text(
              'Distanza: $distanza',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.gray600,
                ),
              ),
            ),
          ],
        ),
        
        // Telefono
        if (numeroTelefono != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 20,
                  color: AppConstants.blueNcs,
                ),
                const SizedBox(width: 8),
                Text(
                  numeroTelefono!,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.blueNcs,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: AppConstants.paddingLarge),
        
        // Pulsante chiamata
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleCall,
            icon: const Icon(Icons.phone, size: 28),
            label: Text(
              'CHIAMA ORA',
              style: GoogleFonts.montserrat(
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
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