import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_constants.dart';
import '../models/garante.dart';
import '../services/api_service.dart';
import '../widgets/top_bar.dart';
import '../widgets/app_drawer.dart';

class GarantiScreen extends StatefulWidget {
  const GarantiScreen({Key? key}) : super(key: key);

  @override
  State<GarantiScreen> createState() => _GarantiScreenState();
}

class _GarantiScreenState extends State<GarantiScreen> {
  late GoogleMapController mapController;
  bool isLoading = true;
  List<Garante> allGaranti = [];
  Set<Marker> markers = {};
  final ApiService _apiService = ApiService();
  BitmapDescriptor? customMarkerIcon;
  Garante? selectedGarante;
  bool isPanelVisible = false;
  bool modalOpen = false;
  String? selectedRegion;
  List<String> regionItems = [];
  List<Garante> filteredGaranti = [];

  // coordinate delle regioni italiane per il filtro
  static const Map<String, CameraPosition> regionCoordinates = {
    'Abruzzo': CameraPosition(target: LatLng(42.3542, 13.3948), zoom: 8.0),
    'Basilicata': CameraPosition(target: LatLng(40.6394, 15.8050), zoom: 8.0),
    'Calabria': CameraPosition(target: LatLng(38.9093, 16.5878), zoom: 8.0),
    'Campania': CameraPosition(target: LatLng(40.8518, 14.2681), zoom: 8.0),
    'Emilia-Romagna': CameraPosition(target: LatLng(44.4949, 11.3426), zoom: 8.0),
    'Friuli-Venezia Giulia': CameraPosition(target: LatLng(45.6495, 13.7768), zoom: 8.0),
    'Lazio': CameraPosition(target: LatLng(41.9028, 12.4964), zoom: 8.0),
    'Liguria': CameraPosition(target: LatLng(44.4056, 8.9463), zoom: 8.0),
    'Lombardia': CameraPosition(target: LatLng(45.4642, 9.1900), zoom: 8.0),
    'Marche': CameraPosition(target: LatLng(43.6158, 13.5189), zoom: 8.0),
    'Molise': CameraPosition(target: LatLng(41.5600, 14.6619), zoom: 8.0),
    'Piemonte': CameraPosition(target: LatLng(45.0703, 7.6869), zoom: 8.0),
    'Puglia': CameraPosition(target: LatLng(41.1171, 16.8719), zoom: 8.0),
    'Sardegna': CameraPosition(target: LatLng(39.2238, 9.1217), zoom: 8.0),
    'Sicilia': CameraPosition(target: LatLng(38.1157, 13.3615), zoom: 8.0),
    'Toscana': CameraPosition(target: LatLng(43.7696, 11.2558), zoom: 8.0),
    'Trentino-Alto Adige': CameraPosition(target: LatLng(46.0667, 11.1217), zoom: 8.0),
    'Umbria': CameraPosition(target: LatLng(43.1122, 12.3886), zoom: 8.0),
    'Valle d\'Aosta': CameraPosition(target: LatLng(45.7372, 7.3201), zoom: 8.0),
    'Veneto': CameraPosition(target: LatLng(45.4408, 12.3155), zoom: 8.0),
  };

  // Coordinate iniziali per l'Italia (Roma) - come nel file React Native
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(41.9028, 12.4964), // Roma - coordinate dal file React Native INITIAL_REGION
    zoom: 6.0, // Zoom level corrispondente a latitudeDelta: 5, longitudeDelta: 5
  );

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _loadGaranti();
    setState(() {
      isLoading = false;
    });
  }

  void _updateFilteredData() {
    filteredGaranti = selectedRegion == null 
      ? allGaranti 
      : allGaranti.where((g) => g.regione == selectedRegion).toList();
    _createMarkers();
  }

  void _handleResetFilter() {
    setState(() {
      selectedRegion = null;
    });
    _updateFilteredData();
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(_initialPosition),
    );
  }

  void _selectRegion(String region) {
    setState(() {
      selectedRegion = region;
      modalOpen = false;
    });
    _updateFilteredData();
    
    final regionPos = regionCoordinates[region];
    if (regionPos != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(regionPos),
      );
    }
  }

  Future<void> _loadGaranti() async {
    try {
      await _createCustomMarkerIcon();
      final garanti = await _apiService.getAllGaranti();
      
      setState(() {
        allGaranti = garanti;
        // Estrai le regioni uniche
        regionItems = garanti
            .map((g) => g.regione)
            .where((r) => r.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        
        _updateFilteredData();
        isLoading = false;
      });
    } catch (e) {
      print('Errore nel caricamento dei Garanti: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createCustomMarkerIcon() async {
    try {
      customMarkerIcon = await BitmapDescriptor.asset(
        ImageConfiguration(
          size: const Size(32, 32),
          devicePixelRatio: 2.5, // Riduce le dimensioni su schermi ad alta densità
          ),
          'assets/images/marker.png',
          );
    } catch (e) {
      print('Errore nel caricamento dell\'icona marker: $e');
      customMarkerIcon = BitmapDescriptor.defaultMarker;
    }
  }


  void _showPanel(Garante garante) {
    setState(() {
      selectedGarante = garante;
      isPanelVisible = true;
    });
  }

  void _hidePanel() {
    setState(() {
      isPanelVisible = false;
      selectedGarante = null;
    });
  }

  Future<void> _handleEmailPress(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      print('Impossibile aprire il client email');
    }
  }

  void _createMarkers() {
    markers = filteredGaranti.map((garante) {
      return Marker(
        markerId: MarkerId(garante.id.toString()),
        position: LatLng(garante.latDouble, garante.lngDouble),
        icon: customMarkerIcon ?? BitmapDescriptor.defaultMarker,
        onTap: () {
          _showPanel(garante);
        },
      );
    }).toSet();
  }

  Widget _buildPanelContent() {
    if (selectedGarante == null) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsante di chiusura
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _hidePanel,
                child: Icon(
                  Icons.cancel,
                  color: AppConstants.gray400,
                  size: 30,
                ),
              ),
            ],
          ),
          
          // Titolo del garante
          Column(
            children: [
              if (selectedGarante!.citta?.isNotEmpty == true) ...[
                Text(
                  'Garante comune di',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w400, 
                      fontSize: 14,
                      color: AppConstants.gray800
                    )
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  selectedGarante!.citta!,
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 22,
                      color: AppConstants.azul
                    )
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  selectedGarante!.regione,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w400, 
                      fontSize: 18,
                      color: AppConstants.gray800
                    )
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  'Garante regione',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w400, 
                      fontSize: 14,
                      color: AppConstants.gray800
                    )
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  selectedGarante!.regione,
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 22,
                      color: AppConstants.azul
                    )
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          
          // Separatore
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 1,
            color: AppConstants.gray200,
          ),
          
          // Label contatti
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CONTATTI',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w400, 
                  fontSize: 12,
                  color: AppConstants.gray800
                )
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Lista contatti
          ...List.generate(3, (index) {
            final garanteField = index == 0 ? selectedGarante!.garante1 :
                              index == 1 ? selectedGarante!.garante2 : 
                              selectedGarante!.garante3;
            final emailField = index == 0 ? selectedGarante!.email1 :
                            index == 1 ? selectedGarante!.email2 : 
                            selectedGarante!.email3;
            
            if (garanteField?.isEmpty != false && emailField?.isEmpty != false) {
              return const SizedBox();
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (garanteField?.isNotEmpty == true)
                    Text(
                      garanteField!,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, 
                          fontSize: 18,
                          color: AppConstants.gray800,
                        ),
                      ),
                    ),
                  if (emailField?.isNotEmpty == true) ...[
                    if (garanteField?.isNotEmpty == true) const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _handleEmailPress(emailField!),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.gray200.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: AppConstants.blueNcs,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: GoogleFonts.lato(
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w400, 
                                        fontSize: 12,
                                        color: AppConstants.gray400
                                      )
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    emailField!,
                                    style: GoogleFonts.lato(
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w400, 
                                        fontSize: 14,
                                        color: AppConstants.gray800
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppConstants.gray400,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          
          // Spazio per evitare sovrapposizioni con navigation bar
          const SizedBox(height: 0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBar(
        title: "Garanti",
        showBackButton: true,
      ),
      endDrawer: const AppDrawer(),
      body: Stack(
        children: [
          // Mappa
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: markers,
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            liteModeEnabled: false,
            // Stile della mappa (mantenere default per ora)
            onTap: (LatLng position) {
              // Handle map tap to dismiss panel
              _hidePanel();
            },
          ),

          // Modal per selezione regione
        if (modalOpen)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxHeight: 500, minWidth: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Seleziona Regione',
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, 
                              fontSize: 18,
                              color: AppConstants.gray800
                            )
                          ),
                        ),
                      ),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: regionItems.length,
                          itemBuilder: (context, index) {
                            final region = regionItems[index];
                            final isSelected = selectedRegion == region;
                            return ListTile(
                              title: Text(
                                region,
                                style: GoogleFonts.lato(
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w400, 
                                    fontSize: 16,
                                    color: AppConstants.gray600,
                                  )
                                ),
                              ),
                              trailing: isSelected 
                                ? Icon(Icons.check, color: AppConstants.blueNcs, size: 20)
                                : null,
                              onTap: () => _selectRegion(region),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => modalOpen = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.gray500,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Chiudi',
                              style: GoogleFonts.lato(
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w500, 
                                  fontSize: 16,
                                  color: AppConstants.white
                                )
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Indicatore di caricamento
          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.blueNcs),
                      strokeWidth: 3.0,
                    ),
                    SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      'Caricamento mappa...',
                      style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
                    ),
                  ],
                ),
              ),
            ),
          
          // Controlli filtro regione
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => modalOpen = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.blueNcs,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedRegion ?? "Tutte le regioni",
                            style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w500, 
                                fontSize: 14,
                                color: AppConstants.white
                              )
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (selectedRegion != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _handleResetFilter,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppConstants.blueNcs,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Pannello Informativo Animato
        if (isPanelVisible && selectedGarante != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(
                0,
                isPanelVisible ? 0 : 400,
                0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: _buildPanelContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}