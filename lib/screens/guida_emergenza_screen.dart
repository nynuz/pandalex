import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../app_constants.dart';
import '../models/guide_data.dart';

class GuidaEmergenzaScreen extends StatefulWidget {
  const GuidaEmergenzaScreen({Key? key}) : super(key: key);

  @override
  State<GuidaEmergenzaScreen> createState() => _GuidaEmergenzaScreenState();
}

class _GuidaEmergenzaScreenState extends State<GuidaEmergenzaScreen> {
  String currentStepId = 'start';

  void _handleSelectOption(GuideOption option) {
    setState(() {
      if (option.nextStepId != null) {
        currentStepId = option.nextStepId!;
      } else if (option.summaryId != null) {
        currentStepId = option.summaryId!;
      }
    });
  }

  void _resetGuide() {
    setState(() {
      currentStepId = 'start';
    });
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Imposta la status bar per sfondo scuro
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    final currentData = _getCurrentData();

    if (currentData == null) {
      return _buildErrorScreen();
    }

    // Se è un summary, mostra la schermata finale
    if (currentData is GuideSummary) {
      return _buildSummaryScreen(currentData);
    }

    // Altrimenti mostra lo step corrente
    return _buildStepScreen(currentData as GuideStep);
  }

  dynamic _getCurrentData() {
    return GuideData.guideTree[currentStepId] ?? 
           GuideData.guideSummaries[currentStepId];
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.red,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Errore: step non trovato',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _resetGuide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Ricomincia'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryScreen(GuideSummary summary) {
    return Scaffold(
      backgroundColor: AppConstants.blueNcs,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                summary.icon,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                summary.title,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                summary.text,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _resetGuide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppConstants.blueNcs,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Ricomincia la guida',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: AppConstants.blueNcs,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _goHome,
                child: Text(
                  'Torna alla Home',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepScreen(GuideStep step) {
    return Scaffold(
      backgroundColor: AppConstants.blueNcs,
      body: SafeArea(
        child: Stack(
          children: [
            // Pulsante Home
            Positioned(
              top: 16,
              left: 20,
              child: GestureDetector(
                onTap: _goHome,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.home_outlined,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Contenuto principale
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                children: [
                  // Header con altezza dinamica
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        step.icon,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.title,
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.question,
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Spazio flessibile per le opzioni
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lista opzioni con spazio flessibile
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: step.options.length,
                            itemBuilder: (context, index) {
                              return _buildOptionButton(step.options[index]);
                            },
                          ),
                        ),
                        
                        // Pulsante reset sempre visibile
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton(
                            onPressed: _resetGuide,
                            child: Text(
                              'Ricomincia la guida',
                              style: GoogleFonts.lato(
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(GuideOption option) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _handleSelectOption(option),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          option.text,
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Ripristina la status bar quando si esce dalla schermata
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