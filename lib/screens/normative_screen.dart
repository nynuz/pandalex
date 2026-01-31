import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';
import '../models/normativa.dart';
import '../models/active_filters.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/fuzzy_search_service.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/emergency_scaffold.dart';
import '../widgets/filter_modal.dart';
import '../widgets/search_snippet_text.dart';
import '../widgets/report_floating_button.dart';
import '../screens/normativa_detail_screen.dart';


class NormativeScreen extends StatefulWidget {
  final String? initialQuery;
  final List<Normativa>? preFilteredResults;
  
  const NormativeScreen({
    Key? key,
    this.initialQuery,
    this.preFilteredResults,
  }) : super(key: key);

  @override
  State<NormativeScreen> createState() => _NormativeScreenState();
}

class _NormativeScreenState extends State<NormativeScreen> {
  List<Normativa> allNormative = [];
  List<Normativa> searchResults = [];
  List<int> favorites = [];
  List<String> availableCategories = [];
  
  bool isLoading = true;
  bool isFilterModalVisible = false;
  bool _usingPreFilteredResults = false;
  bool isSearching = false;
  
  int visibleItemsCount = 10;
  final int itemsPerPage = 10;
  int _selectedIndex = 1;
  
  ActiveFilters activeFilters = ActiveFilters(categoria: []);
  String currentSearchQuery = '';
  
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();
  final FuzzySearchService _fuzzySearchService = FuzzySearchService(); // NUOVO SERVICE
  
  // Controller per il campo di ricerca
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // IMPOSTA LA QUERY INIZIALE NEL CONTROLLER
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      currentSearchQuery = widget.initialQuery!;
      _searchController.text = widget.initialQuery!; // ✅ AGGIUNGI QUESTA RIGA
    }
    
    _loadInitialData();
    
    // Se abbiamo risultati pre-filtrati dalla homepage
    if (widget.preFilteredResults != null && 
        widget.preFilteredResults!.isNotEmpty &&
        widget.initialQuery != null) {
      searchResults = widget.preFilteredResults!;
      _usingPreFilteredResults = true;
      print('✅ Usando ${searchResults.length} risultati pre-filtrati dalla homepage');
    } 
    // Altrimenti esegui ricerca normale se c'è una query
    else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      Future.delayed(Duration.zero, () {
        _handleSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => isLoading = true);
      
      final results = await Future.wait([
        _favoritesService.loadFavorites(),
        _apiService.getAllArticles(),
        _apiService.getArticleCategories(),
      ]);
      
      setState(() {
        favorites = results[0] as List<int>;
        allNormative = results[1] as List<Normativa>;
        availableCategories = results[2] as List<String>;

        // INDICIZZA LE NORMATIVE
        //_fuzzySearchService.indexNormative(allNormative);
      });
    } catch (error) {
      print('Errore nel caricamento dei dati iniziali: $error');
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

  // NUOVA IMPLEMENTAZIONE CON FUZZY SEARCH
  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults.clear();
        currentSearchQuery = '';
        _usingPreFilteredResults = false;
      });
      return;
    }

    // Se stiamo usando risultati pre-filtrati e la query è la stessa, non rifare la ricerca
    if (_usingPreFilteredResults && query == currentSearchQuery) {
      print('ℹ️ Usando risultati già filtrati');
      return;
    }

    setState(() {
      isSearching = true; // ✅ MOSTRA LOADING
    });

    // ✅ ESEGUI LA RICERCA IN MODO ASINCRONO
    await Future.delayed(const Duration(milliseconds: 300)); // Tempo minimo per vedere il loading
    
    final results = await Future(() {
      return _fuzzySearchService.searchNormativeAdvanced(query, allNormative);
    });

    setState(() {
      currentSearchQuery = query;
      searchResults = results;
      isSearching = false; // ✅ NASCONDI LOADING
    });
  }

  void _clearSearch() {
    setState(() {
      searchResults.clear();
      currentSearchQuery = '';
      visibleItemsCount = itemsPerPage;
      _usingPreFilteredResults = false;
      _searchController.clear();
    });
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
        builder: (context) => NormativaDetailScreen(
          articleId: articleId,
          searchQuery: _searchController.text
        ),
      ),
    );
  }

  void _loadMoreItems() {
    setState(() {
      visibleItemsCount += itemsPerPage;
    });
  }

  void _resetAllFilters() {
    _clearSearch();
    setState(() {
      activeFilters = ActiveFilters(categoria: []);
      visibleItemsCount = itemsPerPage;
    });
  }

  void _applyFilters(ActiveFilters filters) {
    setState(() {
      activeFilters = filters;
    });
  }

  List<Normativa> get filteredList {
    // Se c'è una ricerca attiva ma nessun risultato, ritorna lista vuota
    if (currentSearchQuery.isNotEmpty && searchResults.isEmpty) {
      return [];
    }
    
    // Se c'è una ricerca attiva con risultati, usa solo quelli
    List<Normativa> list = searchResults.isNotEmpty 
        ? searchResults
        : allNormative;
    
    // Applica filtri di categoria
    if (activeFilters.categoria.isNotEmpty) {
      list = list.where((item) => 
          activeFilters.categoria.contains(item.categoria)).toList();
    }

    return list;
  }

  bool get isAnyFilterActive => 
      searchResults.isNotEmpty || activeFilters.totalCount > 0;

  List<Normativa> get visibleList {
    return isAnyFilterActive 
        ? filteredList 
        : filteredList.take(visibleItemsCount).toList();
  }

  bool get hasMoreItems => 
      visibleItemsCount < filteredList.length && !isAnyFilterActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        EmergencyScaffold(
          title: "Lista Normative",
          showBackButton: true,
          selectedNavIndex: _selectedIndex,
          onNavItemTapped: _onItemTapped,
          floatingActionButton: const ReportFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: BackgroundWrapper(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 0),
                        _buildHeader(),
                        _buildContent(),
                        if (hasMoreItems && !isLoading)
                          _buildLoadMoreButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
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

  Widget _buildHeader() {
    _searchController.addListener(() {
      setState(() {}); // Ricostruisce per mostrare/nascondere il pulsante X
    });
    
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          Text(
            'Cerca o filtra tra tutte le normative.',
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                fontWeight: FontWeight.w400, 
                fontSize: 16,
                color: AppConstants.gray600
              )
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.paddingMedium),
          
          // NUOVA BARRA DI RICERCA INTEGRATA
          Row(
            children: [
              Expanded(
                child: _buildSearchBar(),
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
          
          if (isAnyFilterActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: _resetAllFilters,
                child: Text(
                  'Rimuovi tutti i filtri',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: AppConstants.blueNcs,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // NUOVO WIDGET BARRA DI RICERCA
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppConstants.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              //onChanged: _handleSearch, // Ricerca in tempo reale
              onSubmitted: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Cerca normative...',
                hintStyle: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.gray800,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.clear,
                  color: AppConstants.gray400,
                  size: 20,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.all(4),
            child: ElevatedButton(
              onPressed: isSearching ? null : () => _handleSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.blueNcs,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: const CircleBorder(),
                minimumSize: const Size(44, 44),
                disabledBackgroundColor: AppConstants.blueNcs.withOpacity(0.7), // ✅ COLORE QUANDO DISABILITATO
              ),
              child: isSearching // ✅ MOSTRA LOADING O ICONA
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.search,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.blueNcs),
          ),
        ),
      );
    }

    if (visibleList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppConstants.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              currentSearchQuery.isEmpty 
                  ? 'Nessuna normativa trovata.' 
                  : 'Nessun risultato per "$currentSearchQuery"',
              style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
              textAlign: TextAlign.center,
            ),
            if (currentSearchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Prova con termini diversi o rimuovi i filtri',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.gray500,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        if (filteredList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filteredList.length} ${filteredList.length == 1 ? 'normativa trovata' : 'normative trovate'}',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600, 
                    fontSize: 18,
                    color: AppConstants.gray800
                  )
                ),
              ),
            ),
          ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          child: Column(
            children: visibleList.map((normativa) => _buildNormativaCard(normativa)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNormativaCard(Normativa normativa) {
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
          
          GestureDetector(
            onTap: () => _navigateToNormDetail(normativa.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 32, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    normativa.decodedTitle,
                    style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  Text(
                    normativa.typeDoc.toUpperCase() + (normativa.numDoc != null ? ' N. ${normativa.numDoc}' : ''),
                    style: GoogleFonts.montserrat(textStyle: AppConstants.cardSubtitle),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    normativa.date,
                    style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
                  ),

                  if (normativa.searchSnippet != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SearchSnippetText(
                        snippet: normativa.searchSnippet!,
                        highlightPositions: normativa.highlightPositions,
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

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          GestureDetector(
            onTap: _loadMoreItems,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppConstants.blueNcs,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Carica di più',
            style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
          ),
        ],
      ),
    );
  }
}