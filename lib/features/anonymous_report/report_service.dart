// lib/features/anonymous_report/report_service.dart

import 'dart:io';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ReportService {
  static const String _recipientEmail = 'info@associazionepanda.it';
  
  /// Invia una segnalazione anonima via email
  Future<bool> sendAnonymousReport({
    required String imagePath,
    required String message,
  }) async {
    try {
      print('📧 Inizio invio segnalazione...');
      
      // Usa direttamente l'immagine originale se la compressione fallisce
      String finalImagePath = imagePath;
      
      try {
        finalImagePath = await _compressImage(imagePath);
        print('✅ Immagine compressa: $finalImagePath');
      } catch (e) {
        print('⚠️ Compressione fallita, uso immagine originale: $e');
        finalImagePath = imagePath;
      }
      
      // Prepara l'email
      final Email email = Email(
        body: _buildEmailBody(message),
        subject: 'Segnalazione Anonima - ${DateTime.now().toString().split('.')[0]}',
        recipients: [_recipientEmail],
        attachmentPaths: [finalImagePath],
        isHTML: false,
      );

      print('📨 Tentativo invio email...');
      
      // Invia l'email
      await FlutterEmailSender.send(email);
      
      print('✅ Email inviata con successo');
      
      // Pulisci il file temporaneo solo se diverso dall'originale
      if (finalImagePath != imagePath) {
        await _cleanupTempFile(finalImagePath);
      }
      
      return true;
    } catch (e) {
      print('❌ Errore invio segnalazione: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Comprimi l'immagine per ridurre le dimensioni
  Future<String> _compressImage(String imagePath) async {
    try {
      print('🗜️ Inizio compressione immagine...');
      
      // Leggi l'immagine originale
      final File imageFile = File(imagePath);
      
      if (!await imageFile.exists()) {
        throw Exception('File immagine non trovato: $imagePath');
      }
      
      final imageBytes = await imageFile.readAsBytes();
      print('📏 Dimensione originale: ${imageBytes.length} bytes');
      
      // Se l'immagine è già piccola (< 2MB), non comprimere
      if (imageBytes.length < 2 * 1024 * 1024) {
        print('✅ Immagine già ottimizzata, nessuna compressione necessaria');
        return imagePath;
      }
      
      final img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print('⚠️ Impossibile decodificare immagine, uso originale');
        return imagePath;
      }

      print('📐 Dimensioni originali: ${image.width}x${image.height}');

      // Ridimensiona se troppo grande (max 1920px sul lato più lungo)
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1920) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
        );
        print('📐 Nuove dimensioni: ${resized.width}x${resized.height}');
      }

      // Comprimi come JPEG con qualità 85
      final List<int> compressedBytes = img.encodeJpg(resized, quality: 85);
      print('📏 Dimensione compressa: ${compressedBytes.length} bytes');

      // Salva in un file temporaneo
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);

      print('✅ Immagine compressa salvata: $tempPath');
      return tempPath;
    } catch (e) {
      print('❌ Errore compressione immagine: $e');
      // In caso di errore, ritorna il path originale
      return imagePath;
    }
  }

  /// Costruisce il corpo dell'email
  String _buildEmailBody(String message) {
    final now = DateTime.now();
    return '''
SEGNALAZIONE DI PERICOLO

Data e ora: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}

Messaggio:
$message

---
Questa è una segnalazione generata automaticamente dall'app P.An.D.A Lex.
''';
  }

  /// Pulisce i file temporanei
  Future<void> _cleanupTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ File temporaneo eliminato: $filePath');
      }
    } catch (e) {
      print('⚠️ Errore pulizia file temporaneo: $e');
    }
  }
}