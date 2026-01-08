import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ui/core/dimension.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/view/reviews/bloc/reviews_bloc.dart';
import 'package:ui/view/reviews/data/model/reviews_model.dart';
import 'package:ui/view/reviews/data/repository/reviews_repository.dart';

class Reviews extends StatelessWidget {
  const Reviews({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure Dimension is initialized if not already done in main.dart
    // Just in case, though usually done at app start.
    // Dimension.init(context);

    return BlocProvider(
      create: (context) =>
          ReviewsBloc(reviewsRepository: ReviewsRepository())
            ..add(LoadReviews()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Reviews',
            style: TextStyle(fontSize: Dimension.font(20)),
          ),
        ),
        body: BlocBuilder<ReviewsBloc, ReviewsState>(
          builder: (context, state) {
            if (state is ReviewsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ReviewsLoaded) {
              if (state.reviews.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<ReviewsBloc>().add(LoadReviews());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: Dimension.height(200)),
                      Center(
                        child: Text(
                          "No reviews yet.",
                          style: TextStyle(fontSize: Dimension.font(16)),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ReviewsBloc>().add(LoadReviews());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(Dimension.width(16.0)),
                  itemCount: state.reviews.length,
                  itemBuilder: (context, index) {
                    final review = state.reviews[index];
                    return ReviewCard(review: review);
                  },
                ),
              );
            } else if (state is ReviewsError) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ReviewsBloc>().add(LoadReviews());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: Dimension.height(200)),
                    Center(
                      child: Text(
                        state.message,
                        style: TextStyle(fontSize: Dimension.font(14)),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final ReviewsModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.tryParse(review.createdAt ?? '');
    final formattedDate = dateTime != null
        ? DateFormat.yMMMd().format(dateTime)
        : '';

    return Card(
      margin: EdgeInsets.only(bottom: Dimension.height(16.0)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimension.width(12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimension.width(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: Dimension.width(20),
                  backgroundImage: review.userImageId != null
                      ? NetworkImage(
                          '${ApiConst.baseUrl}images/${review.userImageId}',
                        )
                      : null,
                  child: review.userImageId == null
                      ? Text(
                          review.userName?[0].toUpperCase() ?? 'U',
                          style: TextStyle(fontSize: Dimension.font(16)),
                        )
                      : null,
                ),
                SizedBox(width: Dimension.width(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Unknown User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Dimension.font(16),
                      ),
                    ),
                    if (formattedDate.isNotEmpty)
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: Dimension.font(12),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimension.width(8),
                    vertical: Dimension.height(4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(Dimension.width(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: Dimension.width(16),
                      ),
                      SizedBox(width: Dimension.width(4)),
                      Text(
                        review.rating?.toString() ?? '0',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: Dimension.font(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimension.height(12)),
            Text(
              review.comment ?? '',
              style: TextStyle(fontSize: Dimension.font(14)),
            ),
            if (review.reviewImageUrl != null &&
                review.reviewImageUrl!.isNotEmpty) ...[
              SizedBox(height: Dimension.height(12)),
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimension.width(8)),
                child: Image.network(
                  '${ApiConst.baseUrl}${review.reviewImageUrl}',
                  height: Dimension.height(150),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
