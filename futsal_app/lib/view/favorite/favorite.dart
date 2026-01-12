import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/dimension.dart';
import '../futsal/futsal_details.dart';
// removed BookNow import; favorite cards no longer have Book Now button
import 'bloc/favorite_bloc.dart';
import 'bloc/favorite_event.dart';
import 'bloc/favorite_state.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  Future<void> _onRefresh() async {
    context.read<FavoriteBloc>().add(const LoadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(Dimension.height(70)),
        child: Container(
          width: double.infinity,

          padding: EdgeInsets.symmetric(
            horizontal: Dimension.width(20),
            vertical: Dimension.height(20),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: Dimension.height(25)),
              Row(
                children: [
                  Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: Dimension.font(20),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  BlocBuilder<FavoriteBloc, FavoriteState>(
                    builder: (context, state) {
                      if (state is FavoriteLoaded ||
                          state is FavoriteActionSuccess) {
                        final count = state is FavoriteLoaded
                            ? state.favorites.length
                            : (state as FavoriteActionSuccess).favorites.length;
                        return Text(
                          ' ($count)',
                          style: TextStyle(
                            fontSize: Dimension.font(20),
                            fontWeight: FontWeight.w400,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Dimension.height(0)),
          // Favorites List with BLoC
          Expanded(
            child: BlocBuilder<FavoriteBloc, FavoriteState>(
              builder: (context, state) {
                if (state is FavoriteLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C853),
                      ),
                    ),
                  );
                } else if (state is FavoriteError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: Dimension.width(64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: Dimension.height(16)),
                        Text(
                          'Failed to load favorites',
                          style: TextStyle(
                            fontSize: Dimension.font(16),
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: Dimension.height(8)),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: Dimension.font(13),
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Dimension.height(16)),
                        ElevatedButton(
                          onPressed: _onRefresh,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is FavoriteLoaded ||
                    state is FavoriteActionSuccess) {
                  final favorites = state is FavoriteLoaded
                      ? state.favorites
                      : (state as FavoriteActionSuccess).favorites;

                  if (favorites.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: const Color(0xFF00C853),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: Dimension.width(64),
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: Dimension.height(16)),
                                Text(
                                  'No favorites yet',
                                  style: TextStyle(
                                    fontSize: Dimension.font(16),
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: Dimension.height(8)),
                                Text(
                                  'Pull down to refresh',
                                  style: TextStyle(
                                    fontSize: Dimension.font(13),
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: const Color(0xFF00C853),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimension.width(20),
                        vertical: Dimension.height(010),
                      ),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final futsal = favorites[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: Dimension.height(5)),
                          child: _FavoriteCard(court: futsal.toMap()),
                        );
                      },
                    ),
                  );
                }

                // Initial state
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: const Color(0xFF00C853),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: Dimension.width(64),
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: Dimension.height(16)),
                            Text(
                              'Pull down to load favorites',
                              style: TextStyle(
                                fontSize: Dimension.font(16),
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> court;
  const _FavoriteCard({required this.court});

  @override
  Widget build(BuildContext context) {
    final outlineColor = Theme.of(context).colorScheme.outline.withOpacity(0.5);
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FutsalDetails(futsalData: court),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: Dimension.height(12)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(Dimension.width(8)),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                blurRadius: Dimension.width(12),
                offset: Offset(0, Dimension.height(4)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Court Image (larger) with subtle border and price overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Dimension.width(8)),
                    topRight: Radius.circular(Dimension.width(8)),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Dimension.width(8)),
                    topRight: Radius.circular(Dimension.width(8)),
                  ),
                  child: SizedBox(
                    height: Dimension.height(160),
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (court['imageUrl'] != null)
                          Image.network(court['imageUrl'], fit: BoxFit.cover)
                        else
                          Container(color: Colors.grey[200]),

                        // favorite badge at top-right of the image
                        Positioned(
                          right: Dimension.width(10),
                          top: Dimension.height(10),
                          child: Container(
                            padding: EdgeInsets.all(Dimension.width(4)),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                              size: Dimension.width(20),
                            ),
                          ),
                        ),

                        // Price badge at bottom-left of the image
                        Positioned(
                          left: Dimension.width(10),
                          bottom: Dimension.height(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimension.width(8),
                              vertical: Dimension.height(6),
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(
                                Dimension.width(6),
                              ),
                            ),
                            child: Text(
                              'Rs ${court['pricePerHour']}/hr',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: Dimension.font(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Court Details
              Padding(
                padding: EdgeInsets.all(Dimension.width(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Court Name
                    Text(
                      court['name'] ?? 'Court Name',
                      style: TextStyle(
                        fontSize: Dimension.font(15),
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Dimension.height(6)),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: Dimension.width(14),
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: Dimension.width(4)),
                        Text(
                          court['location'] ?? 'Location',
                          style: TextStyle(
                            fontSize: Dimension.font(12),
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          court['distanceKm'] != null
                              ? '  ${court['distanceKm']} km'
                              : '  --- km',
                          style: TextStyle(
                            fontSize: Dimension.font(12),
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    SizedBox(height: Dimension.height(8)),

                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: Dimension.width(15),
                          color: const Color(0xFFFFA500),
                        ),
                        SizedBox(width: Dimension.width(4)),
                        Text(
                          court['averageRating']?.toString() ?? '0.0',
                          style: TextStyle(
                            fontSize: Dimension.font(12),
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        Text(
                          ' (${court['ratingCount']?.toString()} reviews)',
                          style: TextStyle(
                            fontSize: Dimension.font(10),
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Dimension.height(10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
