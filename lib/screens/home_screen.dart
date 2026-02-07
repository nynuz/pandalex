import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';
import '../models/normativa.dart';
import '../services/api_service.dart';
import '../services/fuzzy_search_service.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/emergency_scaffold.dart';
import '../widgets/report_floating_button.dart';
import '../screens/garanti_screen.dart';
import '../screens/casi_sentenze_screen.dart';
import '../screens/segnalazione_screen.dart';
import '../screens/guida_emergenza_screen.dart';
import '../screens/normative_in_evidenza_screen.dart';
import '../screens/normative_screen.dart';
import '../screens/consulenze_screen.dart';
import '../screens/eventi_pubblici_screen.dart';
import '../widgets/filter_modal.dart';
import '../models/active_filters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FuzzySearchService _fuzzySearch = FuzzySearchService();
  List<Normativa> allNormative = [];
  bool isIndexed = false;
  bool isFilterModalVisible = false;
  ActiveFilters activeFilters = ActiveFilters(categoria: []);
  List<String> availableCategories = [];
  
  // Gestione della selezione del BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _handleHomeSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // Se l'indice non è pronto, fallback su ricerca API
    if (!isIndexed || allNormative.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NormativeScreen(initialQuery: query),
        ),
      );
      return;
    }
    
    // Usa il motore fuzzy per cercare localmente
    final results = _fuzzySearch.searchNormativeAdvanced(query, allNormative);
    
    print('🔍 Ricerca homepage: "${query}" → ${results.length} risultati');
    
    // Naviga alla schermata Normative con i risultati pre-filtrati e i filtri attivi
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NormativeScreen(
          initialQuery: query,
          preFilteredResults: results, // Passa i risultati già filtrati
          initialFilters: activeFilters.totalCount > 0 ? activeFilters : null,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAndIndexNormative();
  }

  Future<void> _loadAndIndexNormative() async {
    try {
      // Carica tutte le normative e le categorie
      final normative = await ApiService().getAllArticles();
      final categories = await ApiService().getArticleCategories();

      // Indicizza per la ricerca fuzzy
      //_fuzzySearch.indexNormative(normative);

      setState(() {
        allNormative = normative;
        availableCategories = categories;
        isIndexed = true;
      });

      print('✅ Homepage pronta con ${normative.length} normative indicizzate');
    } catch (e) {
      print('❌ Errore caricamento normative per ricerca: $e');
    }
  }

  void _applyFilters(ActiveFilters filters) {
    setState(() {
      activeFilters = filters;
    });
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

    return Stack(
      children: [
        EmergencyScaffold(
      title: "Homepage",
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
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  const SizedBox(height: 0),
                  _buildMainTitleCard(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildCentralImage(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildSearchBar(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildNormativeCard(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildCasiSentenzeCard(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildGarantiCard(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildEventiPubbliciCard(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildConsulenzeLegaliCard(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildSegnalazioneCard(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildEmergenzaCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
        ),

        FilterModal(
          visible: isFilterModalVisible,
          onClose: () => setState(() => isFilterModalVisible = false),
          onApply: _applyFilters,
          initialFilters: activeFilters,
          categorie: availableCategories,
        ),
      ],
    );
  }

  Widget _buildMainTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppConstants.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titolo principale
          Column(
            children: [
              Text(
                'P.An.D.A',
                style: GoogleFonts.gupter(textStyle: AppConstants.titleLarge),
                textAlign: TextAlign.center,
              ),
              Text(
                'Lex',
                style: GoogleFonts.gupter(textStyle: AppConstants.titleLarge),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.paddingSmall),
          
          // Sottotitolo
          Text(
            'Guida alle',
            style: GoogleFonts.montserrat(textStyle: AppConstants.titleMedium),
            textAlign: TextAlign.center,
          ),
          Text(
            'normative',
            style: GoogleFonts.montserrat(textStyle: AppConstants.titleMedium),
            textAlign: TextAlign.center,
          ),
          Text(
            'per la Tutela',
            style: GoogleFonts.montserrat(textStyle: AppConstants.titleMedium),
            textAlign: TextAlign.center,
          ),
          Text(
            'degli Animali',
            style: GoogleFonts.montserrat(textStyle: AppConstants.titleMedium),
            textAlign: TextAlign.center,
          ),
          
          // Separatore
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
            height: 1,
            color: AppConstants.gray200,
          ),
          
          // Messaggio di benvenuto
          Text(
            'Consulta le normative',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
            textAlign: TextAlign.center,
          ),
          Text(
            'IN EVIDENZA',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
            textAlign: TextAlign.center,
          ),
          Text(
            'o usa la ricerca per trovare',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
            textAlign: TextAlign.center,
          ),
          Text(
            'una specifica Legge',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCentralImage() {
    return Container(
      width: 300,
      height: 350,
      child: Image.asset(
        'assets/images/home.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: custom.SearchBar(
              onSearch: _handleHomeSearch,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => isFilterModalVisible = true),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.gray200,
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Icon(
                    Icons.tune,
                    color: AppConstants.gray700,
                    size: 24,
                  ),
                  if (activeFilters.totalCount > 0)
                    Positioned(
                      right: 0,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppConstants.orangeDark,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          activeFilters.totalCount.toString(),
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: AppConstants.white
                            )
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormativeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NormativeInEvidenzaScreen()),
          );
        },
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.amber500.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: AppConstants.amber500,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NORMATIVE IN EVIDENZA',
                        style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scopri le leggi più importanti per la tutela degli animali',
                        style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.gray400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsulenzeLegaliCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConsulenzeScreen()),
          );
        },
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic,
                      color: AppConstants.green,
                      size: 28,
                    ),
                  ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONSULENZE LEGALI di "La Legge per Tutti"',
                        style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vuoi saperne di più su regolamenti e norme? Vuoi consultare un professionista?', 
                        style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.gray400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegnalazioneCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SegnalazioneScreen()),
          );
        },
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icona e titolo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppConstants.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Text(
                        'SEGNALAZIONE DI PERICOLO',
                        style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppConstants.gray400,
                      size: 24,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Testo introduttivo
                Text(
                  'Invia alla community Panda Lex una segnalazione di pericolo con foto e descrizione:',
                  style: GoogleFonts.lato(
                    textStyle: AppConstants.cardSubtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Elenco pericoli (primi 3 visibili)
                Text(
                  'Per esempio, sospetta zona con:\n'
                  '- sostanze tossiche/bocconi avvelenati\n'
                  '- trappole o tagliole illegali\n'
                  '- furti o sparizione di animali\n'
                  '- zona con bracconaggio\n'
                  '- incendi recenti o in corso\n'
                  '- corsi d\'acqua contaminati\n'
                  '- alta incidenza di investimenti di fauna selvatica',
                  style: GoogleFonts.lato(
                    textStyle: AppConstants.cardSubtitle.copyWith(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCasiSentenzeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CasiSentenzeScreen()),
          );
        },
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.purple500.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.library_books,
                    color: AppConstants.purple500,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CASI E SENTENZE',
                        style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Documenti e sentenze con PDF scaricabili per casi di studio pratici',
                        style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.gray400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventiPubbliciCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventiPubbliciScreen()),
          );
        },
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.ciano.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_outlined,
                    color: AppConstants.ciano,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EVENTI',
                        style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vedi gli EVENTI promossi dai GARANTI in favore degli animali',
                        style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.gray400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGarantiCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GarantiScreen()),
          );
        },
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.blueNcs.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: AppConstants.blueNcs,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I GARANTI per la Tutela degli Animali sul territorio',
                        style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cerca e rivolgiti al Garante per segnalare inadempienze, ritardi o omissioni delle Amministrazioni e degli Enti preposti alla Tutela degli Animali e alla Vigilanza sul loro Benessere.',
                        style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.gray400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergenzaCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GuidaEmergenzaScreen()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            gradient: const LinearGradient(
              colors: [AppConstants.orange, AppConstants.orangeDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.orange.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENZA?',
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'Scopri cosa fare subito.',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}