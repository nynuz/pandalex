import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import '../app_constants.dart';
import '../services/user_service.dart';
import '../widgets/background_wrapper.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final UserService _userService = UserService();
  
  String? _selectedRole;
  bool _isLoading = false;
  bool _acceptedTerms = true; // Impostare a false per riattivare i termini e condizioni
  
  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'associazione',
      'label': 'Associazione',
      'icon': Icons.group_outlined,
      //'description': '',
    },
    {
      'value': 'amministrazione',
      'label': 'Amministrazione',
      'icon': Icons.account_balance_outlined,
      //'description': '',
    },
    {
      'value': 'forze-ordine',
      'label': 'Forze dell\'Ordine',
      'icon': Icons.local_police_outlined,
      //'description': '',
    },
    {
      'value': 'guardie-zoofile',
      'label': 'Guardie Zoofile',
      'icon': Icons.security_outlined,
      //'description': '',
    },
    {
      'value': 'garante-animali',
      'label': 'Garante Animali',
      'icon': Icons.security_outlined,
      //'description': '',
    },
    {
      'value': 'sanità-animale',
      'label': 'Sanità Animale',
      'icon': Icons.medical_services_outlined,
      //'description': '',
    },
    {
      'value': 'volontario',
      'label': 'Volontario',
      'icon': Icons.volunteer_activism_outlined,
      //'description': '',
    }
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedRole == null || !_acceptedTerms) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Salva i dati dell'utente
      final success = await _userService.saveUserData(
        email: _emailController.text,
        role: _selectedRole!,
      );

      if (success) {
        _showSuccessSnackBar('Registrazione completata con successo!');
        
        // Attendi un momento per mostrare il messaggio
        await Future.delayed(const Duration(seconds: 1));
        
        // Naviga alla home screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showErrorSnackBar('Errore durante la registrazione. Riprova.');
      }
    } catch (e) {
      if (e.toString().contains('duplicate') || e.toString().contains('already exists')) {
        _showErrorSnackBar('Questa email è già registrata nel sistema.');
      } else {
        _showErrorSnackBar('Errore durante la registrazione. Riprova.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppConstants.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
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

    return Scaffold(
      backgroundColor: AppConstants.blueNcs,
      body: BackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //const SizedBox(height: 20),
                  
                  // Logo e titolo
                  _buildHeader(),
                  
                  const SizedBox(height: 20),
                  
                  // Card del form
                  _buildFormCard(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [    
        // Titolo
        Text(
          'Benvenuto',
          style: GoogleFonts.gupter(
            textStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppConstants.gray800,
            ),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Sottotitolo
        Text(
          'Per iniziare, compila il form sottostante',
          style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppConstants.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          _buildEmailField(),
          
          const SizedBox(height: 24),
          
          // Role selection
          _buildRoleSelection(),
          
          const SizedBox(height: 24),
          
          // Terms checkbox
          //_buildTermsCheckbox(),
          
          //const SizedBox(height: 32),
          
          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indirizzo Email',
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.gray800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci il tuo indirizzo email';
            }
            if (!EmailValidator.validate(value.trim())) {
              return 'Inserisci un indirizzo email valido';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'esempio@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleziona il tuo ruolo',
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.gray800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._roles.map((role) => _buildRoleOption(role)).toList(),
      ],
    );
  }

  Widget _buildRoleOption(Map<String, dynamic> role) {
    final isSelected = _selectedRole == role['value'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role['value']),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.blueNcs.withOpacity(0.1) : AppConstants.gray100,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(
              color: isSelected ? AppConstants.blueNcs : AppConstants.gray300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                role['icon'],
                color: isSelected ? AppConstants.blueNcs : AppConstants.gray600,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role['label'],
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppConstants.blueNcs : AppConstants.gray800,
                        ),
                      ),
                    ),
                    //const SizedBox(height: 4),
                    /*Text(
                      role['description'],
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: isSelected ? AppConstants.gray700 : AppConstants.gray600,
                        ),
                      ),
                    ),*/
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppConstants.blueNcs,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
          activeColor: AppConstants.blueNcs,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Accetto di essere contattato per aggiornamenti sulle normative e di fornire i miei dati per migliorare il servizio.',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.gray600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isFormValid = _selectedRole != null && _acceptedTerms;
    
    return ElevatedButton(
      onPressed: isFormValid && !_isLoading ? _handleSubmit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.blueNcs,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppConstants.gray300,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        elevation: isFormValid ? 4 : 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Inizia ad esplorare',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}