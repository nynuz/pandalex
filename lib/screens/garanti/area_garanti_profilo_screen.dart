import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_constants.dart';
import '../../providers/garante_auth_provider.dart';
import '../../services/auth_garanti_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/app_drawer.dart';

class AreaGarantiProfiloScreen extends StatelessWidget {
  const AreaGarantiProfiloScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<GaranteAuthProvider>();
    final garante = authProvider.currentGarante;

    return Scaffold(
      appBar: TopBar(
        title: 'Profilo',
        showBackButton: true,
      ),
      endDrawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icona profilo
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppConstants.blueNcs.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 64,
                    color: AppConstants.blueNcs,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Card con dati personali
              Text(
                'Dati Personali',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.gray800,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildDataField(
                        icon: Icons.person_outline,
                        label: 'Nome',
                        value: garante?.nome ?? 'N/A',
                      ),
                      const Divider(height: 24),
                      _buildDataField(
                        icon: Icons.person_outline,
                        label: 'Cognome',
                        value: garante?.cognome ?? 'N/A',
                      ),
                      const Divider(height: 24),
                      _buildDataField(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: garante?.email ?? 'N/A',
                      ),
                      const Divider(height: 24),
                      _buildDataField(
                        icon: Icons.location_on_outlined,
                        label: 'Regione',
                        value: garante?.regione ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Card(
                elevation: 2,
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Questa azione è irreversibile',
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Eliminando il tuo account perderai definitivamente tutti i tuoi dati e gli eventi creati.',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeleteConfirmation(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.delete_forever),
                          label: Text(
                            'Elimina Account',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.blueNcs.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppConstants.blueNcs,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.gray600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.gray800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'Elimina Account',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sei sicuro di voler eliminare il tuo account?',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATTENZIONE:',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Tutti i tuoi dati personali verranno cancellati\n'
                    '• Tutti gli eventi creati verranno eliminati\n'
                    '• Questa azione è IRREVERSIBILE\n'
                    '• Non potrai più accedere con questo account',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                color: AppConstants.gray600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Chiudi dialog di conferma

              // Mostra loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppConstants.blueNcs,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Eliminazione in corso...',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              // Esegui eliminazione
              final authService = AuthGarantiService();
              final result = await authService.eliminaAccount();

              if (!context.mounted) return;

              // Chiudi loading dialog
              Navigator.pop(context);

              if (result['success']) {
                // Successo - mostra messaggio e torna alla home
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Account eliminato con successo',
                      style: GoogleFonts.lato(),
                    ),
                    backgroundColor: AppConstants.green,
                    duration: const Duration(seconds: 3),
                  ),
                );

                // Torna alla home (il wrapper gestirà il redirect al login)
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                // Errore - mostra messaggio
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Errore durante l\'eliminazione',
                      style: GoogleFonts.lato(),
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'Elimina definitivamente',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
