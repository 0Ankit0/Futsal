/// Matches FastAPI `LoyaltyAccountResponse`
class LoyaltyAccount {
  final int pointsBalance;
  final int totalEarned;
  final int totalRedeemed;

  const LoyaltyAccount({
    required this.pointsBalance,
    required this.totalEarned,
    required this.totalRedeemed,
  });

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccount(
      pointsBalance: (json['points_balance'] as int?) ?? 0,
      totalEarned: (json['total_earned'] as int?) ?? 0,
      totalRedeemed: (json['total_redeemed'] as int?) ?? 0,
    );
  }
}

/// Matches FastAPI `LoyaltyTransactionResponse`
class LoyaltyTransaction {
  final int id;
  final String transactionType; // earned | redeemed
  final int points;
  final String description;

  const LoyaltyTransaction({
    required this.id,
    required this.transactionType,
    required this.points,
    required this.description,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] as int,
      transactionType: json['transaction_type'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}
