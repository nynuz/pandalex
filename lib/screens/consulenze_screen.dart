import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_constants.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/emergency_scaffold.dart';
import '../widgets/report_floating_button.dart';

class ConsulenzeScreen extends StatefulWidget {
  const ConsulenzeScreen({Key? key}) : super(key: key);

  @override
  State<ConsulenzeScreen> createState() => _ConsulenzeScreenState();
}

class _ConsulenzeScreenState extends State<ConsulenzeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showQuestionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionModalWidget(
        onSuccess: () => _showSuccessMessage(),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Domanda inviata con successo!',
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AppConstants.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDisclaimerDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Attenzione',
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.gray800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              'Il link rimanda a sito esterno che può offrire servizi a pagamento. Si precisa che l\'Associazione non ha rapporti economici e non riceve alcun compenso o guadagno dall\'uso dei servizi esterni. I link sono forniti a solo scopo informativo. L\'Associazione non è responsabile per i contenuti o per le condizioni dei servizi offerti da terzi.',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 15,
                  color: AppConstants.gray700,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Chiudi',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.gray600,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchConsulenzaUrl();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.blueNcs,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
              child: Text(
                'Procedi',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchConsulenzaUrl() async {
    final Uri url = Uri.parse('https://consulenze.laleggepertutti.it/consulenza?panda');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorMessage('Impossibile aprire il link');
      }
    } catch (e) {
      _showErrorMessage('Errore nell\'apertura del link');
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
      title: "Consulenza Legali",
      showBackButton: true,
      selectedNavIndex: _selectedIndex,
      onNavItemTapped: _onItemTapped,
      floatingActionButton: const ReportFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BackgroundWrapper(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                const SizedBox(height: 0),
                
                // Header con descrizione
                _buildHeader(),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Card 1 - Consulta P.An.D.A Lex
                _buildPandaLexCard(),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Card 2 - Consulta un Professionista
                _buildProfessionistaCard(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                Icons.headset_mic_outlined,
                color: AppConstants.blueNcs,
                size: 24,
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Text(
                'Consulenze Legali',
                style: GoogleFonts.montserrat(textStyle: AppConstants.cardTitle),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Hai bisogno di aiuto? Scegli il tipo di consulenza più adatto alle tue esigenze.',
            style: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildPandaLexCard() {
    return GestureDetector(
      onTap: () {
        _showQuestionModal();
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Icona e titolo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.blueNcs.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: AppConstants.blueNcs,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VUOI SAPERNE DI PIÙ SU',
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: AppConstants.gray600,
                            ),
                          ),
                        ),
                        Text(
                          'REGOLAMENTI E NORME?',
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppConstants.gray800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Call to action
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.blueNcs.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  border: Border.all(color: AppConstants.blueNcs.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'CONSULTA',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppConstants.blueNcs,
                        ),
                      ),
                    ),
                    Text(
                      'P.An.D.A Lex',
                      style: GoogleFonts.gupter(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: AppConstants.blueNcs,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionistaCard() {
    return GestureDetector(
      onTap: () {
        _showDisclaimerDialog();
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Icona e titolo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.blueNcs.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gavel_outlined,
                      color: AppConstants.blueNcs,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VUOI SAPERE SE SI CONFIGURA',
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: AppConstants.gray600,
                            ),
                          ),
                        ),
                        Text(
                          'UN REATO E COME DENUNCIARLO?',
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppConstants.gray800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Call to action
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.blueNcs.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  border: Border.all(color: AppConstants.blueNcs.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'CONSULTA',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppConstants.blueNcs,
                        ),
                      ),
                    ),
                    Text(
                      'UN PROFESSIONISTA',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppConstants.blueNcs,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget separato per il modal con StatefulWidget
class _QuestionModalWidget extends StatefulWidget {
  final VoidCallback onSuccess;
  
  const _QuestionModalWidget({
    required this.onSuccess,
  });

  @override
  State<_QuestionModalWidget> createState() => _QuestionModalWidgetState();
}

class _QuestionModalWidgetState extends State<_QuestionModalWidget> {
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Per favore, scrivi una domanda prima di inviare',
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: AppConstants.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crea l'email URI
      final emailUri = Uri(
        scheme: 'mailto',
        path: 'info@associazionepanda.it',
        query: _encodeQueryParameters(<String, String>{
          'subject': 'Domanda da P.An.D.A Lex',
          'body': question,
        }),
      );

      // Prova ad aprire l'app email
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
        }
      } else {
        throw Exception('Impossibile aprire l\'app email');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore nell\'invio dell\'email: ${e.toString()}',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.gray300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              
              // Contenuto scrollabile
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titolo
                      Text(
                        'Fai una domanda a P.An.D.A Lex',
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.gray800,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Descrivi la tua domanda su regolamenti e normative (massimo 10 righe)',
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: AppConstants.gray600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Campo di testo con altezza minima
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 200,
                          maxHeight: 300,
                        ),
                        child: TextField(
                          controller: _questionController,
                          maxLines: null,
                          minLines: 8,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Scrivi qui la tua domanda...',
                            hintStyle: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                color: AppConstants.gray400,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                              borderSide: const BorderSide(color: AppConstants.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                              borderSide: const BorderSide(color: AppConstants.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                              borderSide: const BorderSide(color: AppConstants.blueNcs, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Pulsanti
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              child: Text(
                                'Annulla',
                                style: GoogleFonts.lato(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    color: AppConstants.gray600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Invia',
                                      style: GoogleFonts.lato(
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}