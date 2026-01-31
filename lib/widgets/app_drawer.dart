// widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';
import '../screens/normative_screen.dart';
import '../screens/preferiti_screen.dart';
import '../screens/garanti_screen.dart';
import '../screens/casi_sentenze_screen.dart';
import '../screens/eventi_pubblici_screen.dart';
import '../screens/consulenze_screen.dart';
import '../screens/segnalazione_screen.dart';
import '../screens/garanti/area_garanti_wrapper.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header del drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: AppConstants.acidGreen,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppConstants.gray800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista voci del menu
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Normative',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NormativeScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bookmark_border,
                    title: 'Preferiti',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PreferitiScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Garanti',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GarantiScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.school_outlined,
                    title: 'Casi e Sentenze',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CasiSentenzeScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.event_outlined,
                    title: 'Eventi',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EventiPubbliciScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.headset_mic,
                    title: 'Consulenze Legali',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConsulenzeScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.warning_amber_rounded,
                    title: 'Segnalazione di pericolo',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SegnalazioneScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock_outlined,
                    title: 'Area Garanti',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AreaGarantiWrapper(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'P.An.D.A Lex 1.0.0',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.gray600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppConstants.gray600,
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.lato(
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppConstants.gray600,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}