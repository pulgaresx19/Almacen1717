import 'package:supabase_flutter/supabase_flutter.dart';

class UldsV2Service {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchUldAwbs(String uldId) async {
    try {
      final res = await supabase
          .from('awb_splits')
          .select('*, awbs(*)')
          .eq('uld_id', uldId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }
}
