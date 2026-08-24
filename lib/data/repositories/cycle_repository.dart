import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cycle.dart';

class CycleRepository {
  final SupabaseClient _supabase;

  CycleRepository(this._supabase);

  /// Fetch all cycles ordered by id (oldest first)
  Future<List<Cycle>> fetchCycles() async {
    try {
      final response = await _supabase
          .from('cycles')
          .select()
          .order('id', ascending: true);
      return (response as List)
          .map((json) => Cycle.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cycles: $e');
    }
  }

  /// Fetch the currently active cycle
  Future<Cycle?> fetchActiveCycle() async {
    try {
      final response = await _supabase
          .from('cycles')
          .select()
          .eq('is_active', true)
          .maybeSingle();
      if (response == null) return null;
      return Cycle.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch active cycle: $e');
    }
  }

  /// Set a cycle as active (deactivates all others first)
  Future<void> setActiveCycle(int cycleId) async {
    try {
      // Deactivate all cycles (PostgREST requires a filter clause)
      await _supabase.from('cycles').update({'is_active': false}).neq('id', 0);
      // Activate the selected one
      await _supabase
          .from('cycles')
          .update({'is_active': true})
          .eq('id', cycleId);
    } catch (e) {
      throw Exception('Failed to set active cycle: $e');
    }
  }

  /// Create a new named cycle (inactive by default)
  Future<Cycle> createCycle(String name, {String? notes}) async {
    try {
      final response = await _supabase
          .from('cycles')
          .insert({
            'name': name,
            'is_active': false,
            if (notes != null) 'notes': notes,
          })
          .select()
          .single();
      return Cycle.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create cycle: $e');
    }
  }

  /// Close a cycle by setting ended_at to now
  Future<void> closeCycle(int cycleId) async {
    try {
      await _supabase
          .from('cycles')
          .update({
            'is_active': false,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cycleId);
    } catch (e) {
      throw Exception('Failed to close cycle: $e');
    }
  }
}
