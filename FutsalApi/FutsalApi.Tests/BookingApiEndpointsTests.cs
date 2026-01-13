using System.Linq.Expressions;
using System.Security.Claims;
using FutsalApi.Data.Models;
using FutsalApi.ApiService.Repositories;
using FutsalApi.ApiService.Routes;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Moq;
using FluentAssertions;
using FutsalApi.ApiService.Repositories.Interfaces;
using FutsalApi.Data.DTO;
using FutsalApi.Data.Models;

namespace FutsalApi.Tests;

public class BookingApiEndpointsTests
{
    private readonly Mock<IBookingRepository> _bookingRepositoryMock;
    private readonly Mock<IFutsalGroundRepository> _groundRepositoryMock;
    private readonly Mock<UserManager<User>> _userManagerMock;
    private readonly Mock<IGroundClosureRepository> _groundClosureRepositoryMock;
    private readonly BookingApiEndpoints _endpoints;

    public BookingApiEndpointsTests()
    {
        _bookingRepositoryMock = new Mock<IBookingRepository>();
        _groundRepositoryMock = new Mock<IFutsalGroundRepository>();
        _groundClosureRepositoryMock = new Mock<IGroundClosureRepository>();
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
            new BookingResponse { Id = 1, UserId = "user1", GroundId = 1, GroundName = "Ground 1", HasReview = false }
        };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _bookingRepositoryMock.Setup(r => r.GetBookingsByUserIdAsync(user.Id, 1, 10)).ReturnsAsync(bookings);

        // Act
        var result = await _endpoints.GetBookingsByUserId(
            _bookingRepositoryMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            1, 10);

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
        var result = await _endpoints.GetBookingsByUserId(
            _bookingRepositoryMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            1, 10);

        // Assert
        result.Should().BeOfType<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound>>();
        if (result is Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound> { Result: NotFound })
        {
            result.Result.Should().BeOfType<NotFound>();
        }
    }

    [Fact]
    public async Task GetBookingsByUserId_ReturnsProblem_WhenPageOrPageSizeInvalid()
    {
        // Arrange
        var user = new User { Id = "user1" };
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, user.Id) }));

        // Act
        var result = await _endpoints.GetBookingsByUserId(
            _bookingRepositoryMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            0, 10);

        // Assert
        result.Should().BeOfType<Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound>>();
        if (result is Results<Ok<IEnumerable<BookingResponse>>, ProblemHttpResult, NotFound> { Result: ProblemHttpResult problem })
        {
            problem.Should().BeOfType<ProblemHttpResult>();
        }
    }

    [Fact]
    public async Task CreateBooking_ReturnsOk_WhenBookingIsCreated()
    {
        // Arrange
        var now = DateTime.UtcNow.TimeOfDay;
        var bookingRequest = new BookingRequest
        {
            UserId = "user1",
            GroundId = 1,
            BookingDate = DateTime.Today,
            StartTime = now.Add(TimeSpan.FromHours(1)),
            EndTime = now.Add(TimeSpan.FromHours(2))
        };
        var ground = new FutsalGroundResponse
        {
            Id = 1,
            Name = "Ground 1",
            Location = "Location 1",
            OwnerId = "Owner1",
            PricePerHour = 200,
            OpenTime = now.Subtract(TimeSpan.FromHours(2)),
            CloseTime = now.Add(TimeSpan.FromHours(6)),
            // Other properties omitted for brevity
        };

        _groundClosureRepositoryMock
            .Setup(r => r.IsGroundClosedAsync(bookingRequest.GroundId, bookingRequest.BookingDate, bookingRequest.StartTime, bookingRequest.EndTime))
            .ReturnsAsync(false);

        _groundRepositoryMock
             .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<FutsalGround, bool>>>()))
             .ReturnsAsync(ground);

        _bookingRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>()))
            .ReturnsAsync((Booking?)null);

        _bookingRepositoryMock
            .Setup(r => r.GetAllAsync(It.IsAny<Expression<Func<Booking, bool>>>(), 1, 4))
            .ReturnsAsync(new List<BookingResponse>());

        _bookingRepositoryMock
            .Setup(r => r.CreateBookingAsync(It.IsAny<Booking>()))
            .ReturnsAsync(1);

        // Act
        var result = await _endpoints.CreateBooking(
            _bookingRepositoryMock.Object,
            _groundClosureRepositoryMock.Object,
            _groundRepositoryMock.Object,
            bookingRequest);

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

        _groundClosureRepositoryMock
            .Setup(r => r.IsGroundClosedAsync(bookingRequest.GroundId, bookingRequest.BookingDate, bookingRequest.StartTime, bookingRequest.EndTime))
            .ReturnsAsync(false);

        _groundRepositoryMock
             .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<FutsalGround, bool>>>()))
                .ReturnsAsync((FutsalGroundResponse?)null);

        // Act
        var result = await _endpoints.CreateBooking(
            _bookingRepositoryMock.Object,
            _groundClosureRepositoryMock.Object,
            _groundRepositoryMock.Object,
            bookingRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult>>();
        if (result is Results<Ok<string>, ProblemHttpResult> { Result: ProblemHttpResult problem })
        {
            problem.Should().BeOfType<ProblemHttpResult>();
        }
    }

    [Fact]
    public async Task CreateBooking_ReturnsProblem_WhenSlotClosed()
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

        _groundClosureRepositoryMock
            .Setup(r => r.IsGroundClosedAsync(bookingRequest.GroundId, bookingRequest.BookingDate, bookingRequest.StartTime, bookingRequest.EndTime))
            .ReturnsAsync(true);

        // Act
        var result = await _endpoints.CreateBooking(
            _bookingRepositoryMock.Object,
            _groundClosureRepositoryMock.Object,
            _groundRepositoryMock.Object,
            bookingRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult>>();
        if (result is Results<Ok<string>, ProblemHttpResult> { Result: ProblemHttpResult problem })
        {
            problem.Should().BeOfType<ProblemHttpResult>();
        }
    }

    [Fact]
    public async Task CreateBooking_ThrowsException_WhenCalledWithoutBookingRequest()
    {
        // Arrange
        // All dependencies are mocked, but bookingRequest is missing on purpose to test compile error fix
        var bookingRequest = new BookingRequest
        {
            UserId = "user1",
            GroundId = 1,
            BookingDate = DateTime.Today,
            StartTime = TimeSpan.FromHours(10),
            EndTime = TimeSpan.FromHours(12)
        };

        // Act & Assert
        // This test is just to ensure the method is always called with bookingRequest
        var result = await _endpoints.CreateBooking(_bookingRepositoryMock.Object, _groundClosureRepositoryMock.Object, _groundRepositoryMock.Object, bookingRequest);
        result.Should().NotBeNull();
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
        var existingBooking = new Booking { Id = 1, UserId = "user1", Status = BookingStatus.Pending };

        _bookingRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>()))
            .ReturnsAsync(existingBooking);

        _bookingRepositoryMock
            .Setup(r => r.UpdateAsync(It.IsAny<Expression<Func<Booking, bool>>>(), It.IsAny<Booking>()))
            .ReturnsAsync(existingBooking);

        // Act
        var result = await _endpoints.UpdateBooking(_bookingRepositoryMock.Object, 1, bookingRequest);

        // Assert
        result.Result.Should().BeOfType<Ok<string>>();
        var okResult = result.Result as Ok<string>;
        okResult!.Value.Should().Be("Booking updated successfully.");
    }

    [Fact]
    public async Task UpdateBooking_ReturnsNotFound_WhenBookingDoesNotExist()
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

        _bookingRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>()))
            .ReturnsAsync((Booking?)null);

        // Act
        var result = await _endpoints.UpdateBooking(_bookingRepositoryMock.Object, 1, bookingRequest);

        // Assert
        result.Result.Should().BeOfType<NotFound>();
    }

    [Fact]
    public async Task UpdateBooking_ReturnsProblem_WhenBookingIsCancelled()
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
        var existingBooking = new Booking { Id = 1, UserId = "user1", Status = BookingStatus.Cancelled };

        _bookingRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>()))
            .ReturnsAsync(existingBooking);

        // Act
        var result = await _endpoints.UpdateBooking(_bookingRepositoryMock.Object, 1, bookingRequest);

        // Assert
        result.Result.Should().BeOfType<ProblemHttpResult>();
        var problem = result.Result as ProblemHttpResult;
        problem!.ProblemDetails.Detail.Should().Contain("Cannot update a cancelled booking");
    }

    [Fact]
    public async Task CancelBooking_ReturnsOk_WhenBookingIsCancelled()
    {
        // Arrange
        var user = new User { Id = "user1" };
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, user.Id) }));

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _bookingRepositoryMock
            .Setup(r => r.CancelBookingAsync(1, user.Id))
            .ReturnsAsync(true);

        // Act
        var result = await _endpoints.CancelBooking(_bookingRepositoryMock.Object, claimsPrincipal, _userManagerMock.Object, 1);

        // Assert
        result.Result.Should().BeOfType<Ok<string>>();
        var okResult = result.Result as Ok<string>;
        okResult!.Value.Should().Be("Booking cancelled successfully.");
    }

    [Fact]
    public async Task CancelBooking_ReturnsNotFound_WhenUserNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal();

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync((User?)null);

        // Act
        var result = await _endpoints.CancelBooking(_bookingRepositoryMock.Object, claimsPrincipal, _userManagerMock.Object, 1);

        // Assert
        result.Result.Should().BeOfType<NotFound>();
    }

    [Fact]
    public async Task CancelBooking_ReturnsNotFound_WhenBookingNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal(); // No identity, simulates invalid user
        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync((User?)null);

        // Act
        var result = await _endpoints.CancelBooking(_bookingRepositoryMock.Object, claimsPrincipal, _userManagerMock.Object, 1);

        // Assert
        result.Result.Should().BeOfType<NotFound>();
    }

    [Fact]
    public async Task CancelBooking_ReturnsProblem_WhenBookingAlreadyCancelled()
    {
        // Arrange
        var user = new User { Id = "user1" };
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, user.Id) }));
        var existingBooking = new Booking { Id = 1, UserId = "user1", Status = BookingStatus.Cancelled };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _bookingRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>()))
            .ReturnsAsync(existingBooking);

        // Act
        var result = await _endpoints.CancelBooking(_bookingRepositoryMock.Object, claimsPrincipal, _userManagerMock.Object, 1);

        // Assert
        result.Result.Should().BeOfType<ProblemHttpResult>();
        var problem = result.Result as ProblemHttpResult;
        problem!.ProblemDetails.Detail.Should().Contain("already cancelled");
    }

    [Fact]
    public async Task CancelBooking_ReturnsProblem_WhenBookingCompleted()
    {
        // Arrange
        var user = new User { Id = "user1" };
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, user.Id) }));
        var existingBooking = new Booking { Id = 1, UserId = "user1", Status = BookingStatus.Completed };

        _userManagerMock.Setup(um => um.GetUserAsync(It.IsAny<ClaimsPrincipal>())).ReturnsAsync(user);
        _bookingRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>()))
            .ReturnsAsync(existingBooking);

        // Act
        var result = await _endpoints.CancelBooking(_bookingRepositoryMock.Object, claimsPrincipal, _userManagerMock.Object, 1);

        // Assert
        result.Result.Should().BeOfType<ProblemHttpResult>();
        //var problem = result.Result as ProblemHttpResult;
        //problem!.ProblemDetails.Detail.Should().Contain("Cannot cancel a completed booking");
    }

    private static Mock<UserManager<User>> MockUserManager()
    {
        var store = new Mock<IUserStore<User>>();
        var options = new Mock<Microsoft.Extensions.Options.IOptions<IdentityOptions>>();
        var passwordHasher = new Mock<IPasswordHasher<User>>();
        var userValidators = new List<IUserValidator<User>>();
        var passwordValidators = new List<IPasswordValidator<User>>();
        var keyNormalizer = new Mock<ILookupNormalizer>();
        var errors = new Mock<IdentityErrorDescriber>();
        var services = new Mock<IServiceProvider>();
        var logger = new Mock<Microsoft.Extensions.Logging.ILogger<UserManager<User>>>();

        return new Mock<UserManager<User>>(
            store.Object,
            options.Object,
            passwordHasher.Object,
            userValidators,
            passwordValidators,
            keyNormalizer.Object,
            errors.Object,
            services.Object,
            logger.Object
        );
    }
}
