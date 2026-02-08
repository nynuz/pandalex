import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';
import '../models/normativa.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/emergency_scaffold.dart';
import '../widgets/report_floating_button.dart';
import '../screens/normative_screen.dart';
import '../screens/normativa_detail_screen.dart';

class NormativeInEvidenzaScreen extends StatefulWidget {
  const NormativeInEvidenzaScreen({Key? key}) : super(key: key);

  @override
  State<NormativeInEvidenzaScreen> createState() => _NormativeInEvidenzaScreenState();
}

class _NormativeInEvidenzaScreenState extends State<NormativeInEvidenzaScreen> {
  List<Normativa> topNormative = [];
  List<int> favorites = [];
  bool isLoading = true;
  
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      
      // Carica preferiti e normative in parallelo
      final results = await Future.wait([
        _favoritesService.loadFavorites(),
        _apiService.getNormativeInEvidenza(),
      ]);
      
      setState(() {
        favorites = results[0] as List<int>;
        topNormative = results[1] as List<Normativa>;
      });
    } catch (e) {
      print('Errore nel caricamento delle normative in evidenza: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nel caricamento dei dati'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFavorite(int articleId) async {
    try {
      final updatedFavorites = await _favoritesService.toggleFavorite(articleId, favorites);
      setState(() {
        favorites = updatedFavorites;
      });
    } catch (e) {
      print('Errore nel salvataggio del preferito: $e');
    }
  }

  bool _isFavorite(int articleId) {
    return _favoritesService.isFavorite(articleId, favorites);
  }

  void _navigateToNormDetail(int articleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NormativaDetailScreen(articleId: articleId),
      ),
    );
  }

  void _navigateToAllNormative() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NormativeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configura la status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppConstants.blueNcs.withOpacity(0.8),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return EmergencyScaffold(
      title: "⭐ Normative",
      showBackButton: true,
      selectedNavIndex: -1,
      onNavItemTapped: (_) {},
      floatingActionButton: const ReportFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BackgroundWrapper(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         kToolbarHeight - 
                         kBottomNavigationBarHeight - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Column(
                children: [
                  const SizedBox(height: 0),
                  // Header con descrizione
                  _buildHeader(),
                  
                  // Lista delle normative
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.blueNcs),
                        ),
                      ),
                    )
                  else if (topNormative.isEmpty)
                    _buildEmptyState()
                  else
                    _buildNormativeList(),
                  
                  // Link all'archivio completo
                  if (!isLoading && topNormative.isNotEmpty)
                    _buildArchiveLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB), // amber-50 equivalent
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: const Border(
            left: BorderSide(color: AppConstants.amber500, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: AppConstants.amber500,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded( // Aggiungi Expanded qui
                  child: Text(
                    'Normative Fondamentali',
                    style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Questa raccolta presenta le normative più importanti e fondamentali per la tutela degli animali in Italia. Queste leggi costituiscono la base del sistema di protezione animale nel nostro Paese.',
              style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingLarge * 2),
      decoration: BoxDecoration(
        color: AppConstants.gray200.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: AppConstants.gray400,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Nessuna normativa in evidenza disponibile al momento.',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNormativeList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: Column(
        children: topNormative.asMap().entries.map((entry) {
          final index = entry.key;
          final normativa = entry.value;
          return _buildNormativeCard(normativa, index + 1);
        }).toList(),
      ),
    );
  }

  Widget _buildNormativeCard(Normativa normativa, int position) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.white,
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
          // Badge numerato
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppConstants.amber500,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  position.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          // Pulsante preferiti
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _toggleFavorite(normativa.id),
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Icon(
                  _isFavorite(normativa.id) ? Icons.bookmark : Icons.bookmark_border,
                  size: 24,
                  color: _isFavorite(normativa.id) ? AppConstants.amber500 : AppConstants.gray400,
                ),
              ),
            ),
          ),
          
          // Contenuto della card
          GestureDetector(
            onTap: () => _navigateToNormDetail(normativa.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 16, 32, 16), // Margini per badge e bookmark
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
                  Text(
                    normativa.decodedTitle,
                    style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  // Tipo documento
                  Text(
                    normativa.typeDoc.toUpperCase() + (normativa.numDoc != null ? ' N. ${normativa.numDoc}' : ''),
                    style: GoogleFonts.montserrat(textStyle: AppConstants.cardSubtitle),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Data
                  Text(
                    normativa.date,
                    style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveLink() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: GestureDetector(
        onTap: _navigateToAllNormative,
        child: Text(
          'Cerca altre normative nell\'archivio completo',
          style: GoogleFonts.lato(textStyle: AppConstants.link),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}