using System.Security.Claims;

using FutsalApi.ApiService.Infrastructure;
using FutsalApi.Data.Models;
using FutsalApi.ApiService.Repositories;
using FutsalApi.Data.DTO;
using FutsalApi.ApiService.Repositories.Interfaces;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace FutsalApi.ApiService.Data;

public class ReviewApiEndpoints : IEndpoint
{
    public void MapEndpoint(IEndpointRouteBuilder endpoints)
    {
        var routeGroup = endpoints.MapGroup("/Reviews")
            .WithTags("Reviews")
            .CacheOutput()
            .RequireAuthorization();

        // GET: /Reviews (for current user, with pagination)
        routeGroup.MapGet("/", GetAllReviewsByUserId)
            .WithName("GetAllReviewsByUserId")
            .WithSummary("Retrieves all reviews for the current user with pagination.")
            .WithDescription("Returns a paginated list of all reviews for the currently authenticated user.")
            .Produces<IEnumerable<ReviewResponse>>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        // GET: /Reviews/Remaining
        routeGroup.MapGet("/Remaining/List", GetRemainingReviews)
            .WithName("GetRemainingReviews")
            .WithSummary("Retrieves bookings that need reviews.")
            .WithDescription("Returns a paginated list of completed or cancelled bookings for which the user hasn't added a review yet.")
            .Produces<IEnumerable<BookingResponse>>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        // GET: /Reviews/Ground/{groundId}
        routeGroup.MapGet("/Ground/{groundId:int}", GetReviewsByGroundId)
            .WithName("GetReviewsByGroundId")
            .WithSummary("Retrieves reviews for a specific ground.")
            .WithDescription("Returns a paginated list of reviews for a specific ground identified by its ID.")
            .Produces<IEnumerable<ReviewResponse>>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        // GET: /Reviews/{id}
        routeGroup.MapGet("/{id:int}", GetReviewById)
            .WithName("GetReviewById")
            .WithSummary("Retrieves a review by ID.")
            .WithDescription("Returns the details of a specific review identified by its ID.")
            .Produces<ReviewResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        // POST: /Reviews
        routeGroup.MapPost("/", CreateReview)
            .WithName("CreateReview")
            .WithSummary("Creates a new review.")
            .WithDescription("Adds a new review to the system.")
            .Accepts<CreateReviewRequest>("application/json")
            .Produces<string>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        // PUT: /Reviews/{id}
        routeGroup.MapPut("/{id:int}", UpdateReview)
            .WithName("UpdateReview")
            .WithSummary("Updates an existing review.")
            .WithDescription("Modifies the details of an existing review identified by its ID.")
            .Accepts<ReviewRequest>("application/json")
            .Produces<string>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        // DELETE: /Reviews/{id}
        routeGroup.MapDelete("/{id:int}", DeleteReview)
            .WithName("DeleteReview")
            .WithSummary("Deletes a review.")
            .WithDescription("Removes a review from the system identified by its ID. Users can only delete their own reviews.")
            .Produces(StatusCodes.Status204NoContent)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status403Forbidden)
            .ProducesProblem(StatusCodes.Status500InternalServerError);
    }

    // Changed: Get all reviews for the current user
    internal async Task<Results<Ok<IEnumerable<ReviewResponse>>, ProblemHttpResult>> GetAllReviewsByUserId(
        [FromServices] IReviewRepository repository,
        [FromServices] UserManager<User> userManager,
        ClaimsPrincipal claimsPrincipal,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        if (page <= 0 || pageSize <= 0)
        {
            return TypedResults.Problem(detail: "Page and pageSize must be greater than 0.", statusCode: StatusCodes.Status400BadRequest);
        }
        try
        {
            var user = await userManager.GetUserAsync(claimsPrincipal);
            if (user == null)
            {
                return TypedResults.Problem("User not found.", statusCode: StatusCodes.Status404NotFound);
            }
            var reviews = await repository.GetAllByUserAsync(user.Id, page, pageSize);
            return TypedResults.Ok(reviews);
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while retrieving reviews: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<IEnumerable<ReviewResponse>>, ProblemHttpResult>> GetReviewsByGroundId(
        [FromServices] IReviewRepository repository,
        int groundId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        if (page <= 0 || pageSize <= 0)
        {
            return TypedResults.Problem(detail: "Page and pageSize must be greater than 0.", statusCode: StatusCodes.Status400BadRequest);
        }

        try
        {
            var reviews = await repository.GetReviewsByGroundIdAsync(groundId, page, pageSize);
            return TypedResults.Ok(reviews);
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while retrieving reviews: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult>> GetRemainingReviews(
        [FromServices] IBookingRepository bookingRepository,
        [FromServices] IReviewRepository reviewRepository,
        [FromServices] UserManager<User> userManager,
        ClaimsPrincipal claimsPrincipal,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        if (page <= 0 || pageSize <= 0)
        {
            return TypedResults.Problem(detail: "Page and pageSize must be greater than 0.", statusCode: StatusCodes.Status400BadRequest);
        }

        try
        {
            var user = await userManager.GetUserAsync(claimsPrincipal);
            if (user == null)
            {
                return TypedResults.Problem("User not found.", statusCode: StatusCodes.Status404NotFound);
            }

            // Get all completed/cancelled bookings for the user
            var allBookings = await bookingRepository.GetRemainingReviewsAsync(user.Id, page, pageSize);

            // Filter out bookings where a review already exists
            var remainingBookings = new List<BookingResponse>();
            foreach (var booking in allBookings)
            {
                var existingReview = await reviewRepository.GetByIdAsync(e => e.GroundId == booking.GroundId && e.UserId == user.Id);
                if (existingReview == null)
                {
                    remainingBookings.Add(booking);
                }
            }

            return TypedResults.Ok(remainingBookings.AsEnumerable());
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while retrieving remaining reviews: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<ReviewResponse>, NotFound, ProblemHttpResult>> GetReviewById(
        [FromServices] IReviewRepository repository,
        int id)
    {
        try
        {
            var review = await repository.GetByIdAsync(e => e.Id == id);
            if (review is null)
            {
                return TypedResults.NotFound();
            }

            return TypedResults.Ok(review);
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while retrieving the review: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<string>, ProblemHttpResult>> CreateReview(
        [FromServices] IReviewRepository repository,
        [FromServices] IBookingRepository bookingRepository,
        [FromServices] AppDbContext dbContext,
        [FromServices] UserManager<User> userManager,
        ClaimsPrincipal claimsPrincipal,
        [FromBody] CreateReviewRequest reviewRequest)
    {
        try
        {
            if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
            {
                return TypedResults.Problem("User not found.", statusCode: StatusCodes.Status404NotFound);
            }

            // Get the booking by bookingId and ensure it belongs to the user
            var booking = await bookingRepository.GetByIdAsync(e => e.Id == reviewRequest.BookingId && e.UserId == user.Id);
            if (booking == null)
            {
                return TypedResults.Problem("Booking not found or does not belong to the user.", statusCode: StatusCodes.Status404NotFound);
            }

            var groundId = booking.GroundId;

            var hasValidBooking = await bookingRepository.HasValidBookingForReviewAsync(groundId, user.Id);
            if (!hasValidBooking)
            {
                return TypedResults.Problem("You can only review grounds for which you have a completed or cancelled booking.", statusCode: StatusCodes.Status400BadRequest);
            }

            var existingReview = await repository.GetByIdAsync(e => e.GroundId == groundId && e.UserId == user.Id);
            if (existingReview is not null)
            {
                return TypedResults.Problem("You have already reviewed this ground.", statusCode: StatusCodes.Status400BadRequest);
            }

            Review review = new Review
            {
                UserId = user.Id,
                GroundId = groundId,
                Rating = reviewRequest.Rating,
                Comment = reviewRequest.Comment,
                ImageId = reviewRequest.ImageId
            };

            var reviewId = await repository.CreateReviewAsync(review);

            if (reviewId == 0)
            {
                return TypedResults.Problem("Failed to create the review.", statusCode: StatusCodes.Status400BadRequest);
            }

            return TypedResults.Ok("Review created successfully.");
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while creating the review: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<string>, NotFound, ProblemHttpResult>> UpdateReview(
        [FromServices] IReviewRepository repository,
        [FromServices] UserManager<User> userManager,
        ClaimsPrincipal claimsPrincipal,
        int id,
        [FromBody] ReviewRequest updatedReviewRequest)
    {
        try
        {
            if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
            {
                return TypedResults.Problem("User not found.", statusCode: StatusCodes.Status404NotFound);
            }

            var existingReview = await repository.GetByIdAsync(e => e.Id == id && e.UserId == user.Id);
            if (existingReview is null)
            {
                return TypedResults.NotFound();
            }

            Review updatedReview = new Review
            {
                Id = id,
                UserId = user.Id,
                GroundId = updatedReviewRequest.GroundId,
                Rating = updatedReviewRequest.Rating,
                Comment = updatedReviewRequest.Comment,
                ImageId = updatedReviewRequest.ImageId
            };

            await repository.UpdateReviewAsync(updatedReview);

            return TypedResults.Ok("Review updated successfully.");
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while updating the review: {ex.Message}");
        }
    }

    internal async Task<Results<NoContent, NotFound, ProblemHttpResult>> DeleteReview(
        [FromServices] IReviewRepository repository,
        [FromServices] IFutsalGroundRepository groundRepository,
        [FromServices] UserManager<User> userManager,
        ClaimsPrincipal claimsPrincipal,
        int id)
    {
        try
        {
            if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
            {
                return TypedResults.Problem("User not found.", statusCode: StatusCodes.Status404NotFound);
            }

            var review = await repository.GetByIdAsync(e => e.Id == id && e.UserId == user.Id);
            if (review is null)
            {
                return TypedResults.NotFound();
            }
            var success = await repository.DeleteReviewByUserAsync(id, user.Id);
            if (success)
            {
                return TypedResults.NoContent();
            }
            await groundRepository.UpdateRatingAsync(review.GroundId);
            return TypedResults.Problem("Failed to delete the review.");
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while deleting the review: {ex.Message}");
        }
    }
}
