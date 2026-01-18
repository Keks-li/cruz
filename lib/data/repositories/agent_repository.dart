import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AgentRepository {
  final SupabaseClient _supabase;

  AgentRepository(this._supabase);

  /// Fetch all agent profiles
  Future<List<Profile>> fetchAgents() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'AGENT')
          .order('full_name', ascending: true);

      return (response as List)
          .map((json) => Profile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch agents: $e');
    }
  }

  /// Toggle an agent's active status
  Future<void> toggleAgentActive(String agentId, bool isActive) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', agentId);
    } catch (e) {
      throw Exception('Failed to update agent status: $e');
    }
  }

  /// Get a single agent by ID
  Future<Profile?> getAgentById(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .eq('role', 'AGENT')
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch agent: $e');
    }
  }
}
