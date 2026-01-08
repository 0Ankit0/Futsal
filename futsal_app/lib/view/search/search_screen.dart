import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_bloc.dart';
import 'package:ui/view/home/bloc/all_futsal/all_futsal_state.dart';
import '../../core/dimension.dart';
import '../futsal/futsal_details.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<dynamic> _filterFutsals(List<dynamic> futsals) {
    if (_searchQuery.isEmpty)
      return []; // Don't show results if query is empty (or show all? user said "results in box below")
    // Usually empty query implies "Recent searches" or "Suggestions". For now, let's show matching or empty.

    return futsals.where((futsal) {
      final name = (futsal.name ?? '').toLowerCase();
      final location = (futsal.location ?? '').toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Dimension.width(20),
        vertical: Dimension.height(15),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, size: Dimension.font(20)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          SizedBox(width: Dimension.width(15)),
          Expanded(
            child: Container(
              height: Dimension.height(45),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(Dimension.width(12)),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Search courts, location...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: Dimension.font(14),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).primaryColor,
                    size: Dimension.font(20),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: Dimension.font(18)),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Dimension.width(15),
                    vertical: Dimension.height(11),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<AllFutsalBloc, AllFutsalState>(
      builder: (context, state) {
        if (state is AllFutsalLoaded) {
          final futsals = _filterFutsals(state.futsals);

          if (_searchQuery.isNotEmpty && futsals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: Dimension.font(60),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: Dimension.height(20)),
                  Text(
                    'No courts found',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: Dimension.font(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (_searchQuery.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: Dimension.font(60),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: Dimension.height(20)),
                  Text(
                    'Search for your favorite courts',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: Dimension.font(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: Dimension.width(20),
              vertical: Dimension.height(20),
            ),
            itemCount: futsals.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: Dimension.height(15)),
            itemBuilder: (context, index) {
              final court = futsals[index].toMap();
              return _SearchCourtCard(court: court);
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _SearchCourtCard extends StatelessWidget {
  final Map<String, dynamic> court;
  const _SearchCourtCard({required this.court});

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
                width: Dimension.width(80),
                height: Dimension.height(80),
                child: court['imageUrl'] != null
                    ? Image.network(court['imageUrl'], fit: BoxFit.cover)
                    : Container(color: Colors.grey[200]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(12),
                  vertical: Dimension.width(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    SizedBox(height: Dimension.height(4)),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: Dimension.font(12),
                          color: Colors.grey,
                        ),
                        SizedBox(width: Dimension.width(4)),
                        Expanded(
                          child: Text(
                            court['location'] ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: Dimension.font(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: Dimension.width(15)),
              child: Icon(
                Icons.arrow_forward_ios,
                size: Dimension.font(14),
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
