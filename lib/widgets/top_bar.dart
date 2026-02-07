// widgets/top_bar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';
import 'emergency_banner.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showEmergencyBanner;
  
  const TopBar({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.showEmergencyBanner = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isHomePage = title == 'Homepage';

    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: AppConstants.acidGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFCBD5E1),
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: kToolbarHeight,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Stack(
                children: [
                  // Freccia back
                  if (showBackButton && !isHomePage)
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '←',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: AppConstants.gray800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Titolo centrato
                  Center(
                    child: Text(
                      title,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, 
                          fontSize: 18,
                          color: AppConstants.gray800
                        )
                      ),
                    ),
                  ),
                  
                  // Hamburger menu posizionato a destra
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => Scaffold.of(context).openEndDrawer(),
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.menu,
                          size: 28,
                          color: AppConstants.gray800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Emergency Banner (se richiesto)
          if (showEmergencyBanner)
            const EmergencyBanner(),
        ],
      ),
    );
  }

  @override
  Size get preferredSize {
    final double height = kToolbarHeight + 56 + (showEmergencyBanner ? 40 : 0);
    return Size.fromHeight(height);
  }
}
