import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_constants.dart';
import '../models/normativa.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/emergency_scaffold.dart';

class NormativaDetailScreen extends StatefulWidget {
  final int articleId;
  final String? searchQuery;
  
  const NormativaDetailScreen({
    Key? key,
    required this.articleId,
    this.searchQuery
  }) : super(key: key);

  @override
  State<NormativaDetailScreen> createState() => _NormativaDetailScreenState();
}

class _NormativaDetailScreenState extends State<NormativaDetailScreen> {
  Normativa? article;
  bool isLoading = true;
  bool isLoadingPdf = false;
  String? pdfError;
  int _selectedIndex = 1;
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadArticleDetail();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadArticleDetail() async {
    try {
      setState(() => isLoading = true);
      
      final articleData = await _apiService.getArticleDetail(widget.articleId);
      setState(() {
        article = articleData;
      });
    } catch (error) {
      print('Errore nel recupero della normativa: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nel caricamento della normativa'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleDownloadPdf() async {
    if (article?.pdf == null) return;

    setState(() {
      isLoadingPdf = true;
      pdfError = null;
    });

    try {
      final Uri pdfUri = Uri.parse(article!.pdf!);
      
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
      title: "Dettaglio Normativa",
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
                : article == null
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
            // Header della normativa
            _buildHeader(),
            
            // Contenuto HTML
            _buildHtmlContent(),
            
            // Pulsante download PDF
            if (article!.hasPdf) _buildPdfDownloadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
          // Tipo documento
          Text(
            article!.typeDoc.toUpperCase() + (article!.numDoc != null ? ' N. ${article!.numDoc}' : ''),
            style: GoogleFonts.montserrat(textStyle: AppConstants.cardSubtitle),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          // Data
          Text(
            article!.date,
            style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
            textAlign: TextAlign.center,
          ),
          
          // Separatore
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 1,
            color: AppConstants.gray200,
          ),
          
          // Titolo
          Text(
            article!.decodedTitle,
            style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
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
        data: _highlightSearchQuery(article!.decodedContent),
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
            textAlign: TextAlign.left,
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
            margin: Margins.only(bottom: 8),
          ),
          "ol": Style(
            margin: Margins.only(bottom: 8),
          ),
          "li": Style(
            margin: Margins.only(bottom: 8),
          ),
          ".text-center": Style(
            textAlign: TextAlign.center,
          ),
          ".text-left": Style(
            textAlign: TextAlign.left,
          ),
          ".text-right": Style(
            textAlign: TextAlign.right,
          ),
          ".text-note": Style(
            fontSize: FontSize(15),
            color: const Color(0xFF990000),
            fontStyle: FontStyle.italic,
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

  /// Evidenzia la query di ricerca nel contenuto HTML
  String _highlightSearchQuery(String htmlContent) {
    if (widget.searchQuery == null || widget.searchQuery!.trim().isEmpty) {
      return htmlContent;
    }

    String content = htmlContent;
    final query = widget.searchQuery!.trim();
    
    // Evidenzia SOLO la query completa (non i singoli token)
    // Crea un pattern case-insensitive che non tocchi i tag HTML
    final pattern = RegExp(
      '(?<![<>])\\b($query)\\b(?![^<]*>)',
      caseSensitive: false,
    );
    
    content = content.replaceAllMapped(pattern, (match) {
      return '<span style="background-color: #0bf34f; font-weight: bold; color: black;">${match.group(0)}</span>';
    });
    
    return content;
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
              )
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