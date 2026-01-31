import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../app_constants.dart';
import '../widgets/emergency_scaffold.dart';
import '../widgets/background_wrapper.dart';
import '../features/anonymous_report/report_service.dart';

class SegnalazioneScreen extends StatefulWidget {
  const SegnalazioneScreen({Key? key}) : super(key: key);

  @override
  State<SegnalazioneScreen> createState() => _SegnalazioneScreenState();
}

class _SegnalazioneScreenState extends State<SegnalazioneScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ReportService _reportService = ReportService();
  
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotocamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galleria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Errore durante la selezione dell\'immagine');
      }
    }
  }

  Future<void> _sendReport() async {
    if (_selectedImage == null) {
      _showErrorSnackbar('Seleziona una foto per la segnalazione');
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      _showErrorSnackbar('Scrivi un messaggio per la segnalazione');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _reportService.sendAnonymousReport(
        imagePath: _selectedImage!.path,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Segnalazione inviata con successo'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorSnackbar('Errore durante l\'invio. Riprova.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Errore durante l\'invio della segnalazione');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmergencyScaffold(
      title: "Segnalazione di Pericolo",
      showBackButton: true,
      showBottomNav: false,
      body: BackgroundWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Info card
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppConstants.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  border: Border.all(color: AppConstants.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppConstants.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Utilizza questo modulo per segnalare situazioni di pericolo per animali',
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: AppConstants.gray700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Sezione Foto
              Text(
                'FOTO DELLA SITUAZIONE',
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.gray700,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              
              _buildImageSection(),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Campo Messaggio
              Text(
                'DESCRIZIONE',
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.gray700,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              
              TextField(
                controller: _messageController,
                maxLines: 6,
                maxLength: 500,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Descrivi la situazione di pericolo...\nEs: zona con sospetto bocconi avvelenati, trappole illegali, ecc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                  filled: true,
                  fillColor: AppConstants.white,
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Pulsante Invio
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendReport,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isLoading ? 'Invio in corso...' : 'INVIA SEGNALAZIONE',
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppConstants.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Info privacy
              Text(
                'La segnalazione verrà inviata tramite email. Nessun dato personale verrà raccolto o memorizzato.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.gray500,
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_selectedImage != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              child: Image.file(
                _selectedImage!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            if (!_isLoading)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _isLoading ? null : _showImageSourceOptions,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppConstants.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: AppConstants.gray300,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 48,
              color: AppConstants.gray400,
            ),
            const SizedBox(height: 12),
            Text(
              'Aggiungi Foto',
              style: GoogleFonts.lato(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: AppConstants.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}