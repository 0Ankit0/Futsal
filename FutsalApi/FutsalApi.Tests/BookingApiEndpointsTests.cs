﻿using System.Linq.Expressions;
using System.Security.Claims;
using FutsalApi.ApiService.Data;
using FutsalApi.ApiService.Models;
using FutsalApi.ApiService.Repositories;
using FutsalApi.ApiService.Routes;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Moq;
using Xunit;
using FluentAssertions;

namespace FutsalApi.Tests;

public class BookingApiEndpointsTests
{
    private readonly Mock<IBookingRepository> _bookingRepositoryMock;
    private readonly Mock<IFutsalGroundRepository> _groundRepositoryMock;
    private readonly Mock<UserManager<User>> _userManagerMock;
    private readonly BookingApiEndpoints _endpoints;

    public BookingApiEndpointsTests()
    {
        _bookingRepositoryMock = new Mock<IBookingRepository>();
        _groundRepositoryMock = new Mock<IFutsalGroundRepository>();
        _userManagerMock = MockUserManager();
        _endpoints = new BookingApiEndpoints();
    }

    [Fact]
    public async Task GetBookingsByUserId_ReturnsOk_WhenBookingsExist()
    {
        // Arrange
        var user = new User { Id = "user1" };
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, user.Id) }));
        var bookings = new List<BookingResponse>
        {
            new BookingResponse { Id = 1, UserId = "user1", GroundId = 1, GroundName = "Ground 1" }
        };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _bookingRepositoryMock.Setup(r => r.GetBookingsByUserIdAsync(user.Id, 1, 10)).ReturnsAsync(bookings);

        // Act
        var result = await _endpoints.GetBookingsByUserId(_bookingRepositoryMock.Object, _userManagerMock.Object, claimsPrincipal, 1, 10);

        // Assert
        result.Should().BeOfType<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound>>();
        if (result is Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound> { Result: Ok<IEnumerable<BookingResponse>> okResult })
        {
            okResult.Value.Should().BeEquivalentTo(bookings);
        }
    }

    [Fact]
    public async Task GetBookingsByUserId_ReturnsNotFound_WhenUserNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal();

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync((User?)null);

        // Act
        var result = await _endpoints.GetBookingsByUserId(_bookingRepositoryMock.Object, _userManagerMock.Object, claimsPrincipal, 1, 10);

        // Assert
        result.Should().BeOfType<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound>>();
        if (result is Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound> { Result: NotFound })
        {
            result.Result.Should().BeOfType<NotFound>();
        }
    }

    [Fact]
    public async Task CreateBooking_ReturnsOk_WhenBookingIsCreated()
    {
        // Arrange
        var bookingRequest = new BookingRequest
        {
            UserId = "user1",
            GroundId = 1,
            BookingDate = DateTime.Today,
            StartTime = TimeSpan.FromHours(10),
            EndTime = TimeSpan.FromHours(12)
        };
        var ground = new FutsalGroundResponse
        {
            Id = 1,
            Name = "Ground 1",
            Location = "Location 1",
            OwnerId = "Owner1",
            PricePerHour = 100,
            OpenTime = TimeSpan.FromHours(8),
            CloseTime = TimeSpan.FromHours(22),
            CreatedAt = DateTime.UtcNow,
            OwnerName = "Owner Name"
        };

        _groundRepositoryMock
             .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<FutsalGround, bool>>>()))
             .ReturnsAsync(ground);

        _bookingRepositoryMock
            .Setup(r => r.CreateAsync(It.IsAny<Booking>()))
            .ReturnsAsync(new Booking
            {
                Id = 1,
                UserId = "user1",
                GroundId = 1,
                BookingDate = DateTime.Today,
                StartTime = TimeSpan.FromHours(10),
                EndTime = TimeSpan.FromHours(12),
                TotalAmount = 200
            });

        // Act
        var result = await _endpoints.CreateBooking(_bookingRepositoryMock.Object, _groundRepositoryMock.Object, bookingRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult>>();
        if (result is Results<Ok<string>, ProblemHttpResult> { Result: Ok<string> okResult })
        {
            okResult.Value.Should().Be("Booking created successfully.");
        }
    }

    [Fact]
    public async Task CreateBooking_ReturnsProblem_WhenGroundNotFound()
    {
        // Arrange
        var bookingRequest = new BookingRequest
        {
            UserId = "user1",
            GroundId = 1,
            BookingDate = DateTime.Today,
            StartTime = TimeSpan.FromHours(10),
            EndTime = TimeSpan.FromHours(12)
        };

        _groundRepositoryMock
             .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<FutsalGround, bool>>>()))
                .ReturnsAsync(new FutsalGroundResponse
                {
                    Id = 1,
                    Name = "Ground 1",
                    Location = "Location 1",
                    OwnerId = "Owner1",
                    PricePerHour = 100,
                    OpenTime = TimeSpan.FromHours(8),
                    CloseTime = TimeSpan.FromHours(22),
                    CreatedAt = DateTime.UtcNow,
                    OwnerName = "Owner Name"
                });

        // Act
        var result = await _endpoints.CreateBooking(_bookingRepositoryMock.Object, _groundRepositoryMock.Object, bookingRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult>>();
        if (result is Results<Ok<string>, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("Ground not found.");
        }
    }

    [Fact]
    public async Task UpdateBooking_ReturnsOk_WhenBookingIsUpdated()
    {
        // Arrange
        var bookingRequest = new BookingRequest
        {
            UserId = "user1",
            GroundId = 1,
            BookingDate = DateTime.Today,
            StartTime = TimeSpan.FromHours(10),
            EndTime = TimeSpan.FromHours(12)
        };
        var existingBooking = new Booking { Id = 1, UserId = "user1" };

        _bookingRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>()))
            .ReturnsAsync(existingBooking);

        _bookingRepositoryMock
            .Setup(r => r.UpdateAsync(It.IsAny<Expression<Func<Booking, bool>>>(), It.IsAny<Booking>()))
            .ReturnsAsync(existingBooking);

        // Act
        var result = await _endpoints.UpdateBooking(_bookingRepositoryMock.Object, 1, bookingRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult, NotFound>>();
        if (result is Results<Ok<string>, ProblemHttpResult, NotFound> { Result: Ok<string> okResult })
        {
            okResult.Value.Should().Be("Booking updated successfully.");
        }
    }

    [Fact]
    public async Task CancelBooking_ReturnsOk_WhenBookingIsCancelled()
    {
        // Arrange
        var user = new User { Id = "user1" };
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, user.Id) }));
        var existingBooking = new Booking { Id = 1, UserId = "user1", Status = BookingStatus.Pending };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _bookingRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>()))
            .ReturnsAsync(existingBooking);

        _bookingRepositoryMock
            .Setup(r => r.UpdateAsync(It.IsAny<Expression<Func<Booking, bool>>>(), It.IsAny<Booking>()))
            .ReturnsAsync(existingBooking);

        // Act
        var result = await _endpoints.CancelBooking(_bookingRepositoryMock.Object, claimsPrincipal, _userManagerMock.Object, 1);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult, NotFound>>();
        if (result is Results<Ok<string>, ProblemHttpResult, NotFound> { Result: Ok<string> okResult })
        {
            okResult.Value.Should().Be("Booking cancelled successfully.");
        }
    }

    private static Mock<UserManager<User>> MockUserManager()
    {
        var store = new Mock<IUserStore<User>>();
        return new Mock<UserManager<User>>(store.Object, null, null, null, null, null, null, null, null);
    }
}
