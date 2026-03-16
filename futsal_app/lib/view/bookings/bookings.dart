import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/core/simple_theme.dart';
import '../../core/dimension.dart';
import '../../core/service/notification_service.dart';
import 'bloc/bookings_bloc.dart';
import 'data/repository/booking_repository.dart';
import 'data/model/booking.dart';
import 'widgets/review_dialog.dart';
import '../reviews/data/repository/reviews_repository.dart';
import '../reviews/data/model/review_request.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return BlocProvider(
      create: (_) =>
          BookingsBloc(bookingRepository: BookingRepository())
            ..add(const LoadBookings()),
      child: BlocListener<BookingsBloc, BookingsState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.infoMessage != current.infoMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }

          if (state.infoMessage != null) {
            if (state.lastActionType == BookingActionType.cancelled &&
                state.actionBooking != null) {
              NotificationService().showBookingCancelled(
                groundName: state.actionBooking!.groundName,
                bookingDate: _prettyDate(state.actionBooking!.bookingDate),
              );
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.infoMessage!)),
            );
          }
        },
        child: Scaffold(
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
                        'My Bookings',
                        style: TextStyle(
                          fontSize: Dimension.font(20),
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  controller: _tabController,
                  splashBorderRadius: null,
                  splashFactory: null,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.symmetric(
                    horizontal: Dimension.width(10),
                  ),
                  tabs: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: Dimension.height(15),
                      ),
                      child: Text('Upcoming'),
                    ),
                    Text('Completed'),
                    Text('Cancelled'),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: Dimension.height(8)),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingList(0),
                      _buildBookingList(1),
                      _buildBookingList(2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildBookingList(int statusFilter) {
    return BlocBuilder<BookingsBloc, BookingsState>(
      builder: (context, state) {
        if (state.isLoading && state.bookings.isEmpty) {
          return _LoadingList();
        }

        if (state.errorMessage != null && state.bookings.isEmpty) {
          return _ErrorView(
            message: state.errorMessage!,
            onRetry: () => context.read<BookingsBloc>().add(const LoadBookings()),
          );
        }

        final now = DateTime.now();
        List<Booking> filtered;

        if (statusFilter == 0) {
          filtered = state.bookings
              .where(
                (b) =>
                    (b.bookingDate.isAfter(now) || _sameDay(b.bookingDate, now)) &&
                    (b.status == 0 || b.status == 1),
              )
              .toList();
        } else if (statusFilter == 1) {
          filtered = state.bookings.where((b) => b.status == 3).toList();
        } else {
          filtered = state.bookings.where((b) => b.status == 2).toList();
        }

        filtered.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

        if (filtered.isEmpty) {
          return _EmptyView(
            statusFilter: statusFilter,
            onRefresh: () => context.read<BookingsBloc>().add(const LoadBookings()),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<BookingsBloc>().add(const LoadBookings());
          },
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              Dimension.width(16),
              Dimension.height(12),
              Dimension.width(16),
              Dimension.height(24),
            ),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(height: Dimension.height(12)),
            itemBuilder: (context, i) {
              final booking = filtered[i];
              return _BookingCard(
                booking: booking,
                isUpcoming: statusFilter == 0,
                isProcessing: state.processingBookingId == booking.id,
                onCancel: () => context.read<BookingsBloc>().add(
                  CancelBookingRequested(booking),
                ),
              );
            },
          ),
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _BookingCard extends StatefulWidget {
  final Booking booking;
  final bool isUpcoming;
  final bool isProcessing;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    this.isUpcoming = false,
    required this.isProcessing,
    required this.onCancel,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  final _reviewRepo = ReviewsRepository();

  @override
  Widget build(BuildContext context) {
    String _formatRange() {
      String start = _friendlyTime(widget.booking.startTime);
      String end = _friendlyTime(widget.booking.endTime);
      return '$start - $end';
    }

    return Container(
      padding: EdgeInsets.all(Dimension.width(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimension.width(16)),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.booking.groundName.isEmpty
                          ? 'Ground'
                          : widget.booking.groundName,
                      style: TextStyle(
                        fontSize: Dimension.font(18),
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: Dimension.height(4)),
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/booking.png',
                          width: Dimension.width(10),
                          height: Dimension.width(10),
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        SizedBox(width: Dimension.width(6)),
                        Text(
                          _prettyDate(widget.booking.bookingDate),
                          style: TextStyle(
                            fontSize: Dimension.font(12),
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Image.asset(
                'assets/icons/clock.png',
                width: Dimension.width(10),
                height: Dimension.width(10),
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              ),
              SizedBox(width: Dimension.width(6)),
              Expanded(
                child: Text(
                  _formatRange(),
                  style: TextStyle(
                    fontSize: Dimension.font(12),
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimension.height(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Total: ',
                    style: TextStyle(
                      fontSize: Dimension.font(12),
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    ' Rs.${widget.booking.totalAmount.truncate()}',
                    style: TextStyle(
                      fontSize: Dimension.font(12),
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (widget.isUpcoming) ...[
                const Spacer(),
                ElevatedButton(
                  onPressed: widget.isProcessing
                      ? null
                      : () => _showCancelDialog(context, widget.booking),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      context.read<ThemeNotifier>().isDark
                          ? Colors.white24
                          : Colors.grey[300],
                    ),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(
                        horizontal: Dimension.width(12),
                        vertical: Dimension.height(0),
                      ),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimension.width(8)),
                      ),
                    ),
                  ),
                  child: widget.isProcessing
                      ? SizedBox(
                          width: Dimension.width(16),
                          height: Dimension.width(16),
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: Dimension.font(14),
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),
              ],
              if (!widget.isUpcoming &&
                  (widget.booking.status == 3 || widget.booking.status == 2)) ...[
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _showReviewDialog(context),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.primary,
                    ),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(
                        horizontal: Dimension.width(12),
                        vertical: Dimension.height(0),
                      ),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimension.width(8)),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: Dimension.width(16),
                        color: Colors.white,
                      ),
                      SizedBox(width: Dimension.width(4)),
                      Text(
                        'Review',
                        style: TextStyle(
                          fontSize: Dimension.font(14),
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ReviewDialog(
        groundId: widget.booking.groundId,
        groundName: widget.booking.groundName,
        onSubmit: (rating, comment) async {
          final reviewRequest = ReviewRequest(
            groundId: widget.booking.groundId,
            rating: rating,
            comment: comment,
          );
          await _reviewRepo.createReview(reviewRequest);
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimension.width(16)),
        ),
        title: Text(
          'Cancel Booking',
          style: TextStyle(
            fontSize: Dimension.font(18),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(
            fontSize: Dimension.font(14),
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'No',
              style: TextStyle(
                fontSize: Dimension.font(14),
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onCancel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimension.width(8)),
              ),
            ),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(
                fontSize: Dimension.font(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _prettyDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final m = months[d.month - 1];
  return '$m ${d.day}, ${d.year}';
}

String _friendlyTime(String raw) {
  final trimmed = raw.trim();

  final secMatch = RegExp(r'^(\d{2}):(\d{2}):(\d{2})$').firstMatch(trimmed);
  if (secMatch != null) {
    final h = int.parse(secMatch.group(1)!);
    final m = secMatch.group(2)!;
    final period = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:$m $period';
  }

  final noSecMatch = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(trimmed);
  if (noSecMatch != null) {
    final h = int.parse(noSecMatch.group(1)!);
    final m = noSecMatch.group(2)!;
    final period = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:$m $period';
  }

  final ampmMatch = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (ampmMatch != null) {
    final h = int.parse(ampmMatch.group(1)!);
    final m = ampmMatch.group(2)!;
    final period = ampmMatch.group(3)!.toUpperCase();
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:$m $period';
  }

  return trimmed;
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Dimension.width(16),
        Dimension.height(12),
        Dimension.width(16),
        Dimension.height(24),
      ),
      itemCount: 6,
      itemBuilder: (context, i) {
        return Container(
          margin: EdgeInsets.only(bottom: Dimension.height(12)),
          height: Dimension.height(110),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimension.width(16)),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimension.width(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: Dimension.width(32)),
            SizedBox(height: Dimension.height(8)),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: Dimension.height(12)),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final int statusFilter;
  final VoidCallback onRefresh;
  const _EmptyView({required this.statusFilter, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final text = statusFilter == 0
        ? 'No upcoming bookings.'
        : statusFilter == 1
        ? 'No completed bookings.'
        : 'No cancelled bookings.';

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimension.width(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: Dimension.width(32)),
            SizedBox(height: Dimension.height(8)),
            Text(text, textAlign: TextAlign.center),
            SizedBox(height: Dimension.height(12)),
            ElevatedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }
}
