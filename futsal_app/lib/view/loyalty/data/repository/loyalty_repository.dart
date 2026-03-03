import 'package:ui/core/service/api_const.dart';
import 'package:ui/core/service/api_service.dart';
import '../model/loyalty_model.dart';

class LoyaltyRepository {
  final ApiService _api = ApiService();

  /// GET /api/v1/futsal/loyalty — current user's loyalty account
  Future<LoyaltyAccount> getAccount() async {
    final response = await _api.get(ApiConst.loyaltyAccount);
    return LoyaltyAccount.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/v1/futsal/loyalty/history — transaction history
  Future<List<LoyaltyTransaction>> getHistory() async {
    final response = await _api.get(ApiConst.loyaltyHistory);
    if (response.data is List) {
      return (response.data as List)
          .map((j) => LoyaltyTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
