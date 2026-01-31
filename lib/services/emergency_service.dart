import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PoliziaLocaleInfo {
  final String nome;
  final String indirizzo;
  final String? telefono;
  final double? distanza; // in km
  final double? latitudine;
  final double? longitudine;
  final String? placeId; // Necessario per recuperare i dettagli

  PoliziaLocaleInfo({
    required this.nome,
    required this.indirizzo,
    this.telefono,
    this.distanza,
    this.latitudine,
    this.longitudine,
    this.placeId,
  });

  factory PoliziaLocaleInfo.fromJson(Map<String, dynamic> json, Position? userPosition) {
    final location = json['geometry']?['location'];
    double? lat = location?['lat']?.toDouble();
    double? lng = location?['lng']?.toDouble();
    
    // Calcola distanza se abbiamo entrambe le posizioni
    double? distanza;
    if (userPosition != null && lat != null && lng != null) {
      distanza = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        lat,
        lng,
      ) / 1000; // Converti in km
    }

    return PoliziaLocaleInfo(
      nome: json['name'] ?? 'Polizia Locale',
      indirizzo: json['vicinity'] ?? json['formatted_address'] ?? 'Indirizzo non disponibile',
      telefono: json['formatted_phone_number'] ?? json['international_phone_number'],
      distanza: distanza,
      latitudine: lat,
      longitudine: lng,
      placeId: json['place_id'],
    );
  }

  PoliziaLocaleInfo copyWith({
    String? nome,
    String? indirizzo,
    String? telefono,
    double? distanza,
    double? latitudine,
    double? longitudine,
    String? placeId,
  }) {
    return PoliziaLocaleInfo(
      nome: nome ?? this.nome,
      indirizzo: indirizzo ?? this.indirizzo,
      telefono: telefono ?? this.telefono,
      distanza: distanza ?? this.distanza,
      latitudine: latitudine ?? this.latitudine,
      longitudine: longitudine ?? this.longitudine,
      placeId: placeId ?? this.placeId,
    );
  }
}

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final String _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  /// Verifica e richiede i permessi di localizzazione
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se il servizio di localizzazione è abilitato
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Ottiene la posizione corrente del dispositivo
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Errore nel recupero della posizione: $e');
      return null;
    }
  }

  /// Cerca la Polizia Locale più vicina usando Google Places API
  Future<PoliziaLocaleInfo?> findNearestPoliziaLocale() async {
    try {
      // Ottieni posizione corrente
      final position = await getCurrentPosition();
      if (position == null) {
        throw Exception('Impossibile ottenere la posizione');
      }

      // Lista di query da provare in ordine di priorità
      final queries = [
        'Polizia Locale',
        'Polizia Municipale',
        'Vigili Urbani',
        'Comando Polizia Locale',
      ];

      PoliziaLocaleInfo? bestResult;
      double? minDistance = double.infinity;

      // Prova ogni query
      for (final query in queries) {
        final result = await _searchNearby(position, query);
        if (result != null) {
          if (result.distanza != null && result.distanza! < minDistance!) {
            minDistance = result.distanza;
            bestResult = result;
          } else if (bestResult == null) {
            bestResult = result;
          }
        }
      }

      if (bestResult != null && bestResult.placeId != null) {
        // Ottieni i dettagli completi incluso il telefono
        return await _getPlaceDetails(bestResult.placeId!, bestResult, position);
      }

      return bestResult;
    } catch (e) {
      print('Errore nella ricerca della Polizia Locale: $e');
      return null;
    }
  }

  /// Cerca luoghi nelle vicinanze usando Google Places Nearby Search
  Future<PoliziaLocaleInfo?> _searchNearby(Position position, String query) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${position.latitude},${position.longitude}'
        '&radius=15000' // 15 km
        '&keyword=$query'
        '&language=it'
        '&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Prendi il primo risultato (il più vicino)
          return PoliziaLocaleInfo.fromJson(data['results'][0], position);
        }
      }

      return null;
    } catch (e) {
      print('Errore nella ricerca nearby: $e');
      return null;
    }
  }

  /// Ottiene i dettagli completi di un luogo usando Place Details API
  Future<PoliziaLocaleInfo> _getPlaceDetails(
    String placeId, 
    PoliziaLocaleInfo baseInfo, 
    Position position
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_address,formatted_phone_number,international_phone_number,geometry'
        '&language=it'
        '&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          
          // Aggiorna le informazioni con i dettagli completi
          return baseInfo.copyWith(
            nome: result['name'] ?? baseInfo.nome,
            indirizzo: result['formatted_address'] ?? baseInfo.indirizzo,
            telefono: result['formatted_phone_number'] ?? 
                     result['international_phone_number'] ?? 
                     baseInfo.telefono,
          );
        }
      }

      // Se fallisce, ritorna le info base
      return baseInfo;
    } catch (e) {
      print('Errore nel recupero dettagli: $e');
      return baseInfo;
    }
  }
}