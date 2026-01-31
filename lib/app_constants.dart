import 'package:flutter/material.dart';

class AppConstants {
  // Colori principali
  static const Color blueNcs = Color(0xFF086FBC);
  static const Color azul = Color(0xFF086FBC);
  static const Color ciano = Color(0xFF00BCD4);
  static const Color acidGreen = Color(0xFF0bf34f); // Per la TopBar
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color purple500 = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeDark = Color(0xFFEA580C);
  static const Color green = Color(0xFF10B981);
  static const Color greenDark = Color(0xFF059669);
  static const Color yellow400 = Color(0xFFFBBF24);
  
  // Colori di base
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6);
  
  // Text Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: gray800,
    height: 1,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: gray500,
    height: 1.2,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: gray600,
  );

  static const TextStyle textSnippet = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: gray600,
  );
  
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: azul,
  );
  
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: gray500,
  );

  static const TextStyle link = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: blueNcs,
    //decoration: TextDecoration.underline,
  );

  static const TextStyle footerMenu = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  
  // Padding e Margini standard
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
}