import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Mappa coordinate italiane alle regioni
  static const Map<String, List<double>> regioniCoordinate = {
    'Abruzzo': [42.3511, 13.3995],
    'Basilicata': [40.6387, 15.8055],
    'Calabria': [38.9101, 16.5875],
    'Campania': [40.8333, 14.2500],
    'Emilia-Romagna': [44.4936, 11.3426],
    'Friuli-Venezia Giulia': [45.6361, 13.8040],
    'Lazio': [41.8931, 12.4828],
    'Liguria': [44.4056, 8.9463],
    'Lombardia': [45.4654, 9.1859],
    'Marche': [43.6166, 13.5166],
    'Molise': [41.5610, 14.6680],
    'Piemonte': [45.0703, 7.6869],
    'Puglia': [41.1171, 16.8719],
    'Sardegna': [40.1209, 9.0129],
    'Sicilia': [38.1157, 13.3615],
    'Toscana': [43.7711, 11.2486],
    'Trentino-Alto Adige': [46.0664, 11.1257],
    'Umbria': [43.1107, 12.3908],
    'Valle d\'Aosta': [45.7370, 7.3205],
    'Veneto': [45.4408, 12.3155],
  };

  // Ottieni posizione corrente
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      print('Errore geolocalizzazione: $e');
      return null;
    }
  }

  // Ottieni regione dalla posizione
  Future<String?> getRegioneFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return placemark.administrativeArea; // Restituisce la regione
      }
      return null;
    } catch (e) {
      print('Errore geocoding: $e');
      return null;
    }
  }

  // Ottieni regione corrente dell'utente
  Future<String?> getCurrentRegione() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return await getRegioneFromPosition(position);
    }
    return null;
  }

  // Trova regione più vicina alle coordinate (fallback)
  String? getNearestRegione(double lat, double lon) {
    String? nearestRegione;
    double minDistance = double.infinity;

    regioniCoordinate.forEach((regione, coords) {
      final distance = Geolocator.distanceBetween(
        lat,
        lon,
        coords[0],
        coords[1],
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestRegione = regione;
      }
    });

    return nearestRegione;
  }
}