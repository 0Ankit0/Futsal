class FutsalModel {
  final int id;
  final String name;
  final String location;
  final String ownerId;
  final int pricePerHour;
  final double averageRating;
  final int ratingCount;
  final double latitude;
  final double longitude;
  final String description;
  final int? imageId;
  final String imageUrl;
  final String openTime;
  final String closeTime;
  final DateTime createdAt;
  final int bookingCount;
  final String ownerName;
  final bool isFavorite;
  final double? distanceKm;
  final List<BookedTimeSlot> bookedTimeSlots;

  FutsalModel({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
    required this.pricePerHour,
    required this.averageRating,
    required this.ratingCount,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.imageId,
    required this.imageUrl,
    required this.openTime,
    required this.closeTime,
    required this.createdAt,
    required this.bookingCount,
    required this.ownerName,
    required this.isFavorite,
    this.distanceKm,
    required this.bookedTimeSlots,
  });

  factory FutsalModel.fromJson(Map<String, dynamic> json) {
    return FutsalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      ownerId: json['ownerId'] as String,
      pricePerHour: json['pricePerHour'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String,
      imageId: json['imageId'] as int?,
      imageUrl: json['imageUrl'] as String? ?? '',
      openTime: json['openTime'] as String,
      closeTime: json['closeTime'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      bookingCount: json['bookingCount'] as int,
      ownerName: json['ownerName'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      distanceKm: json['distanceKm'] != null
          ? (json['distanceKm'] as num).toDouble()
          : null,
      bookedTimeSlots:
          (json['bookedTimeSlots'] as List<dynamic>?)
              ?.map((e) => BookedTimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'ownerId': ownerId,
      'pricePerHour': pricePerHour,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'imageId': imageId,
      'imageUrl': imageUrl,
      'openTime': openTime,
      'closeTime': closeTime,
      'createdAt': createdAt.toIso8601String(),
      'bookingCount': bookingCount,
      'ownerName': ownerName,
      'isFavorite': isFavorite,
      'distanceKm': distanceKm,
      'bookedTimeSlots': bookedTimeSlots.map((e) => e.toJson()).toList(),
    };
  }

  // Convert to Map for compatibility with existing UI
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'ownerId': ownerId,
      'pricePerHour': pricePerHour,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'imageId': imageId,
      'imageUrl': imageUrl,
      'openTime': openTime,
      'closeTime': closeTime,
      'createdAt': createdAt.toIso8601String(),
      'bookingCount': bookingCount,
      'ownerName': ownerName,
      'isFavorite': isFavorite,
      'distanceKm': distanceKm,
      'bookedTimeSlots': bookedTimeSlots
          .map(
            (e) => {
              'bookingDate': e.bookingDate.toIso8601String(),
              'startTime': e.startTime,
              'endTime': e.endTime,
            },
          )
          .toList(),
    };
  }
}

class BookedTimeSlot {
  final DateTime bookingDate;
  final String startTime;
  final String endTime;

  BookedTimeSlot({
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
  });

  factory BookedTimeSlot.fromJson(Map<String, dynamic> json) {
    return BookedTimeSlot(
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingDate': bookingDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
