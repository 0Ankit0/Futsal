import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/view/bookings/bookings.dart';
import 'package:ui/view/favorite/favorite.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_bloc.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_event.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_state.dart';
import 'package:ui/view/home/bloc/trending_futsal/trending_futsal_bloc.dart';
import 'package:ui/view/home/bloc/trending_futsal/trending_futsal_event.dart';
import 'package:ui/view/home/bloc/trending_futsal/trending_futsal_state.dart';
import 'package:ui/view/reviews/reviews.dart';
import '../../core/dimension.dart';
import '../../core/service/notification_service.dart';
import '../futsal/futsal_details.dart';
import '../notifications/notifications_screen.dart';

import 'package:ui/view/search/search_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isGridView = false;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _updateNotificationCount();

    // Listen to notification changes
    NotificationService().addListener(_updateNotificationCount);
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGridView = prefs.getBool('isGridView') ?? false;
      });
    }
  }

  void _updateNotificationCount() {
    if (mounted) {
      setState(() {
        _unreadNotificationCount = NotificationService().unreadCount;
      });
    }
  }

  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool('isGridView', _isGridView);
  }

  @override
  void dispose() {
    NotificationService().removeListener(_updateNotificationCount);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<AllFutsalBloc>().add(const LoadAllFutsals());
    context.read<TrendingFutsalBloc>().add(const LoadTrendingFutsals());
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF00C853),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            _buildSpacing(Dimension.height(20)),

            // Trending Section
            _buildSectionHeader('Trending Now', 'Hot courts this week'),
            _buildTrendingSection(),
            _buildSpacing(Dimension.height(25)),

            // Quick Access Panel
            _buildSectionHeader('Quick Access', 'Manage your activities'),
            _buildQuickAccessPanel(),
            _buildSpacing(Dimension.height(25)),

            // All Grounds Section
            _buildSectionHeader(
              'All Courts',
              'Find your perfect pitch',
              action: IconButton(
                onPressed: _toggleView,
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  size: Dimension.font(20),
                  color: Colors.grey[700],
                ),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            _buildAllFutsalsList(),
            _buildSpacing(Dimension.height(20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: Dimension.height(120),
      // Floating and snap make the app bar appear immediately on scroll up
      floating: true,
      snap: true,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      surfaceTintColor: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(Dimension.width(20)),
          bottomRight: Radius.circular(Dimension.width(20)),
        ),
      ),
      // Put Search Bar in 'bottom' so it remains pinned when scrolled
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(Dimension.height(60)),
        child: Container(
          padding: EdgeInsets.only(
            left: Dimension.width(20),
            right: Dimension.width(20),
            bottom: Dimension.height(15),
          ),
          child: _buildSearchBar(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(Dimension.width(20)),
              bottomRight: Radius.circular(Dimension.width(20)),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Dimension.width(20),
              vertical: Dimension.height(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only Greeting here
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: Dimension.font(12),
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          'Lets Play!',
                          style: TextStyle(
                            fontSize: Dimension.font(20),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: Dimension.width(18),
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: Dimension.font(20),
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: EdgeInsets.all(Dimension.width(4)),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: Dimension.width(16),
                                  minHeight: Dimension.width(16),
                                ),
                                child: Text(
                                  _unreadNotificationCount > 9
                                      ? '9+'
                                      : _unreadNotificationCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: Dimension.font(10),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimension.height(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        height: Dimension.height(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimension.width(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: Dimension.width(15)),
            Icon(Icons.search, color: Colors.grey, size: Dimension.font(20)),
            SizedBox(width: Dimension.width(10)),
            Text(
              'Search courts...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: Dimension.font(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, {Widget? action}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimension.width(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Dimension.font(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Dimension.height(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: Dimension.font(11),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: Dimension.height(10)),
              ],
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: Dimension.height(200),
        child: BlocBuilder<TrendingFutsalBloc, TrendingFutsalState>(
          builder: (context, state) {
            if (state is TrendingFutsalLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TrendingFutsalLoaded) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: Dimension.width(20)),
                itemCount: state.futsals.length,
                itemBuilder: (context, index) {
                  return _TrendingCard(court: state.futsals[index].toMap());
                },
              );
            }
            return const Center(child: Text("No trending courts"));
          },
        ),
      ),
    );
  }

  Widget _buildQuickAccessPanel() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimension.width(20)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingsScreen(),
                    ),
                  );
                },
                child: _QuickAccessItem(
                  icon: Icons.calendar_today,
                  label: 'Bookings',
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(width: Dimension.width(Dimension.isTablet ? 60 : 30)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Favorite()),
                  );
                },
                child: _QuickAccessItem(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(width: Dimension.width(Dimension.isTablet ? 60 : 30)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Reviews()),
                  );
                },
                child: _QuickAccessItem(
                  icon: Icons.star,
                  label: 'Reviews',
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllFutsalsList() {
    return BlocBuilder<AllFutsalBloc, AllFutsalState>(
      builder: (context, state) {
        if (state is AllFutsalLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is AllFutsalLoaded) {
          final futsals = state.futsals;
          if (futsals.isEmpty) {
            return const SliverFillRemaining(
              child: Center(child: Text('No courts found')),
            );
          }

          if (_isGridView) {
            int columns = Dimension.isLargeTablet
                ? 4
                : (Dimension.isTablet ? 3 : 2);
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: Dimension.width(20)),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 0.75, // Adjust as needed
                  crossAxisSpacing: Dimension.width(15),
                  mainAxisSpacing: Dimension.width(15),
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _GridCourtCard(court: futsals[index].toMap());
                }, childCount: futsals.length),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Dimension.isTablet ? 700 : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimension.width(20),
                      vertical: Dimension.height(10),
                    ),
                    child: _CourtCard(court: futsals[index].toMap()),
                  ),
                ),
              );
            }, childCount: futsals.length),
          );
        }
        return const SliverFillRemaining(
          child: Center(child: Text('Failed to load courts')),
        );
      },
    );
  }

  Widget _buildSpacing(double height) {
    return SliverToBoxAdapter(child: SizedBox(height: height));
  }
}

class _TrendingCard extends StatelessWidget {
  final Map<String, dynamic> court;
  const _TrendingCard({required this.court});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FutsalDetails(futsalData: court),
          ),
        );
      },
      child: Container(
        width: Dimension.isTablet ? Dimension.width(250) : Dimension.width(200),
        margin: EdgeInsets.only(right: Dimension.width(12)),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimension.width(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(Dimension.width(12)),
                ),
                child: court['imageUrl'] != null
                    ? Image.network(
                        court['imageUrl'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(Dimension.width(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court['name'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimension.font(14),
                    ),
                  ),
                  SizedBox(height: Dimension.height(2)),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: Dimension.font(12),
                        color: Colors.grey,
                      ),
                      SizedBox(width: Dimension.width(2)),
                      Expanded(
                        child: Text(
                          court['location'] ?? 'Unknown location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: Dimension.font(11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Dimension.width(12)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: Dimension.width(24)),
        ),
        SizedBox(height: Dimension.height(8)),
        Text(
          label,
          style: TextStyle(
            fontSize: Dimension.font(12),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CourtCard extends StatelessWidget {
  final Map<String, dynamic> court;
  const _CourtCard({required this.court});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FutsalDetails(futsalData: court),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimension.width(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimension.width(12)),
                bottomLeft: Radius.circular(Dimension.width(12)),
              ),
              child: SizedBox(
                width: Dimension.width(100),
                height: Dimension.height(100),
                child: court['imageUrl'] != null
                    ? Image.network(court['imageUrl'], fit: BoxFit.cover)
                    : Container(color: Colors.grey[200]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Dimension.width(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            court['name'] ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Dimension.font(14),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimension.width(6),
                            vertical: Dimension.height(3),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              Dimension.width(6),
                            ),
                          ),
                          child: Text(
                            'Rs ${court['pricePerHour']}',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: Dimension.font(11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimension.height(4)),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: Dimension.font(12),
                          color: Colors.grey,
                        ),
                        SizedBox(width: Dimension.width(2)),
                        Expanded(
                          child: Text(
                            court['location'] ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: Dimension.font(11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimension.height(4)),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: Dimension.font(14),
                          color: Colors.amber,
                        ),
                        SizedBox(width: Dimension.width(2)),
                        Text(
                          '${court['averageRating'] ?? 4.5}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Dimension.font(11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCourtCard extends StatelessWidget {
  final Map<String, dynamic> court;
  const _GridCourtCard({required this.court});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FutsalDetails(futsalData: court),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimension.width(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(Dimension.width(12)),
                      ),
                      child: court['imageUrl'] != null
                          ? Image.network(
                              court['imageUrl'],
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(color: Colors.grey[200]),
                    ),
                  ),
                  Positioned(
                    top: Dimension.height(8),
                    right: Dimension.width(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimension.width(6),
                        vertical: Dimension.height(2),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Dimension.width(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: Dimension.font(12),
                            color: Colors.amber,
                          ),
                          SizedBox(width: Dimension.width(2)),
                          Text(
                            '${court['averageRating'] ?? 4.5}',
                            style: TextStyle(
                              fontSize: Dimension.font(10),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(Dimension.width(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court['name'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimension.font(14),
                    ),
                  ),
                  SizedBox(height: Dimension.height(2)),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: Dimension.font(12),
                        color: Colors.grey,
                      ),
                      SizedBox(width: Dimension.width(2)),
                      Expanded(
                        child: Text(
                          court['location'] ?? 'Unknown location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: Dimension.font(11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimension.height(4)),
                  Text(
                    'Rs ${court['pricePerHour'] ?? 0}/hr',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: Dimension.font(12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
