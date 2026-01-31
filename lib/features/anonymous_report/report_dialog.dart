// lib/features/anonymous_report/report_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'report_service.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
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

  /// Mostra opzioni per scegliere fotocamera o galleria
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

  /// Seleziona un'immagine dalla fonte specificata
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

  /// Invia la segnalazione
  Future<void> _sendReport() async {
    // Validazione
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
          _showSuccessSnackbar('Segnalazione inviata con successo');
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

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(  // <-- AGGIUNGI QUESTO
          child: Padding(
            padding: EdgeInsets.only(  // <-- MODIFICA QUESTO
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(context).viewInsets.bottom,  // <-- IMPORTANTE: gestisce la tastiera
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SEGNALAZIONE DI PERICOLO',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sezione Immagine
                _buildImageSection(),
                const SizedBox(height: 20),

                // Campo Messaggio
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Descrivi la situazione',
                    hintText: 'Es: Cane randagio ferito in via...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

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
                  label: Text(_isLoading ? 'Invio in corso...' : 'Invia Segnalazione'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Info privacy
                const SizedBox(height: 12),
                const Text(
                  'La segnalazione verrà inviata tramite email. Nessun dato personale verrà raccolto o memorizzato.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              height: 200,
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
      );
    }

    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _showImageSourceOptions,
      icon: const Icon(Icons.add_a_photo, size: 32),
      label: const Text('Aggiungi Foto'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 60),
        side: BorderSide(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
          width: 0,
        ),
      ),
    );
  }
}