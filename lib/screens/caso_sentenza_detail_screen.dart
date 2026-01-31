import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_constants.dart';
import '../models/caso_sentenza.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/emergency_scaffold.dart';

class CasoSentenzaDetailScreen extends StatefulWidget {
  final int casoId;
  
  const CasoSentenzaDetailScreen({
    Key? key,
    required this.casoId,
  }) : super(key: key);

  @override
  State<CasoSentenzaDetailScreen> createState() => _CasoSentenzaDetailScreenState();
}

class _CasoSentenzaDetailScreenState extends State<CasoSentenzaDetailScreen> {
  CasoSentenza? caso;
  bool isLoading = true;
  bool isLoadingPdf = false;
  String? pdfError;
  int _selectedIndex = 1;
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadCasoDetail();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadCasoDetail() async {
    try {
      setState(() => isLoading = true);
      
      final casoData = await _apiService.getCasoSentenzaDetail(widget.casoId);
      setState(() {
        caso = casoData;
      });
    } catch (error) {
      print('Errore nel recupero del caso/sentenza: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nel caricamento del caso/sentenza'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleDownloadPdf() async {
    if (caso?.pdf == null) return;

    setState(() {
      isLoadingPdf = true;
      pdfError = null;
    });

    try {
      final Uri pdfUri = Uri.parse(caso!.pdf!);
      
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
      setState(() => isLoadingPdf = false);
    }
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
      title: "Dettaglio Caso",
      showBackButton: true,
      selectedNavIndex: _selectedIndex,
      onNavItemTapped: _onItemTapped,
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
            child: isLoading
                ? _buildLoadingState()
                : caso == null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.blueNcs),
          ),
          SizedBox(height: 16),
          Text(
            'Caricamento...',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Dati non disponibili',
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Header con titolo e data
            _buildHeader(),
            
            // Contenuto dell'articolo
            _buildArticleContent(),
            
            // Pulsante download PDF
            if (caso!.hasPdf) _buildPdfDownloadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Immagine in evidenza
          if (caso!.hasImage)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                topRight: Radius.circular(AppConstants.borderRadiusLarge),
              ),
              child: Image.network(
                caso!.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox.shrink();
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              children: [
                // Data pubblicazione
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppConstants.blueNcs,
                    ),
                    SizedBox(width: 8),
                    Text(
                      caso!.date,
                      style: GoogleFonts.lato(
                        textStyle: AppConstants.bodyLarge.copyWith(
                          color: AppConstants.blueNcs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                // Separatore
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 1,
                  color: AppConstants.gray200,
                ),
                
                // Titolo
                Text(
                  caso!.decodedTitle,
                  style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
                  textAlign: TextAlign.center,
                ),

                if (caso!.excerpt != null && caso!.excerpt!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    caso!.decodedExcerpt,
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.gray800,
                      ),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Html(
        data: caso!.content ?? caso!.decodedExcerpt,
        style: {
          "body": Style(
            color: AppConstants.gray800,
            fontSize: FontSize(17),
            lineHeight: const LineHeight(1.6),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          "p": Style(
            margin: Margins.only(bottom: 16),
            textAlign: TextAlign.justify,
          ),
          "strong": Style(
            fontWeight: FontWeight.bold,
          ),
          "b": Style(
            fontWeight: FontWeight.bold,
          ),
          "a": Style(
            color: AppConstants.blueNcs,
            textDecoration: TextDecoration.underline,
          ),
          "ul": Style(
            margin: Margins.only(bottom: 8, left: 16),
          ),
          "ol": Style(
            margin: Margins.only(bottom: 8, left: 16),
          ),
          "li": Style(
            margin: Margins.only(bottom: 8),
          ),
          "h1": Style(
            fontSize: FontSize(24),
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 16, bottom: 8),
          ),
          "h2": Style(
            fontSize: FontSize(22),
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 16, bottom: 8),
          ),
          "h3": Style(
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 16, bottom: 8),
          ),
          "blockquote": Style(
            margin: Margins.only(left: 16, top: 8, bottom: 8),
            padding: HtmlPaddings.only(left: 16),
            border: Border(
              left: BorderSide(
                color: AppConstants.blueNcs,
                width: 4,
              ),
            ),
            backgroundColor: AppConstants.gray100,
          ),
        },
        onLinkTap: (url, attributes, element) {
          if (url != null) {
            _launchUrl(url);
          }
        },
      ),
    );
  }

  Widget _buildPdfDownloadButton() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoadingPdf ? null : _handleDownloadPdf,
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
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.blueNcs,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('Errore nell\'apertura del link: $e');
    }
  }

  @override
  void dispose() {
    // Ripristina la status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }
}