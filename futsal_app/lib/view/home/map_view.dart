import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:ui/core/dimension.dart';
import 'package:ui/view/book_now/book_now.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_bloc.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_event.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_state.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Map<String, dynamic>? _selectedFutsal;
  final MapController _mapController = MapController();
  Future<Position>? _locationFuture;

  @override
  void initState() {
    super.initState();
    // Load all futsals when the map view is initialized
    context.read<AllFutsalBloc>().add(const LoadAllFutsals());
    _locationFuture = _determinePosition();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _recenterMap() async {
    try {
      final position = await _determinePosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openDirections(double destLat, double destLng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _recenterMap,
        child: const Icon(Icons.my_location),
      ),
      body: FutureBuilder<Position>(
        future: _locationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final currentPosition = snapshot.data!;
            return BlocBuilder<AllFutsalBloc, AllFutsalState>(
              builder: (context, state) {
                if (state is AllFutsalLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C853),
                      ),
                    ),
                  );
                } else if (state is AllFutsalError) {
                  return Center(child: Text('Error: ${state.message}'));
                } else if (state is AllFutsalLoaded) {
                  final futsals = state.futsals;
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            currentPosition.latitude,
                            currentPosition.longitude,
                          ),
                          initialZoom: 15,
                          minZoom: 10,
                          onTap: (_, __) {
                            setState(() {
                              _selectedFutsal = null;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.futsal_app',
                          ),
                          MarkerLayer(
                            markers: [
                              ...futsals.map((futsal) {
                                final latitude = futsal.latitude;
                                final longitude = futsal.longitude;
                                return Marker(
                                  point: LatLng(latitude, longitude),
                                  width: 120,
                                  height: 64,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFutsal = futsal.toMap();
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            futsal.name,
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
                                );
                              }).toList(),
                              Marker(
                                point: LatLng(
                                  currentPosition.latitude,
                                  currentPosition.longitude,
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_selectedFutsal != null)
                        _buildFutsalDetailsSheet(_selectedFutsal!),
                    ],
                  );
                }
                return const Center(child: Text('No futsals found.'));
              },
            );
          }
          return const Center(child: Text('Getting location...'));
        },
      ),
    );
  }

  Widget _buildFutsalDetailsSheet(Map<String, dynamic> futsalData) {
    final name = futsalData['name'] ?? '';
    final latitude = futsalData['latitude'] ?? 0.0;
    final longitude = futsalData['longitude'] ?? 0.0;
    final description = futsalData['description'] ?? '';
    final rating = futsalData['averageRating']?.toString() ?? '0.0';
    final reviews = futsalData['ratingCount']?.toString() ?? '0';

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.2,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.outline.withAlpha(90),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: Dimension.height(16)),
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
                        const Icon(Icons.star, color: Colors.orange, size: 20),
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
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BookNow(futsalData: futsalData),
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
                    futsalData['imageUrl'] ??
                        'https://via.placeholder.com/400x200.png?text=No+Image',
                    width: double.infinity,
                    height: Dimension.height(200),
                    fit: BoxFit.cover,
                  ),
                  const Divider(),
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
                        ).colorScheme.onPrimary.withAlpha(180),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
