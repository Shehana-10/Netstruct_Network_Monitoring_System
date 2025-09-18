import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response =
        await _supabase
            .from('users')
            .select('username')
            .eq('id', user.id)
            .single();

    return {'username': response['username'] as String?, 'email': user.email};
  }
}
