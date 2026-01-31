import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../app_constants.dart';
import '../../providers/garante_auth_provider.dart';
import '../../services/eventi_garanti_service.dart';
import '../../models/evento_garante.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/app_drawer.dart';

class AreaGarantiEventoFormScreen extends StatefulWidget {
  final EventoGarante? evento;

  const AreaGarantiEventoFormScreen({
    Key? key,
    this.evento,
  }) : super(key: key);

  @override
  State<AreaGarantiEventoFormScreen> createState() => _AreaGarantiEventoFormScreenState();
}

class _AreaGarantiEventoFormScreenState extends State<AreaGarantiEventoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titoloController = TextEditingController();
  final _descrizioneController = TextEditingController();
  final EventiGarantiService _eventiService = EventiGarantiService();
  final ImagePicker _picker = ImagePicker();
  
  File? _immagineFile;
  String? _immagineUrlEsistente;
  bool _pubblicato = true;
  bool _isLoading = false;
  DateTime? _dataEvento;

  bool get _isModifica => widget.evento != null;

  bool get _isGaranteAdmin {
    final garante = context.read<GaranteAuthProvider>().currentGarante;
    return garante?.regione?.toUpperCase() == 'NAZIONALE';
  }

  @override
  void initState() {
    super.initState();
    if (_isModifica) {
      _titoloController.text = widget.evento!.titolo;
      _descrizioneController.text = widget.evento!.descrizione;
      _immagineUrlEsistente = widget.evento!.immagineUrl;
      _pubblicato = widget.evento!.pubblicato;
      _dataEvento = widget.evento!.dataEvento;
    }
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _immagineFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante la selezione dell\'immagine'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selezionaData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataEvento ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 anni
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.blueNcs,
              onPrimary: Colors.white,
              onSurface: AppConstants.gray800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dataEvento) {
      setState(() => _dataEvento = picked);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppConstants.blueNcs),
                title: Text('Galleria', style: GoogleFonts.lato()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppConstants.blueNcs),
                title: Text('Fotocamera', style: GoogleFonts.lato()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvaEvento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final garanteId = context.read<GaranteAuthProvider>().currentGarante?.id;
    if (garanteId == null) {
      setState(() => _isLoading = false);
      return;
    }

    String? immagineUrl = _immagineUrlEsistente;

    // Upload nuova immagine se selezionata
    if (_immagineFile != null) {
      final eventoId = _isModifica ? widget.evento!.id : DateTime.now().millisecondsSinceEpoch.toString();
      immagineUrl = await _eventiService.uploadImmagine(
        garanteId,
        eventoId,
        _immagineFile!.path,
      );

      if (immagineUrl == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante l\'upload dell\'immagine'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Elimina vecchia immagine se in modifica
      if (_isModifica && _immagineUrlEsistente != null) {
        await _eventiService.eliminaImmagine(_immagineUrlEsistente!);
      }
    }

    // Salva evento
    final Map<String, dynamic> result;
    if (_isModifica) {
      result = await _eventiService.aggiornaEvento(
        eventoId: widget.evento!.id,
        titolo: _titoloController.text.trim(),
        descrizione: _descrizioneController.text.trim(),
        immagineUrl: immagineUrl,
        pubblicato: _pubblicato,
        dataEvento: _dataEvento,
      );
    } else {
      result = await _eventiService.creaEvento(
        garanteId: garanteId,
        titolo: _titoloController.text.trim(),
        descrizione: _descrizioneController.text.trim(),
        immagineUrl: immagineUrl,
        pubblicato: _pubblicato,
        dataEvento: _dataEvento,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? AppConstants.green : Colors.red,
        ),
      );

      if (result['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: _isModifica ? 'Modifica Evento' : 'Crea Evento',
        showBackButton: true,
      ),
      endDrawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Anteprima/Upload Immagine
                _buildImageSection(),
                const SizedBox(height: 24),

                // Campo Titolo
                TextFormField(
                  controller: _titoloController,
                  style: GoogleFonts.lato(),
                  decoration: InputDecoration(
                    labelText: 'Titolo *',
                    hintText: 'Es: Incontro pubblico sulla privacy',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.blueNcs, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il titolo';
                    }
                    if (value.trim().length < 5) {
                      return 'Il titolo deve essere di almeno 5 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Descrizione
                TextFormField(
                  controller: _descrizioneController,
                  style: GoogleFonts.lato(),
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Descrizione *',
                    hintText: 'Descrivi l\'evento...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.blueNcs, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci la descrizione';
                    }
                    if (value.trim().length < 20) {
                      return 'La descrizione deve essere di almeno 20 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Data Evento con validator
                GestureDetector(
                  onTap: _selezionaData,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _dataEvento != null ? AppConstants.gray300 : Colors.red.shade300,
                        width: _dataEvento != null ? 1 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              color: _dataEvento != null ? AppConstants.blueNcs : Colors.red.shade400,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data Evento *',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: _dataEvento != null ? AppConstants.gray600 : Colors.red.shade400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dataEvento != null
                                        ? DateFormat('dd MMMM yyyy', 'it_IT').format(_dataEvento!)
                                        : 'Seleziona una data',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      color: _dataEvento != null 
                                          ? AppConstants.gray800 
                                          : Colors.red.shade400,
                                      fontWeight: _dataEvento != null 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_dataEvento != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                color: AppConstants.gray400,
                                onPressed: () => setState(() => _dataEvento = null),
                              ),
                          ],
                        ),
                        if (_dataEvento == null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Seleziona una data per l\'evento',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Toggle Pubblicato
                Card(
                  elevation: 0,
                  color: AppConstants.gray100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: Text('Pubblica evento', style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _pubblicato ? 'L\'evento sarà visibile a tutti' : 'L\'evento sarà una bozza',
                      style: GoogleFonts.lato(fontSize: 12, color: AppConstants.gray600),
                    ),
                    value: _pubblicato,
                    activeColor: AppConstants.green,
                    onChanged: (value) => setState(() => _pubblicato = value),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottoni
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Annulla', style: GoogleFonts.lato(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _salvaEvento,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.blueNcs,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                _isModifica ? 'Aggiorna' : 'Crea Evento',
                                style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Immagine',
              style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600, color: AppConstants.gray800),
            ),
            if (_isGaranteAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.orange, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public, size: 14, color: AppConstants.orange),
                    const SizedBox(width: 4),
                    Text(
                      'EVENTO NAZIONALE',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        if (_immagineFile != null || _immagineUrlEsistente != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _immagineFile != null
                    ? Image.file(
                        _immagineFile!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        _immagineUrlEsistente!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => setState(() {
                    _immagineFile = null;
                    _immagineUrlEsistente = null;
                  }),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppConstants.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.gray300, width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: AppConstants.gray400),
                  const SizedBox(height: 8),
                  Text('Aggiungi Immagine', style: GoogleFonts.lato(color: AppConstants.gray600)),
                  Text('(Opzionale)', style: GoogleFonts.lato(fontSize: 12, color: AppConstants.gray500)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}