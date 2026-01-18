import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone.dart';

class ZoneRepository {
  final SupabaseClient _supabase;

  ZoneRepository(this._supabase);

  /// Fetch all zones
  Future<List<Zone>> fetchZones() async {
    try {
      final response = await _supabase
          .from('zones')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Zone.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch zones: $e');
    }
  }

  /// Create a new zone
  Future<Zone> createZone(String name) async {
    try {
      final response = await _supabase
          .from('zones')
          .insert({'name': name})
          .select()
          .single();

      return Zone.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create zone: $e');
    }
  }

  /// Update an existing zone
  Future<void> updateZone(int zoneId, String name) async {
    try {
      await _supabase
          .from('zones')
          .update({'name': name})
          .eq('id', zoneId);
    } catch (e) {
      throw Exception('Failed to update zone: $e');
    }
  }

  /// Delete a zone
  Future<void> deleteZone(int zoneId) async {
    try {
      await _supabase
          .from('zones')
          .delete()
          .eq('id', zoneId);
    } catch (e) {
      throw Exception('Failed to delete zone: $e');
    }
  }
}
