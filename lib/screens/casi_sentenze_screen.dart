import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';
import '../models/caso_sentenza.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/emergency_scaffold.dart';
import '../widgets/report_floating_button.dart';
import 'caso_sentenza_detail_screen.dart';

class CasiSentenzeScreen extends StatefulWidget {
  const CasiSentenzeScreen({Key? key}) : super(key: key);

  @override
  State<CasiSentenzeScreen> createState() => _CasiSentenzeScreenState();
}

class _CasiSentenzeScreenState extends State<CasiSentenzeScreen> {
  List<CasoSentenza> allCasi = [];
  bool isLoading = true;
  bool isLoadingPdf = false;
  String? pdfError;
  int visibleItemsCount = 10;
  final int itemsPerPage = 10;
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  int _selectedIndex = 4; // Index 4 per la tab "Casi"
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCasiSentenze();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCasiSentenze() async {
    try {
      final casi = await _apiService.getCasiSentenze();
      setState(() {
        allCasi = casi;
        isLoading = false;
      });
    } catch (e) {
      print('Errore nel caricamento dei casi: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleDownloadPdf(String pdfUrl) async {
    setState(() {
      isLoadingPdf = true;
      pdfError = null;
    });

    try {
      final Uri pdfUri = Uri.parse(pdfUrl);
      
      if (await canLaunchUrl(pdfUri)) {
        await launchUrl(
          pdfUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        setState(() {
          pdfError = 'Impossibile aprire il PDF';
        });
      }
    } catch (e) {
      setState(() {
        pdfError = 'Errore durante il download del PDF';
      });
    } finally {
      setState(() {
        isLoadingPdf = false;
      });
    }
  }

  Future<void> _handleReadArticle(String articleUrl) async {
    try {
      final Uri articleUri = Uri.parse(articleUrl);
      
      if (await canLaunchUrl(articleUri)) {
        await launchUrl(
          articleUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile aprire l\'articolo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante l\'apertura dell\'articolo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString; // Ritorna la stringa originale se il parsing fallisce
    }
  }

  void _loadMoreItems() {
    setState(() {
      visibleItemsCount += itemsPerPage;
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
    return EmergencyScaffold(
      title: "Sentenze",
      showBackButton: true,
      selectedNavIndex: _selectedIndex,
      onNavItemTapped: _onItemTapped,
      floatingActionButton: const ReportFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BackgroundWrapper(
        child: SingleChildScrollView(
          //controller: _scrollController,
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
                  
                  // Lista degli articoli
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.blueNcs),
                        ),
                      ),
                    )
                  else if (allCasi.isEmpty)
                    _buildEmptyState()
                  else
                    _buildArticlesList(),
                  
                  // Pulsante Carica di più
                  if (visibleItemsCount < allCasi.length && !isLoading)
                    _buildLoadMoreButton(),
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
          color: const Color(0xFFEBF8FF), // blue-50 equivalent
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: const Border(
            left: BorderSide(color: AppConstants.blueNcs, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_books,
                  color: AppConstants.blueNcs,
                  size: 24,
                ),
                SizedBox(width: AppConstants.paddingSmall),
                Text(
                  'Casi e Sentenze',
                  style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Raccolta di casi pratici e sentenze significative nel campo della tutela degli animali. Documenti e analisi per comprendere l\'applicazione pratica delle normative.',
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
            'Nessun caso o sentenza disponibile al momento.',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesList() {
    final visibleCasi = allCasi.take(visibleItemsCount).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: Column(
        children: visibleCasi.map((caso) => _buildArticleCard(caso)).toList(),
      ),
    );
  }

  Widget _buildArticleCard(CasoSentenza caso) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingLarge * 2),
      decoration: BoxDecoration(
        color: AppConstants.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Immagine in evidenza
          if (caso.hasImage) _buildArticleImage(caso),
          
          // Contenuto
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titolo
                Text(
                  caso.decodedTitle,
                  style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: AppConstants.paddingSmall),
                
                // Data
                Text(
                  'Pubblicato il ${_formatDate(caso.date)}',
                  style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
                ),
                
                const SizedBox(height: AppConstants.paddingMedium),

                // Estratto
                if (caso.excerpt != null && caso.excerpt!.isNotEmpty)
                  Text(
                    caso.decodedExcerpt,
                    style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
                  ),

                const SizedBox(height: AppConstants.paddingMedium),
                
                // Pulsanti azione
                _buildActionButtons(caso),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleImage(CasoSentenza caso) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.gray200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.borderRadiusMedium),
          topRight: Radius.circular(AppConstants.borderRadiusMedium),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.borderRadiusMedium),
          topRight: Radius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Image.network(
          caso.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppConstants.gray200,
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: AppConstants.gray400,
                  size: 48,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppConstants.gray200,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.blueNcs),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(CasoSentenza caso) {
    return Column(
      children: [
        // Pulsante Leggi Articolo
        if (caso.hasBlogUrl)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CasoSentenzaDetailScreen(
                      casoId: caso.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_browser, size: 22),
              label: Text(
                'Leggi l\'articolo',
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.blueNcs,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
              ),
            ),
          ),
        
        const SizedBox(height: AppConstants.paddingSmall),
        
        // Pulsante Scarica PDF
        if (caso.hasPdf)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoadingPdf 
                ? null 
                : () => _handleDownloadPdf(caso.pdf!),
              icon: isLoadingPdf 
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download, size: 22),
              label: Text(
                isLoadingPdf ? 'Download...' : 'Scarica PDF',
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
              ),
            ),
          ),
        
        // Messaggio di errore PDF
        if (pdfError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.paddingSmall),
            child: Text(
              pdfError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
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