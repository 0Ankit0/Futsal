/// Matches FastAPI `GroundResponse` schema from `/api/v1/futsal/grounds`
class FutsalModel {
  final int id;
  final String name;
  final String slug;
  final int ownerId;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String groundType; // outdoor, indoor, etc.
  final double pricePerHour;
  final double? weekendPricePerHour;
  final String openTime; // HH:mm:ss
  final String closeTime;
  final int slotDurationMinutes;
  final bool isActive;
  final bool isVerified;
  final double averageRating;
  final int ratingCount;
  final Map<String, dynamic>? amenities;

  FutsalModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerId,
    required this.location,
    this.latitude,
    this.longitude,
    this.description,
    required this.groundType,
    required this.pricePerHour,
    this.weekendPricePerHour,
    required this.openTime,
    required this.closeTime,
    required this.slotDurationMinutes,
    required this.isActive,
    required this.isVerified,
    required this.averageRating,
    required this.ratingCount,
    this.amenities,
  });

  factory FutsalModel.fromJson(Map<String, dynamic> json) {
    return FutsalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: (json['slug'] as String?) ?? '',
      ownerId: (json['owner_id'] as int?) ?? 0,
      location: (json['location'] as String?) ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      description: json['description'] as String?,
      groundType: (json['ground_type'] as String?) ?? 'outdoor',
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      weekendPricePerHour: json['weekend_price_per_hour'] != null
          ? (json['weekend_price_per_hour'] as num).toDouble()
          : null,
      openTime: (json['open_time'] as String?) ?? '06:00:00',
      closeTime: (json['close_time'] as String?) ?? '22:00:00',
      slotDurationMinutes: (json['slot_duration_minutes'] as int?) ?? 60,
      isActive: (json['is_active'] as bool?) ?? true,
      isVerified: (json['is_verified'] as bool?) ?? false,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : 0.0,
      ratingCount: (json['rating_count'] as int?) ?? 0,
      amenities: json['amenities'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'owner_id': ownerId,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'ground_type': groundType,
      'price_per_hour': pricePerHour,
      'weekend_price_per_hour': weekendPricePerHour,
      'open_time': openTime,
      'close_time': closeTime,
      'slot_duration_minutes': slotDurationMinutes,
      'is_active': isActive,
      'is_verified': isVerified,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'amenities': amenities,
    };
  }

  /// Alias used by UI screens that navigate via Map<String, dynamic>.
  Map<String, dynamic> toMap() => toJson();
}

/// Matches FastAPI `SlotResponse` schema from `/api/v1/futsal/grounds/{id}/slots`
class SlotModel {
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final bool isLocked;
  final double price;

  SlotModel({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.isLocked,
    required this.price,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: (json['is_available'] as bool?) ?? true,
      isLocked: (json['is_locked'] as bool?) ?? false,
      price: (json['price'] as num).toDouble(),
    );
  }
}
