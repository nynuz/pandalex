import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../app_constants.dart';
import '../services/eventi_garanti_service.dart';
import '../services/location_service.dart';
import '../models/evento_garante.dart';
import '../widgets/background_wrapper.dart';
import '../widgets/emergency_scaffold.dart';
import '../widgets/report_floating_button.dart';
import 'evento_pubblico_detail_screen.dart';

class EventiPubbliciScreen extends StatefulWidget {
  const EventiPubbliciScreen({Key? key}) : super(key: key);

  @override
  State<EventiPubbliciScreen> createState() => _EventiPubbliciScreenState();
}

class _EventiPubbliciScreenState extends State<EventiPubbliciScreen> {
  final EventiGarantiService _eventiService = EventiGarantiService();
  final LocationService _locationService = LocationService();
  
  List<EventoGarante> _eventi = [];
  List<String> _regioni = [];
  String? _regioneSelezionata;
  String? _regioneUtente;
  bool _isLoading = true;
  bool _isLoadingLocation = true;

  int _selectedIndex = 3; // Index per la tab "Eventi"
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Carica regione utente in parallelo
    _loadRegioneUtente();
    
    // Carica lista regioni
    await _loadRegioni();
    
    // Carica eventi
    await _loadEventi();
  }

  Future<void> _loadRegioneUtente() async {
    setState(() => _isLoadingLocation = true);
    
    final regione = await _locationService.getCurrentRegione();
    
    setState(() {
      _regioneUtente = regione;
      _isLoadingLocation = false;
      
      // Imposta automaticamente la regione dell'utente come filtro SOLO se è nella lista
      if (regione != null && _regioni.contains(regione) && _regioneSelezionata == null) {
        _regioneSelezionata = regione;
      }
    });
    
    // Ricarica eventi con la regione utente SOLO se è stata impostata
    if (_regioneSelezionata != null) {
      _loadEventi();
    }
  }

  Future<void> _loadRegioni() async {
    final regioni = await _eventiService.getRegioniConEventi();
    setState(() => _regioni = regioni);
  }

  Future<void> _loadEventi() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final regione = _regioneSelezionata == 'Tutte le regioni' ? null : _regioneSelezionata;
      final eventi = await _eventiService.getTuttiEventiPubblici(regione: regione);
      
      if (mounted) {
        setState(() {
          _eventi = eventi;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Errore caricamento eventi: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostraFiltroRegioni() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtra per Regione',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.gray800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Opzione "Tutte le regioni"
            ListTile(
              leading: Icon(
                Icons.public,
                color: _regioneSelezionata == null ? AppConstants.blueNcs : AppConstants.gray400,
              ),
              title: Text(
                'Tutte le regioni',
                style: GoogleFonts.lato(
                  fontWeight: _regioneSelezionata == null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: _regioneSelezionata == null
                  ? const Icon(Icons.check, color: AppConstants.blueNcs)
                  : null,
              selected: _regioneSelezionata == null,
              selectedTileColor: AppConstants.blueNcs.withOpacity(0.1),
              onTap: () {
                setState(() => _regioneSelezionata = null);
                Navigator.pop(context);
                _loadEventi();
              },
            ),
            
            const Divider(height: 1),
            
            // Lista regioni
            Expanded(
              child: _regioni.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Nessuna regione disponibile',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: AppConstants.gray500,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _regioni.length,
                      itemBuilder: (context, index) {
                        final regione = _regioni[index];
                        final isSelected = _regioneSelezionata == regione;
                        final isUserRegione = _regioneUtente == regione;
                        
                        return ListTile(
                          leading: Icon(
                            isUserRegione ? Icons.my_location : Icons.location_on_outlined,
                            color: isSelected ? AppConstants.blueNcs : AppConstants.gray400,
                          ),
                          title: Text(
                            regione,
                            style: GoogleFonts.lato(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          subtitle: isUserRegione
                              ? Text(
                                  'La tua regione',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: AppConstants.blueNcs,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppConstants.blueNcs)
                              : null,
                          selected: isSelected,
                          selectedTileColor: AppConstants.blueNcs.withOpacity(0.1),
                          onTap: () {
                            setState(() => _regioneSelezionata = regione);
                            Navigator.pop(context);
                            _loadEventi();
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
      title: "Eventi",
      showBackButton: true,
      selectedNavIndex: _selectedIndex,
      onNavItemTapped: _onItemTapped,
      floatingActionButton: const ReportFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BackgroundWrapper(
        child: Column(
          children: [
            // Header con filtro regioni
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppConstants.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppConstants.blueNcs,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtra per regione',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppConstants.gray500,
                          ),
                        ),
                        Text(
                          _regioneSelezionata ?? 'Tutte le regioni',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.gray800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingLocation)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.blueNcs),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _mostraFiltroRegioni,
                      color: AppConstants.blueNcs,
                    ),
                ],
              ),
            ),

            // Lista Eventi
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadRegioneUtente();
                        await _loadRegioni();
                        await _loadEventi();
                      },
                      child: _eventi.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _eventi.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return _buildEventoCard(_eventi[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoCard(EventoGarante evento) {
    final isNazionale = evento.regione?.toUpperCase() == 'NAZIONALE';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNazionale 
            ? BorderSide(color: AppConstants.orange, width: 2.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventoPubblicoDetailScreen(evento: evento),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge Nazionale se applicabile
            if (isNazionale)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.orange,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'EVENTO NAZIONALE',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Immagine
            if (evento.immagineUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: isNazionale ? Radius.zero : const Radius.circular(12),
                ),
                child: Image.network(
                  evento.immagineUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: AppConstants.gray200,
                      child: const Icon(Icons.broken_image, size: 48, color: AppConstants.gray400),
                    );
                  },
                ),
              ),
            
            // Contenuto
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Regione (solo se NON nazionale)
                  if (!isNazionale && evento.regione != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppConstants.blueNcs.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppConstants.blueNcs),
                          const SizedBox(width: 4),
                          Text(
                            evento.regione!,
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.blueNcs,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Titolo
                  Text(
                    evento.titolo,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.gray800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Descrizione
                  Text(
                    evento.descrizione,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppConstants.gray600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Data
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppConstants.blueNcs),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMMM yyyy', 'it_IT').format(evento.dataEvento),
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.blueNcs,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_note_outlined,
              size: 80,
              color: AppConstants.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              _regioneSelezionata != null
                  ? 'Nessun evento in $_regioneSelezionata'
                  : 'Nessun evento disponibile',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.gray600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _regioneSelezionata != null
                  ? 'Prova a selezionare un\'altra regione'
                  : 'Al momento non ci sono eventi pubblicati',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.gray500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}