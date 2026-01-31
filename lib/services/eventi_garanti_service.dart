import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/evento_garante.dart';

class EventiGarantiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Ottieni il conteggio totale eventi del garante
  Future<int> getEventiCount(String garanteId) async {
    try {
      final response = await _supabase
          .from('eventi_garanti')
          .select()
          .eq('garante_id', garanteId);
      
      return response.length;
    } catch (e) {
      debugPrint('Errore conteggio eventi: $e');
      return 0;
    }
  }

  // Ottieni gli ultimi N eventi del garante
  Future<List<EventoGarante>> getUltimiEventi(String garanteId, {int limit = 3}) async {
    try {
      final response = await _supabase
          .from('eventi_garanti')
          .select()
          .eq('garante_id', garanteId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => EventoGarante.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Errore recupero ultimi eventi: $e');
      return [];
    }
  }

  // Ottieni tutti gli eventi del garante
  Future<List<EventoGarante>> getTuttiEventi(String garanteId) async {
    try {
      final response = await _supabase
          .from('eventi_garanti')
          .select()
          .eq('garante_id', garanteId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EventoGarante.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Errore recupero tutti eventi: $e');
      return [];
    }
  }

  // Ottieni singolo evento
  Future<EventoGarante?> getEvento(String eventoId) async {
    try {
      final response = await _supabase
          .from('eventi_garanti')
          .select()
          .eq('id', eventoId)
          .single();

      return EventoGarante.fromJson(response);
    } catch (e) {
      debugPrint('Errore recupero evento: $e');
      return null;
    }
  }

  // Ottieni tutti gli eventi pubblici con JOIN alla tabella garanti
  Future<List<EventoGarante>> getTuttiEventiPubblici({String? regione}) async {
    try {
      debugPrint('=== getTuttiEventiPubblici ===');
      debugPrint('Regione filtro: $regione');

      // Query base con JOIN
      var query = _supabase
          .from('eventi_garanti')
          .select('*, garanti!inner(regione)')
          .eq('pubblicato', true);
      
      // Applica filtro regione se specificato
      // Gli eventi con regione "NAZIONALE" sono sempre visibili
      if (regione != null && regione.isNotEmpty) {
        // Usa .in() invece di .or() per una sintassi più chiara
        query = query.filter(
          'garanti.regione', 
          'in', 
          '($regione,NAZIONALE)'
        );
      }
      
      final response = await query.order('created_at', ascending: false);

      debugPrint('Response count: ${(response as List).length}');

      // Mappa i risultati
      final eventi = (response as List).map((json) {
        debugPrint('Evento JSON: $json');
        
        // Estrai la regione dal join
        String? regioneGarante;
        if (json['garanti'] != null) {
          if (json['garanti'] is Map) {
            regioneGarante = json['garanti']['regione'];
          }
        }
        
        debugPrint('Regione estratta: $regioneGarante');
        
        // Crea nuovo JSON con regione al primo livello
        final eventoJson = Map<String, dynamic>.from(json);
        eventoJson['regione'] = regioneGarante;
        eventoJson.remove('garanti');
        
        return EventoGarante.fromJson(eventoJson);
      }).toList();

      debugPrint('Eventi mappati: ${eventi.length}');
      return eventi;
    } catch (e) {
      debugPrint('Errore recupero eventi pubblici: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Ottieni lista regioni con eventi
  Future<List<String>> getRegioniConEventi() async {
    try {
      debugPrint('=== getRegioniConEventi ===');
      
      final response = await _supabase
          .from('eventi_garanti')
          .select('garanti!inner(regione)')
          .eq('pubblicato', true);

      debugPrint('Response regioni: $response');

      final Set<String> regioniSet = {};
      for (var item in response as List) {
        debugPrint('Item: $item');
        
        if (item['garanti'] != null) {
          final regione = item['garanti']['regione'];
          debugPrint('Regione trovata: $regione');
          
          // Escludi gli eventi nazionali dalla lista regioni
          if (regione != null && 
              regione.toString().trim().isNotEmpty && 
              regione.toString().trim() != 'NAZIONALE') {
            regioniSet.add(regione.toString().trim());
          }
        }
      }
      
      final regioni = regioniSet.toList();
      regioni.sort();
      
      debugPrint('Regioni finali: $regioni');
      
      return regioni;
    } catch (e) {
      debugPrint('Errore recupero regioni: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Crea nuovo evento
  Future<Map<String, dynamic>> creaEvento({
    required String garanteId,
    required String titolo,
    required String descrizione,
    String? immagineUrl,
    required bool pubblicato,
    DateTime? dataEvento,
  }) async {
    try {
      final response = await _supabase
          .from('eventi_garanti')
          .insert({
            'garante_id': garanteId,
            'titolo': titolo,
            'descrizione': descrizione,
            'immagine_url': immagineUrl,
            'pubblicato': pubblicato,
            'data_evento': dataEvento?.toIso8601String(),
          })
          .select()
          .single();

      return {
        'success': true,
        'evento': EventoGarante.fromJson(response),
        'message': 'Evento creato con successo',
      };
    } catch (e) {
      debugPrint('Errore creazione evento: $e');
      return {
        'success': false,
        'message': 'Errore durante la creazione dell\'evento',
      };
    }
  }

  // Aggiorna evento esistente
  Future<Map<String, dynamic>> aggiornaEvento({
    required String eventoId,
    required String titolo,
    required String descrizione,
    String? immagineUrl,
    required bool pubblicato,
    DateTime? dataEvento,
  }) async {
    try {
      final response = await _supabase
          .from('eventi_garanti')
          .update({
            'titolo': titolo,
            'descrizione': descrizione,
            'immagine_url': immagineUrl,
            'pubblicato': pubblicato,
            'data_evento': dataEvento?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventoId)
          .select()
          .single();

      return {
        'success': true,
        'evento': EventoGarante.fromJson(response),
        'message': 'Evento aggiornato con successo',
      };
    } catch (e) {
      debugPrint('Errore aggiornamento evento: $e');
      return {
        'success': false,
        'message': 'Errore durante l\'aggiornamento dell\'evento',
      };
    }
  }

  // Elimina evento
  Future<Map<String, dynamic>> eliminaEvento(String eventoId, String? immagineUrl) async {
    try {
      if (immagineUrl != null && immagineUrl.isNotEmpty) {
        await eliminaImmagine(immagineUrl);
      }

      await _supabase
          .from('eventi_garanti')
          .delete()
          .eq('id', eventoId);

      return {
        'success': true,
        'message': 'Evento eliminato con successo',
      };
    } catch (e) {
      debugPrint('Errore eliminazione evento: $e');
      return {
        'success': false,
        'message': 'Errore durante l\'eliminazione dell\'evento',
      };
    }
  }

  // Upload immagine
  Future<String?> uploadImmagine(String garanteId, String eventoId, String filePath) async {
    try {
      final fileName = '${garanteId}_${eventoId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage
          .from('eventi_garanti_images')
          .upload(fileName, File(filePath));

      final url = _supabase.storage
          .from('eventi_garanti_images')
          .getPublicUrl(fileName);

      return url;
    } catch (e) {
      debugPrint('Errore upload immagine: $e');
      return null;
    }
  }

  // Elimina immagine
  Future<void> eliminaImmagine(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      await _supabase.storage
          .from('eventi_garanti_images')
          .remove([fileName]);
    } catch (e) {
      debugPrint('Errore eliminazione immagine: $e');
    }
  }
}