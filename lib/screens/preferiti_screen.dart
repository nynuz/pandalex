import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../app_constants.dart';
import '../models/normativa.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/emergency_scaffold.dart';
import '../widgets/report_floating_button.dart';
import '../screens/normativa_detail_screen.dart';

class PreferitiScreen extends StatefulWidget {
  const PreferitiScreen({Key? key}) : super(key: key);

  @override
  State<PreferitiScreen> createState() => _PreferitiScreenState();
}

class _PreferitiScreenState extends State<PreferitiScreen> {
  List<Normativa> allArticles = [];
  List<int> favoriteIDs = [];
  bool isLoading = true;
  int _selectedIndex = 2; // Index 2 per la tab "Preferiti"
  
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      
      // Carica gli ID dei preferiti
      final savedFavorites = await _favoritesService.loadFavorites();
      setState(() {
        favoriteIDs = savedFavorites;
      });

      // Carica tutti gli articoli solo se non già caricati
      if (allArticles.isEmpty) {
        final articles = await _apiService.getAllArticles();
        setState(() {
          allArticles = articles;
        });
      }
    } catch (error) {
      print('Errore nel caricamento dei dati: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nel caricamento dei preferiti'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFavorite(int articleId) async {
    try {
      final updatedFavorites = favoriteIDs.where((id) => id != articleId).toList();
      setState(() {
        favoriteIDs = updatedFavorites;
      });
      await _favoritesService.saveFavorites(updatedFavorites);
    } catch (e) {
      print('Errore nella rimozione del preferito: $e');
    }
  }

  void _navigateToNormDetail(int articleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NormativaDetailScreen(articleId: articleId),
      ),
    );
  }

  // Filtra gli articoli per mostrare solo i preferiti
  List<Normativa> get favoriteArticles {
    return allArticles.where((article) => favoriteIDs.contains(article.id)).toList();
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
      title: "Preferiti",
      showBackButton: true,
      selectedNavIndex: _selectedIndex,
      onNavItemTapped: _onItemTapped,
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
              padding: const EdgeInsets.only(top: 60, bottom: 0),
              child: isLoading
                  ? _buildLoadingState()
                  : favoriteArticles.isNotEmpty
                      ? _buildFavoritesList()
                      : _buildEmptyState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.blueNcs),
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: favoriteArticles.map((article) => _buildFavoriteCard(article)).toList(),
      ),
    );
  }

  Widget _buildFavoriteCard(Normativa article) {
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
          // Pulsante rimozione preferito
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _toggleFavorite(article.id),
              child: Container(
                padding: const EdgeInsets.all(0),
                child: const Icon(
                  Icons.bookmark,
                  size: 24,
                  color: Color(0xFFFFC700), // Colore giallo come nel React Native
                ),
              ),
            ),
          ),
          
          // Contenuto della card
          GestureDetector(
            onTap: () => _navigateToNormDetail(article.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 32, 16), // Margine per il bookmark
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
                  Text(
                    article.decodedTitle,
                    style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  // Tipo documento
                  Text(
                    article.typeDoc.toUpperCase() + (article.numDoc != null ? ' N. ${article.numDoc}' : ''),
                    style: GoogleFonts.montserrat(textStyle: AppConstants.cardSubtitle),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Data
                  Text(
                    article.date,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 60,
            color: AppConstants.gray400,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Tocca l\'icona a forma di segnalibro su una normativa per aggiungerla qui.',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}