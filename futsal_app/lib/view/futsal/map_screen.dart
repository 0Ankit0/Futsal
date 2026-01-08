import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ui/core/dimension.dart';
import 'package:ui/view/book_now/book_now.dart';

class FutsalMapScreen extends StatefulWidget {
  final Map<String, dynamic> futsalData;

  const FutsalMapScreen({super.key, required this.futsalData});

  @override
  State<FutsalMapScreen> createState() => _FutsalMapScreenState();
}

class _FutsalMapScreenState extends State<FutsalMapScreen> {
  bool _showSheet = false;

  Future<void> _openDirections(double destLat, double destLng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.futsalData['name'] ?? '';
    final latitude = widget.futsalData['latitude'] ?? 0.0;
    final longitude = widget.futsalData['longitude'] ?? 0.0;
    final description = widget.futsalData['description'] ?? '';
    final rating = widget.futsalData['averageRating']?.toString() ?? '0.0';
    final reviews = widget.futsalData['ratingCount']?.toString() ?? '0';

    return Scaffold(
      appBar: AppBar(title: Text(name.isNotEmpty ? name : 'Futsal Location')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 16,
              onTap: (_, __) {
                setState(() {
                  _showSheet = false;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.futsal_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    width: 120,
                    height: 64,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showSheet = true;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_showSheet)
            DraggableScrollableSheet(
              initialChildSize: 0.19,
              minChildSize: 0.15,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: Dimension.height(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimension.width(16),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: Dimension.font(20),
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: Dimension.height(4)),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimension.width(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text('$rating ($reviews reviews)'),
                              ],
                            ),
                          ),
                          SizedBox(height: Dimension.height(4)),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimension.width(16),
                            ),
                            child: Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ButtonStyle(
                                    splashFactory: null,
                                    backgroundColor: WidgetStateProperty.all(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  onPressed: () {
                                    _openDirections(latitude, longitude);
                                  },
                                  icon: const Icon(
                                    Icons.directions,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Direction',
                                    style: TextStyle(
                                      fontSize: Dimension.font(14),
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ButtonStyle(
                                    splashFactory: null,
                                    backgroundColor: WidgetStateProperty.all(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookNow(
                                          futsalData: widget.futsalData,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Book Now',
                                    style: TextStyle(
                                      fontSize: Dimension.font(14),
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Image.network(
                            widget.futsalData['imageUrl'] ??
                                'https://via.placeholder.com/400x200.png?text=No+Image',
                            width: double.infinity,
                            height: Dimension.height(200),
                            fit: BoxFit.cover,
                          ),
                          Divider(),
                          // Expanded details
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimension.width(16),
                            ),
                            child: Text(
                              'Description',
                              style: TextStyle(
                                fontSize: Dimension.font(18),
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimension.width(16),
                            ),
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: Dimension.font(14),
                                fontWeight: FontWeight.w400,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Add more details as needed
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
