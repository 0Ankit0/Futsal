import 'package:flutter/material.dart';
import '../../../core/dimension.dart';

class ReviewDialog extends StatefulWidget {
  final int groundId;
  final String groundName;
  final Function(int rating, String comment) onSubmit;

  const ReviewDialog({
    super.key,
    required this.groundId,
    required this.groundName,
    required this.onSubmit,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.width(16)),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: Dimension.width(20),
        vertical: Dimension.height(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Dimension.width(20)),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Review ${widget.groundName}',
                        style: TextStyle(
                          fontSize: Dimension.font(18),
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, size: Dimension.width(24)),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: Dimension.height(16)),
                Text(
                  'Rating *',
                  style: TextStyle(
                    fontSize: Dimension.font(14),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: Dimension.height(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: Dimension.width(40),
                      ),
                    );
                  }),
                ),
                if (_rating == 0)
                  Padding(
                    padding: EdgeInsets.only(top: Dimension.height(4)),
                    child: Text(
                      'Please select a rating',
                      style: TextStyle(
                        fontSize: Dimension.font(12),
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: Dimension.height(16)),
                Text(
                  'Comment *',
                  style: TextStyle(
                    fontSize: Dimension.font(14),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: Dimension.height(8)),
                TextFormField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a comment';
                    }
                    if (value.trim().length < 10) {
                      return 'Comment must be at least 10 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimension.width(12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimension.width(12)),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimension.width(12)),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimension.width(12)),
                      borderSide: BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimension.width(12)),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: Dimension.height(20)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: Dimension.height(12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimension.width(12),
                        ),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: Dimension.height(20),
                            width: Dimension.width(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Submit Review',
                            style: TextStyle(
                              fontSize: Dimension.font(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (_rating == 0) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(_rating, _commentController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
