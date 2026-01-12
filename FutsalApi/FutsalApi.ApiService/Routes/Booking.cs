using System;
using System.Runtime.CompilerServices;
using System.Security.Claims;


using FutsalApi.ApiService.Infrastructure;
using FutsalApi.ApiService.Infrastructure.Auth;
using FutsalApi.Data.Models;
using FutsalApi.Data.DTO;
using FutsalApi.ApiService.Repositories;
using FutsalApi.ApiService.Repositories.Interfaces;
using FutsalApi.Data.DTO;

using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Auth;

[assembly: InternalsVisibleTo("FutsalApi.Tests")]
namespace FutsalApi.ApiService.Routes;

public class BookingApiEndpoints : IEndpoint
{
    public void MapEndpoint(IEndpointRouteBuilder endpoints)
    {
        var routeGroup = endpoints.MapGroup("/Booking")
            .WithTags("Booking")
            .RequireAuthorization();

        routeGroup.MapGet("/", GetBookingsByUserId)
            //.RequirePermissionResource(Permissions.CanView, Resources.Booking)
            .WithName("GetBookingsByUserId")
            .WithSummary("Get Bookings of a user")
            .WithDescription("Get all the Bookings for a particular user using userid")
            .Produces<IEnumerable<BookingResponse>>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapGet("/pending", GetPendingBookingsByUserId)
            .WithName("GetPendingBookingsByUserId")
            .WithSummary("Get Pending Bookings of a user")
            .WithDescription("Get all the Pending Bookings for a particular user using userid")
            .Produces<IEnumerable<BookingResponse>>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapGet("/cancelled",GetCancelledBookingsByUserId)
            .WithName("GetCancelledBookingsByUserId")
            .WithSummary("Get Cancelled Bookings of a user")
            .WithDescription("Get all the Cancelled Bookings for a particular user using userid")
            .Produces<IEnumerable<BookingResponse>>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapGet("/completed",GetCompletedBookingsByUserId)
            .WithName("GetCompletedBookingsByUserId")
            .WithSummary("Get Completed Bookings of a user")
            .WithDescription("Get all the Completed Bookings for a particular user using userid")
            .Produces<IEnumerable<BookingResponse>>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPost("/", CreateBooking)
            .WithName("CreateBooking")
            .WithSummary("Create a new booking")
            .WithDescription("Create a new booking for a user")
            .Accepts<BookingRequest>("application/json")
            .Produces<string>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPut("/{id}", UpdateBooking)
            .WithName("UpdateBooking")
            .WithSummary("Update an existing booking")
            .WithDescription("Update an existing booking for a user")
            .Accepts<BookingRequest>("application/json")
            .Produces<string>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPatch("/cancel/{id}", CancelBooking)
            .WithName("CancelBooking")
            .WithSummary("Cancel an existing booking")
            .WithDescription("Cancel an existing booking for a user")
            .Produces<string>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPatch("/accept/{id}", AcceptBooking)
            .WithName("AcceptBooking")
            .WithSummary("Accept a booking request (owner only)")
            .WithDescription("Allows the owner of the ground to accept a booking request. Only the owner can perform this action.")
            .Produces<string>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status403Forbidden)
            .ProducesProblem(StatusCodes.Status500InternalServerError);
    }

    internal async Task<Results<Ok<string>, ProblemHttpResult, NotFound<string>, ForbidHttpResult>> AcceptBooking(
        [FromServices] IBookingRepository repository,
        [FromServices] IFutsalGroundRepository groundRepository,
        ClaimsPrincipal claimsPrincipal,
        [FromServices] UserManager<User> userManager,
        [FromRoute] int id)
    {
        try
        {
            // Get current user
            var user = await userManager.GetUserAsync(claimsPrincipal);
            if (user == null)
                return TypedResults.NotFound("User not found.");

            // Get booking
            var booking = await repository.GetByIdAsync(e => e.Id == id);
            if (booking == null)
                return TypedResults.NotFound("Booking not found.");

            // Get ground
            var ground = await groundRepository.GetByIdAsync(e => e.Id == booking.GroundId);
            if (ground == null)
                return TypedResults.Problem("Ground not found.", statusCode: StatusCodes.Status404NotFound);

            // Check owner
            if (ground.OwnerId != user.Id)
                return TypedResults.Problem("Only the owner of the ground can accept bookings.", statusCode: StatusCodes.Status403Forbidden);

            // Only allow accepting if pending
            if (booking.Status != BookingStatus.Pending)
                return TypedResults.Problem("Only pending bookings can be accepted.", statusCode: StatusCodes.Status400BadRequest);

            booking.Status = BookingStatus.Confirmed;
            booking.UpdatedAt = DateTime.UtcNow;
            await repository.UpdateAsync(e => e.Id == id, booking);

            return TypedResults.Ok("Booking accepted successfully.");
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while accepting the booking: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound<string>>> GetPendingBookingsByUserId(
        [FromServices] IBookingRepository repository,
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
            if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
            {
                return TypedResults.NotFound("User not found.");
            }
            var bookings = await repository.GetBookingsByPredicateAsync(
                r => r.UserId == user.Id && r.Status == BookingStatus.Pending,
                page,
                pageSize);
            return TypedResults.Ok(bookings);
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while retrieving Bookings: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound<string>>> GetCancelledBookingsByUserId(
        [FromServices] IBookingRepository repository,
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
            if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
            {
                return TypedResults.NotFound("User not found.");
            }
            var bookings = await repository.GetBookingsByPredicateAsync(
                r => r.UserId == user.Id && r.Status == BookingStatus.Cancelled,
                page,
                pageSize);
            return TypedResults.Ok(bookings);
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while retrieving Bookings: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound<string>>> GetCompletedBookingsByUserId(
        [FromServices] IBookingRepository repository,
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
            if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
            {
                return TypedResults.NotFound("User not found.");
            }
            var bookings = await repository.GetBookingsByPredicateAsync(
                r => r.UserId == user.Id && r.Status == BookingStatus.Completed,
                page,
                pageSize);
            return TypedResults.Ok(bookings);
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while retrieving Bookings: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound<string>>> GetBookingsByUserId(
        [FromServices] IBookingRepository repository,
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
            if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
            {
                return TypedResults.NotFound("User not found.");
            }
            var bookings = await repository.GetBookingsByUserIdAsync(user.Id, page, pageSize);
            return TypedResults.Ok(bookings);
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while retrieving Bookings: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<string>, ProblemHttpResult>> CreateBooking(
        [FromServices] IBookingRepository repository,
        [FromServices] IGroundClosureRepository groundClosureRepository,
        [FromServices] IFutsalGroundRepository groundRepository,
        [FromBody] BookingRequest bookingRequest)
    {
        try
        {
            if (await groundClosureRepository.IsGroundClosedAsync(bookingRequest.GroundId, bookingRequest.BookingDate, bookingRequest.StartTime, bookingRequest.EndTime))
            {
                return TypedResults.Problem("The selected time slot is closed for booking.", statusCode: StatusCodes.Status400BadRequest);
            }

            var ground = await groundRepository.GetByIdAsync(e => e.Id == bookingRequest.GroundId);
            if (ground == null)
            {
                return TypedResults.Problem("Ground not found.", statusCode: StatusCodes.Status404NotFound);
            }

            if (bookingRequest.StartTime >= bookingRequest.EndTime)
            {
                return TypedResults.Problem("Start time must be less than end time.", statusCode: StatusCodes.Status400BadRequest);
            }

            if (bookingRequest.StartTime < ground.OpenTime || bookingRequest.EndTime > ground.CloseTime)
            {
                return TypedResults.Problem("Booking time must be within the ground's operating hours.", statusCode: StatusCodes.Status400BadRequest);
            }

            Booking booking = new Booking
            {
                UserId = bookingRequest.UserId,
                GroundId = bookingRequest.GroundId,
                BookingDate = bookingRequest.BookingDate,
                StartTime = bookingRequest.StartTime,
                EndTime = bookingRequest.EndTime,
                TotalAmount = ground.PricePerHour * (decimal)(bookingRequest.EndTime - bookingRequest.StartTime).TotalHours
            };

            var bookingId = await repository.CreateBookingAsync(booking);

            if (bookingId == 0)
            {
                return TypedResults.Problem("The selected time slot is already booked.", statusCode: StatusCodes.Status400BadRequest);
            }

            return TypedResults.Ok("Booking created successfully.");
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while creating the booking: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<string>, ProblemHttpResult, NotFound>> UpdateBooking(
        [FromServices] IBookingRepository repository,
        [FromRoute] int id,
        [FromBody] BookingRequest bookingRequest)
    {
        try
        {
            var existingBooking = await repository.GetByIdAsync(e => e.Id == id);
            if (existingBooking == null)
            {
                return TypedResults.NotFound("Booking not found.");
            }
            if (existingBooking.Status == BookingStatus.Cancelled)
            {
                return TypedResults.Problem("Cannot update a cancelled booking.", statusCode: StatusCodes.Status400BadRequest);
            }
            if (existingBooking.Status == BookingStatus.Completed)
            {
                return TypedResults.Problem("Cannot update a completed booking.", statusCode: StatusCodes.Status400BadRequest);
            }

            existingBooking.StartTime = bookingRequest.StartTime;
            existingBooking.EndTime = bookingRequest.EndTime;

            await repository.UpdateAsync(e => e.Id == id, existingBooking);
            return TypedResults.Ok("Booking updated successfully.");
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while updating the booking: {ex.Message}");
        }
    }

    internal async Task<Results<Ok<string>, ProblemHttpResult, NotFound>> CancelBooking(
        [FromServices] IBookingRepository repository,
        ClaimsPrincipal claimsPrincipal,
        [FromServices] UserManager<User> userManager,
        [FromRoute] int id)
    {
        try
        {
            if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
            {
                return TypedResults.NotFound("User not found.");
            }

            var booking = await repository.GetBookingByIdAndUserIdAsync(id, user.Id);
            if (booking == null)
            {
                return TypedResults.NotFound("Booking not found.");
            }

            if (booking.Status == BookingStatus.Confirmed)
            {
                return TypedResults.Problem("Already accepted booking can't be cancelled.", statusCode: StatusCodes.Status400BadRequest);
            }

            var result = await repository.CancelBookingAsync(id, user.Id);

            if (!result)
            {
                return TypedResults.Problem("Failed to cancel the booking. The booking may not exist or is already cancelled.", statusCode: StatusCodes.Status400BadRequest);
            }

            return TypedResults.Ok("Booking cancelled successfully.");
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"An error occurred while updating the booking: {ex.Message}");
        }
    }
}
