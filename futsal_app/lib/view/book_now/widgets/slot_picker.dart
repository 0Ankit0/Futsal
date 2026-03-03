import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/dimension.dart';
import '../../home/data/model/futsal_model.dart';
import '../../home/data/repository/futsal_repository.dart';

/// Slot picker widget: shows a date selector and available time slots for a ground.
/// Calls back with (startTime, endTime, price) when a slot is tapped.
class SlotPicker extends StatefulWidget {
  final int groundId;
  final void Function(String startTime, String endTime, double price)? onSlotSelected;

  const SlotPicker({
    super.key,
    required this.groundId,
    this.onSlotSelected,
  });

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  final _repo = FutsalRepository();
  DateTime _selectedDate = DateTime.now();
  List<SlotModel> _slots = [];
  bool _loading = false;
  String? _error;
  String? _selectedStart;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedStart = null;
    });
    try {
      final slots = await _repo.getGroundSlots(widget.groundId, _selectedDate);
      if (mounted) {
        setState(() {
          _slots = slots;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      await _loadSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date selector
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(Dimension.width(12)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimension.width(16),
              vertical: Dimension.height(12),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(Dimension.width(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, color: AppTheme.primary, size: Dimension.width(18)),
                SizedBox(width: Dimension.width(8)),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: Dimension.font(14),
                  ),
                ),
                SizedBox(width: Dimension.width(6)),
                Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: Dimension.width(20)),
              ],
            ),
          ),
        ),
        SizedBox(height: Dimension.height(16)),
        // Slots
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Text('Failed to load slots: $_error',
              style: TextStyle(color: Colors.red, fontSize: Dimension.font(13)))
        else if (_slots.isEmpty)
          Text('No slots available for this date.',
              style: TextStyle(color: Colors.grey, fontSize: Dimension.font(14)))
        else
          Wrap(
            spacing: Dimension.width(8),
            runSpacing: Dimension.height(8),
            children: _slots.map((slot) {
              final isSelected = _selectedStart == slot.startTime;
              final isUnavailable = !slot.isAvailable || slot.isLocked;
              return GestureDetector(
                onTap: isUnavailable
                    ? null
                    : () {
                        setState(() => _selectedStart = slot.startTime);
                        widget.onSlotSelected
                            ?.call(slot.startTime, slot.endTime, slot.price);
                      },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimension.width(14),
                    vertical: Dimension.height(10),
                  ),
                  decoration: BoxDecoration(
                    color: isUnavailable
                        ? Colors.grey[200]
                        : isSelected
                            ? AppTheme.primary
                            : Colors.white,
                    border: Border.all(
                      color: isUnavailable
                          ? Colors.grey[300]!
                          : isSelected
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(Dimension.width(8)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${slot.startTime.substring(0, 5)} - ${slot.endTime.substring(0, 5)}',
                        style: TextStyle(
                          fontSize: Dimension.font(13),
                          fontWeight: FontWeight.w600,
                          color: isUnavailable
                              ? Colors.grey
                              : isSelected
                                  ? Colors.white
                                  : AppTheme.primary,
                        ),
                      ),
                      Text(
                        isUnavailable
                            ? (slot.isLocked ? 'Locked' : 'Booked')
                            : 'NPR ${slot.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: Dimension.font(11),
                          color: isUnavailable
                              ? Colors.grey
                              : isSelected
                                  ? Colors.white70
                                  : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
