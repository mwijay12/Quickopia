import '../config/supabase_config.dart';
import '../models/branch_model.dart';

class BranchService {
  final _client = SupabaseConfig.client;

  Future<Branch> fetchPrimaryBranch() async {
    final response = await _client.from('branches').select().limit(1).single();
    return Branch.fromMap(response);
  }
}
