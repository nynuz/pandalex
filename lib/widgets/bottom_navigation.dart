import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';
import '../screens/normative_screen.dart';
import '../screens/garanti_screen.dart';
import '../screens/casi_sentenze_screen.dart';
import '../screens/eventi_pubblici_screen.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigationWidget({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se selectedIndex è -1, non mostrare nessuna selezione
    final int? displayIndex = selectedIndex == -1 ? null : selectedIndex;

    return BottomNavigationBar(
      currentIndex: displayIndex ?? 0, // Usa 0 come fallback per evitare l'errore
      onTap: (index) => _handleTap(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppConstants.white,
      selectedItemColor: selectedIndex == -1 ? AppConstants.gray400 : AppConstants.blueNcs, // Tutti grigi se nessuna selezione
      unselectedItemColor: AppConstants.gray400,
      selectedLabelStyle: GoogleFonts.lato(textStyle: AppConstants.footerMenu),
      unselectedLabelStyle: GoogleFonts.lato(textStyle: AppConstants.footerMenu),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          label: 'Normative',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_outlined),
          label: 'Garanti',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          label: 'Eventi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          label: 'Sentenze',
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, int index) {
    // Per la tab Home (index 0), torna alla schermata precedente se non siamo già in Home
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      onItemTapped(index);
      return;
    }

    // Per la tab Normative (index 1), naviga alla schermata Normative
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NormativeScreen()),
      ).then((_) => onItemTapped(0)); // Quando torna indietro, resetta la selezione su Home (index 0)
      return;
    }
    
    // Per la tab Garanti (index 2), naviga alla schermata Garanti
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GarantiScreen()),
      ).then((_) => onItemTapped(0)); // Quando torna indietro, resetta la selezione su Home (index 0)
      return;
    }

    // Per la tab Eventi (index 3), naviga alla schermata Eventi
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EventiPubbliciScreen()),
      ).then((_) => onItemTapped(0)); // Quando torna indietro, resetta la selezione su Home (index 0)
      return;
    }

    // Per la tab Casi (index 4), naviga alla schermata Casi e Sentenze
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CasiSentenzeScreen()),
      ).then((_) => onItemTapped(0)); // Quando torna indietro, resetta la selezione su Home (index 0)
      return;
    }
    
    // Per le altre tab, aggiorna l'indice (per ora non hanno navigazione)
    onItemTapped(index);
  }
}