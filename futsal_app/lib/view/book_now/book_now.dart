import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/dimension.dart';
import '../../core/service/notification_service.dart';
import '../bookings/data/repository/booking_repository.dart';
import '../bookings/bookings.dart';
import '../profile/bloc/profile_bloc.dart';
import '../profile/bloc/profile_state.dart';

class BookNow extends StatefulWidget {
  final Map<String, dynamic> futsalData;

  const BookNow({super.key, required this.futsalData});

  @override
  State<BookNow> createState() => _BookNowState();
}

class _BookNowState extends State<BookNow> {
  final _bookingRepo = BookingRepository();
  int _selectedDateIndex = 0;
  String? _selectedTimeSlot;
  bool _showConfirmation = false;
  bool _isBooking = false;

  List<DateTime> _generateNext7Days() {
    final today = DateTime.now();
    return List.generate(7, (index) => today.add(Duration(days: index)));
  }

  List<String> _generateTimeSlots() {
    final openTime = widget.futsalData['openTime'] ?? '06:00 AM';
    final closeTime = widget.futsalData['closeTime'] ?? '10:00 PM';

    final openHour = _parseTime(openTime);
    final closeHour = _parseTime(closeTime);

    List<String> slots = [];
    for (int hour = openHour; hour < closeHour; hour++) {
      final startTime = _formatTimeSlot(hour);
      final endTime = _formatTimeSlot(hour + 1);
      slots.add('$startTime - $endTime');
    }
    return slots;
  }

  int _parseTime(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final isPM = time.toUpperCase().contains('PM');
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return hour;
    } catch (e) {
      return 6;
    }
  }

  String _formatTimeSlot(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:00 $period';
  }

  bool _isTimeSlotBooked(DateTime selectedDate, String timeSlot) {
    final bookedSlots = widget.futsalData['bookedTimeSlots'] as List? ?? [];
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    for (var slot in bookedSlots) {
      try {
        final bookingDate = DateTime.parse(slot['bookingDate']);
        final bookingDateStr = DateFormat('yyyy-MM-dd').format(bookingDate);

        if (bookingDateStr == selectedDateStr) {
          final bookedTime = '${slot['startTime']} - ${slot['endTime']}';
          if (bookedTime == timeSlot) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  bool _isTimeSlotPassed(DateTime selectedDate, String timeSlot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    // Only check for today's date
    if (selectedDay != today) {
      return false;
    }

    // Extract start time from time slot (e.g., "11:00 AM - 12:00 PM" -> "11:00 AM")
    final startTimeStr = timeSlot.split(' - ')[0];
    final startHour = _parseTime(startTimeStr);

    // Compare with current hour
    return startHour <= now.hour;
  }

  void _showConfirmationDialog() {
    if (_selectedTimeSlot == null) return;
    setState(() {
      _showConfirmation = true;
    });
  }

  void _confirmBooking() async {
    if (_isBooking) return;
    setState(() => _isBooking = true);

    try {
      final profileState = context.read<ProfileBloc>().state;
      if (profileState is! ProfileLoaded) {
        throw Exception('User profile not loaded');
      }

      final userId = profileState.userInfo.id;
      final groundId = widget.futsalData['_id'] ?? widget.futsalData['id'];
      final selectedDate = _generateNext7Days()[_selectedDateIndex];

      final bookingDate = DateTime.utc(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      final times = _selectedTimeSlot!.split(' - ');
      final startTime = _convertTo24HourFormat(times[0]);
      final endTime = _convertTo24HourFormat(times[1]);

      await _bookingRepo.createBooking(
        userId: userId,
        groundId: groundId is int
            ? groundId
            : int.tryParse(groundId.toString()) ?? 0,
        bookingDate: bookingDate,
        startTime: startTime,
        endTime: endTime,
      );

      if (!mounted) return;

      // Show notification
      NotificationService().showBookingConfirmed(
        groundName: widget.futsalData['name'] ?? 'Futsal Ground',
        bookingDate: DateFormat('MMM dd, yyyy').format(selectedDate),
        timeSlot: _selectedTimeSlot!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BookingsScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  String _convertTo24HourFormat(String time12h) {
    final parts = time12h.split(':');
    int hour = int.tryParse(parts[0].trim()) ?? 0;
    final minutePart = parts[1].split(' ');
    final minute = minutePart[0].trim();
    final period = minutePart.length > 1
        ? minutePart[1].trim().toUpperCase()
        : 'AM';

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  }

  void _showCustomBookingDialog(BuildContext context) {
    int selectedDuration = 1;
    String? selectedStartTime;
    final openTime = widget.futsalData['openTime'] ?? '06:00 AM';
    final closeTime = widget.futsalData['closeTime'] ?? '10:00 PM';
    final openHour = _parseTime(openTime);
    final closeHour = _parseTime(closeTime);

    // Get current hour if booking for today
    final selectedDate = _generateNext7Days()[_selectedDateIndex];
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final currentHour = isToday ? now.hour : -1;

    List<int> availableHours = [];
    for (int i = openHour; i < closeHour; i++) {
      // Only add hours that haven't passed if booking for today
      if (!isToday || i > currentHour) {
        availableHours.add(i);
      }
    }

    // Show message if no hours available
    if (availableHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No available time slots for today. All hours have passed.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Custom Booking"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isToday)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Only future time slots are available',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Text("Duration (Max 2 hours)"),
              Row(
                children: [
                  Radio<int>(
                    value: 1,
                    groupValue: selectedDuration,
                    onChanged: (val) =>
                        setStateDialog(() => selectedDuration = val!),
                  ),
                  const Text("1 Hour"),
                  const SizedBox(width: 15),
                  Radio<int>(
                    value: 2,
                    groupValue: selectedDuration,
                    onChanged: (val) =>
                        setStateDialog(() => selectedDuration = val!),
                  ),
                  const Text("2 Hours"),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Start Time"),
              DropdownButtonFormField<String>(
                value: selectedStartTime,
                items: availableHours.map((hour) {
                  return DropdownMenuItem(
                    value: hour.toString(),
                    child: Text(_formatTimeSlot(hour)),
                  );
                }).toList(),
                onChanged: (val) =>
                    setStateDialog(() => selectedStartTime = val),
                decoration: const InputDecoration(
                  hintText: 'Select start time',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedStartTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a start time'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                int startH = int.parse(selectedStartTime!);
                if (selectedDuration == 2 && (startH + 2) > closeHour) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Not enough time for 2-hour booking before closing',
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                String startStr = _formatTimeSlot(startH);
                String endStr = _formatTimeSlot(startH + selectedDuration);
                String customSlot = "$startStr - $endStr";

                setState(() => _selectedTimeSlot = customSlot);
                Navigator.pop(context);
              },
              child: const Text("Set Time"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    if (_showConfirmation)
      return _buildConfirmationScreen(_generateNext7Days()[_selectedDateIndex]);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Book Futsal'),
        leading: Padding(
          padding: EdgeInsets.all(Dimension.width(8)),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: Dimension.width(8),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
                size: Dimension.width(18),
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Dimension.isTablet ? 700 : double.infinity,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildDateSelection(),
                    _buildTimeSlotSelection(),
                    SizedBox(height: Dimension.height(100)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedTimeSlot != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(Dimension.width(16)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.futsalData['imageUrl'] ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Icon(Icons.sports_soccer),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.futsalData['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.futsalData['location'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Rs.${widget.futsalData['pricePerHour'] ?? 0}/hour',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    final dates = _generateNext7Days();
    return Container(
      padding: EdgeInsets.all(Dimension.width(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = index == _selectedDateIndex;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDateIndex = index;
                    _selectedTimeSlot = null;
                  }),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                        Text(
                          DateFormat('dd').format(date),
                          style: TextStyle(
                            fontSize: 24,
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildTimeSlotSelection() {
    final timeSlots = _generateTimeSlots();
    final selectedDate = _generateNext7Days()[_selectedDateIndex];
    return Container(
      padding: EdgeInsets.all(Dimension.width(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Time Slot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _showCustomBookingDialog(context),
                child: const Text("Custom"),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: timeSlots.map((slot) {
              final isBooked = _isTimeSlotBooked(selectedDate, slot);
              final isPassed = _isTimeSlotPassed(selectedDate, slot);
              final isSelected = slot == _selectedTimeSlot;
              final isDisabled = isBooked || isPassed;

              return GestureDetector(
                onTap: isDisabled
                    ? () {
                        // Show snackbar for disabled slots
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isPassed
                                  ? 'This time slot has already passed and cannot be booked'
                                  : 'This time slot is already booked',
                            ),
                            backgroundColor: isPassed
                                ? Colors.orange
                                : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : () => setState(() => _selectedTimeSlot = slot),
                child: Opacity(
                  opacity: isDisabled ? 0.5 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.red[50]
                          : isPassed
                          ? Colors.grey[200]
                          : isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      border: Border.all(
                        color: isBooked
                            ? Colors.red
                            : isPassed
                            ? Colors.grey
                            : Colors.grey.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        color: isBooked
                            ? Colors.red
                            : isPassed
                            ? Colors.grey[600]
                            : isSelected
                            ? Colors.white
                            : Colors.black,
                        decoration: isPassed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Dimension.isTablet ? 700 : double.infinity,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: Dimension.isTablet
                    ? Dimension.width(700 - 32)
                    : Dimension.deviceWidth - 32,
                height: 54,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  child: const Text('Continue'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationScreen(DateTime selectedDate) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        leading: Padding(
          padding: EdgeInsets.all(Dimension.width(8)),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: Dimension.width(8),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
                size: Dimension.width(18),
              ),
              onPressed: () => setState(() => _showConfirmation = false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Dimension.isTablet ? 600 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Review Your Booking',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoRow('Court', widget.futsalData['name'] ?? ''),
                    _buildInfoRow(
                      'Date',
                      DateFormat('EEEE, MMM dd').format(selectedDate),
                    ),
                    _buildInfoRow('Time', _selectedTimeSlot ?? ''),
                    _buildInfoRow(
                      'Total',
                      'Rs.${widget.futsalData['pricePerHour'] ?? 0}',
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Dimension.isTablet ? 600 : double.infinity,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: Dimension.isTablet
                      ? Dimension.width(600 - 32)
                      : Dimension.deviceWidth - 32,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _confirmBooking,
                    child: _isBooking
                        ? const CircularProgressIndicator()
                        : const Text('Confirm Booking'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
