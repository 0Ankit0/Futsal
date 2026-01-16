using System.Linq.Expressions;
using System.Security.Claims;

using FutsalApi.Data.Models;
using FutsalApi.ApiService.Repositories;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Moq;
using FluentAssertions;
using FutsalApi.Data.DTO;
using FutsalApi.Data.Models;
using FutsalApi.ApiService.Data;

namespace FutsalApi.Tests;

public class ReviewApiEndpointsTests
{
    private readonly Mock<IReviewRepository> _repositoryMock;
    private readonly Mock<UserManager<User>> _userManagerMock;
    private readonly Mock<IFutsalGroundRepository> _groundRepositoryMock;
    private readonly Mock<IBookingRepository> _bookingRepositoryMock;
    private readonly Mock<AppDbContext> _dbContextMock;
    private readonly ReviewApiEndpoints _endpoints;

    public ReviewApiEndpointsTests()
    {
        _repositoryMock = new Mock<IReviewRepository>();
        _groundRepositoryMock = new Mock<IFutsalGroundRepository>();
        _bookingRepositoryMock = new Mock<IBookingRepository>();
        _dbContextMock = new Mock<AppDbContext>();
        _userManagerMock = MockUserManager();
        _endpoints = new ReviewApiEndpoints();
    }

    [Fact]
    public async Task GetAllReviewsByUserId_ReturnsOk_WhenValid()
    {
        // Arrange
        var user = new User { Id = "user1" };
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        var reviews = new List<ReviewResponse>
        {
            new ReviewResponse { Id = 1, UserId = "user1", GroundId = 1, GroundName = "Ground1", GroundImageUrl = "url1", Rating = 5, Comment = "Great!" }
        };
        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _repositoryMock.Setup(r => r.GetAllByUserAsync(user.Id, 1, 10)).ReturnsAsync(reviews);

        // Act
        var result = await _endpoints.GetAllReviewsByUserId(_repositoryMock.Object, _userManagerMock.Object, claimsPrincipal, 1, 10);

        // Assert
        result.Should().BeOfType<Results<Ok<IEnumerable<ReviewResponse>>, ProblemHttpResult>>();
        if (result is Results<Ok<IEnumerable<ReviewResponse>>, ProblemHttpResult> { Result: Ok<IEnumerable<ReviewResponse>> okResult })
        {
            okResult.Value.Should().BeEquivalentTo(reviews);
        }
    }

    [Fact]
    public async Task GetAllReviewsByUserId_ReturnsProblem_WhenInvalidPage()
    {
        // Arrange
        var user = new User { Id = "user1" };
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);

        // Act
        var result = await _endpoints.GetAllReviewsByUserId(_repositoryMock.Object, _userManagerMock.Object, claimsPrincipal, 0, 10);

        // Assert
        result.Should().BeOfType<Results<Ok<IEnumerable<ReviewResponse>>, ProblemHttpResult>>();
        if (result is Results<Ok<IEnumerable<ReviewResponse>>, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("Page and pageSize must be greater than 0.");
        }
    }

    [Fact]
    public async Task GetReviewsByGroundId_ReturnsOk_WhenValid()
    {
        // Arrange
        var reviews = new List<ReviewResponse>
        {
            new ReviewResponse { Id = 1, UserId = "user1", GroundId = 1, GroundName = "Ground1", GroundImageUrl = "url1", Rating = 5, Comment = "Great!" }
        };
        _repositoryMock.Setup(r => r.GetReviewsByGroundIdAsync(1, 1, 10)).ReturnsAsync(reviews);

        // Act
        var result = await _endpoints.GetReviewsByGroundId(_repositoryMock.Object, 1, 1, 10);

        // Assert
        result.Should().BeOfType<Results<Ok<IEnumerable<ReviewResponse>>, ProblemHttpResult>>();
        if (result is Results<Ok<IEnumerable<ReviewResponse>>, ProblemHttpResult> { Result: Ok<IEnumerable<ReviewResponse>> okResult })
        {
            okResult.Value.Should().BeEquivalentTo(reviews);
        }
    }

    [Fact]
    public async Task GetReviewById_ReturnsOk_WhenFound()
    {
        // Arrange
        var review = new ReviewResponse { Id = 1, UserId = "user1", GroundId = 1, GroundName = "Ground1", GroundImageUrl = "url1", Rating = 5, Comment = "Great!" };
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync(review);

        // Act
        var result = await _endpoints.GetReviewById(_repositoryMock.Object, 1);

        // Assert
        result.Should().BeOfType<Results<Ok<ReviewResponse>, NotFound, ProblemHttpResult>>();
        if (result is Results<Ok<ReviewResponse>, NotFound, ProblemHttpResult> { Result: Ok<ReviewResponse> okResult })
        {
            okResult.Value.Should().BeEquivalentTo(review);
        }
    }

    [Fact]
    public async Task GetReviewById_ReturnsNotFound_WhenNotFound()
    {
        // Arrange
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync((ReviewResponse?)null);

        // Act
        var result = await _endpoints.GetReviewById(_repositoryMock.Object, 1);

        // Assert
        result.Should().BeOfType<Results<Ok<ReviewResponse>, NotFound, ProblemHttpResult>>();
        if (result is Results<Ok<ReviewResponse>, NotFound, ProblemHttpResult> { Result: NotFound })
        {
            result.Result.Should().BeOfType<NotFound>();
        }
    }

    [Fact]
    public async Task CreateReview_ReturnsOk_WhenCreated()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        var user = new User { Id = "user1" };
        var booking = new Booking { Id = 1, UserId = "user1", GroundId = 1 };
        var reviewRequest = new CreateReviewRequest { BookingId = 1, Rating = 5, Comment = "Great!" };
        var review = new Review { Id = 1, UserId = "user1", GroundId = 1, Rating = 5, Comment = "Great!" };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _bookingRepositoryMock.Setup(br => br.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>())).ReturnsAsync(booking);
        _bookingRepositoryMock.Setup(br => br.HasValidBookingForReviewAsync(1, "user1")).ReturnsAsync(true);
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync((Review?)null);
        _repositoryMock.Setup(r => r.CreateReviewAsync(It.IsAny<Review>())).ReturnsAsync(1);

        // Act
        var result = await _endpoints.CreateReview(
            _repositoryMock.Object,
            _bookingRepositoryMock.Object,
            _dbContextMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            reviewRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult>>();
        if (result is Results<Ok<string>, ProblemHttpResult> { Result: Ok<string> okResult })
        {
            okResult.Value.Should().Be("Review created successfully.");
        }
    }

    [Fact]
    public async Task CreateReview_ReturnsProblem_WhenUserNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal();
        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync((User?)null);
        var reviewRequest = new CreateReviewRequest { BookingId = 1, Rating = 5, Comment = "Great!" };

        // Act
        var result = await _endpoints.CreateReview(
            _repositoryMock.Object,
            _bookingRepositoryMock.Object,
            _dbContextMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            reviewRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult>>();
        if (result is Results<Ok<string>, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("User not found.");
        }
    }

    [Fact]
    public async Task CreateReview_ReturnsProblem_WhenAlreadyReviewed()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        var user = new User { Id = "user1" };
        var booking = new Booking { Id = 1, UserId = "user1", GroundId = 1 };
        var reviewRequest = new CreateReviewRequest { BookingId = 1, Rating = 5, Comment = "Great!" };
        var existingReview = new Review { Id = 2, UserId = "user1", GroundId = 1, Rating = 4, Comment = "Nice" };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _bookingRepositoryMock.Setup(br => br.GetByIdAsync(It.IsAny<Expression<Func<Booking, bool>>>())).ReturnsAsync(booking);
        _bookingRepositoryMock.Setup(br => br.HasValidBookingForReviewAsync(1, "user1")).ReturnsAsync(true);
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync(existingReview);

        // Act
        var result = await _endpoints.CreateReview(
            _repositoryMock.Object,
            _bookingRepositoryMock.Object,
            _dbContextMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            reviewRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, ProblemHttpResult>>();
        if (result is Results<Ok<string>, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("You have already reviewed this ground.");
        }
    }

    [Fact]
    public async Task UpdateReview_ReturnsOk_WhenUpdated()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        var user = new User { Id = "user1" };
        var booking = new Booking { Id = 1, UserId = "user1", GroundId = 1 };
        var reviewRequest = new ReviewRequest { GroundId = 1, Rating = 4, Comment = "Good!" };
        var existingReview = new Review { Id = 1, UserId = "user1", GroundId = 1, Rating = 5, Comment = "Great!" };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync(existingReview);

        // Act
        var result = await _endpoints.UpdateReview(
            _repositoryMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            1,
            reviewRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, NotFound, ProblemHttpResult>>();
        if (result is Results<Ok<string>, NotFound, ProblemHttpResult> { Result: Ok<string> okResult })
        {
            okResult.Value.Should().Be("Review updated successfully.");
        }
    }

    [Fact]
    public async Task UpdateReview_ReturnsProblem_WhenUserNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal();
        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync((User?)null);
        var reviewRequest = new ReviewRequest { GroundId = 1, Rating = 4, Comment = "Good!" };

        // Act
        var result = await _endpoints.UpdateReview(
            _repositoryMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            1,
            reviewRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, NotFound, ProblemHttpResult>>();
        if (result is Results<Ok<string>, NotFound, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("User not found.");
        }
    }

    [Fact]
    public async Task UpdateReview_ReturnsNotFound_WhenReviewNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        var user = new User { Id = "user1" };
        var reviewRequest = new ReviewRequest { GroundId = 1, Rating = 4, Comment = "Good!" };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync((Review?)null);

        // Act
        var result = await _endpoints.UpdateReview(
            _repositoryMock.Object,
            _userManagerMock.Object,
            claimsPrincipal,
            1,
            reviewRequest);

        // Assert
        result.Should().BeOfType<Results<Ok<string>, NotFound, ProblemHttpResult>>();
        if (result is Results<Ok<string>, NotFound, ProblemHttpResult> { Result: NotFound })
        {
            result.Result.Should().BeOfType<NotFound>();
        }
    }

    [Fact]
    public async Task DeleteReview_ReturnsNoContent_WhenDeleted()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        var user = new User { Id = "user1" };
        var existingReview = new ReviewResponse { Id = 1, UserId = "user1", GroundId = 1, GroundName = "Ground1", GroundImageUrl = "url1", Rating = 5, Comment = "Great!" };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync(existingReview);
        _repositoryMock.Setup(r => r.DeleteReviewByUserAsync(1, user.Id)).ReturnsAsync(true);

        // Act
        var result = await _endpoints.DeleteReview(_repositoryMock.Object, _groundRepositoryMock.Object, _userManagerMock.Object, claimsPrincipal, 1);

        // Assert
        result.Should().BeOfType<Results<NoContent, NotFound, ProblemHttpResult>>();
        if (result is Results<NoContent, NotFound, ProblemHttpResult> { Result: NoContent noContentResult })
        {
            noContentResult.Should().BeOfType<NoContent>();
        }
    }

    [Fact]
    public async Task DeleteReview_ReturnsProblem_WhenUserNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal();
        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync((User?)null);

        // Act
        var result = await _endpoints.DeleteReview(_repositoryMock.Object, _groundRepositoryMock.Object, _userManagerMock.Object, claimsPrincipal, 1);

        // Assert
        result.Should().BeOfType<Results<NoContent, NotFound, ProblemHttpResult>>();
        if (result is Results<NoContent, NotFound, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("User not found.");
        }
    }

    [Fact]
    public async Task DeleteReview_ReturnsNotFound_WhenReviewNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        var user = new User { Id = "user1" };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync((ReviewResponse?)null);

        // Act
        var result = await _endpoints.DeleteReview(_repositoryMock.Object, _groundRepositoryMock.Object, _userManagerMock.Object, claimsPrincipal, 1);

        // Assert
        result.Should().BeOfType<Results<NoContent, NotFound, ProblemHttpResult>>();
        if (result is Results<NoContent, NotFound, ProblemHttpResult> { Result: NotFound })
        {
            result.Result.Should().BeOfType<NotFound>();
        }
    }

    [Fact]
    public async Task DeleteReview_ReturnsProblem_WhenDeleteFails()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal(new ClaimsIdentity(new Claim[] { new Claim(ClaimTypes.NameIdentifier, "user1") }));
        var user = new User { Id = "user1" };
        var existingReview = new ReviewResponse { Id = 1, UserId = "user1", GroundId = 1, GroundName = "Ground1", GroundImageUrl = "url1", Rating = 5, Comment = "Great!" };

        _userManagerMock.Setup(um => um.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<Expression<Func<Review, bool>>>())).ReturnsAsync(existingReview);
        _repositoryMock.Setup(r => r.DeleteReviewByUserAsync(1, user.Id)).ReturnsAsync(false);

        // Act
        var result = await _endpoints.DeleteReview(_repositoryMock.Object, _groundRepositoryMock.Object, _userManagerMock.Object, claimsPrincipal, 1);

        // Assert
        result.Should().BeOfType<Results<NoContent, NotFound, ProblemHttpResult>>();
        if (result is Results<NoContent, NotFound, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("Failed to delete the review.");
        }
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
