import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepository {
  final SupabaseClient _supabase;

  SettingsRepository(this._supabase);

  /// Get a system setting by key
  Future<String?> getSetting(String key) async {
    try {
      final response = await _supabase
          .from('system_settings')
          .select('value')
          .eq('key', key)
          .maybeSingle();

      if (response == null) return null;
      return response['value'] as String?;
    } catch (e) {
      throw Exception('Failed to get setting: $e');
    }
  }

  /// Update or insert a system setting
  Future<void> setSetting(String key, String value) async {
    try {
      await _supabase
          .from('system_settings')
          .upsert({
            'key': key,
            'value': value,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to set setting: $e');
    }
  }

  /// Get registration fee
  Future<double> getRegistrationFee() async {
    try {
      final value = await getSetting('registration_fee');
      if (value == null) return 0.0;
      return double.tryParse(value) ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get registration fee: $e');
    }
  }

  /// Set registration fee
  Future<void> setRegistrationFee(double fee) async {
    try {
      await setSetting('registration_fee', fee.toString());
    } catch (e) {
      throw Exception('Failed to set registration fee: $e');
    }
  }
}
