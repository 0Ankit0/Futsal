using System;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;


using FutsalApi.Data.DTO;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Options;

using Moq;

using Xunit;
using FluentAssertions;

using Microsoft.AspNetCore.Http.HttpResults;
using FutsalApi.Data.Models;
using FutsalApi.ApiService.Routes;
using Auth;






namespace FutsalApi.Tests;

public class AuthApiEndpointsTests
{
    private readonly AuthApiEndpointRouteBuilderExtensions _authApi;
    private readonly Mock<UserManager<User>> _userManagerMock;
    private readonly Mock<IUserStore<User>> _userStoreMock;
    private readonly Mock<IEmailSender<User>> _emailSenderMock;
    private readonly Mock<LinkGenerator> _linkGeneratorMock;
    private readonly Mock<IServiceProvider> _serviceProviderMock;
    private readonly Mock<SignInManager<User>> _signInManagerMock;

    public AuthApiEndpointsTests()
    {
        _authApi = new AuthApiEndpointRouteBuilderExtensions();

        _userStoreMock = new Mock<IUserStore<User>>();
        _userManagerMock = MockUserManager();
        _emailSenderMock = new Mock<IEmailSender<User>>();
        _linkGeneratorMock = new Mock<LinkGenerator>();
        _serviceProviderMock = new Mock<IServiceProvider>();

        // Ensure the user store supports email
        var userEmailStoreMock = _userStoreMock.As<IUserEmailStore<User>>();
        _userManagerMock.Setup(x => x.SupportsUserEmail).Returns(true);

        _signInManagerMock = MockSignInManager(_userManagerMock.Object);
    }

    [Fact]
    public async Task RegisterUser_InvalidEmail_ReturnsValidationProblem()
    {
        // Arrange
        var registration = new RegisterRequest { Email = "invalid", FirstName = "Test", LastName = "User", Password = "Password123!" };
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _serviceProviderMock.Setup(x => x.GetService(typeof(IUserStore<User>))).Returns(_userStoreMock.Object);

        // Setup ErrorDescriber to avoid NullReferenceException
        var errorDescriber = new IdentityErrorDescriber();
        _userManagerMock.Object.ErrorDescriber = errorDescriber;

        // Act
        var result = await _authApi.RegisterUser(
            registration,
            new DefaultHttpContext(),
            _serviceProviderMock.Object,
            _linkGeneratorMock.Object,
            _emailSenderMock.Object
        );

        // Assert
        result.Result.Should().BeOfType<ValidationProblem>();
    }

    [Fact]
    public async Task RegisterUser_ValidEmail_ReturnsOk()
    {
        // Arrange
        var registration = new RegisterRequest { Email = "test@example.com", FirstName = "Test", LastName = "User", Password = "Password123!" };
        var emailStore = new Mock<IUserEmailStore<User>>();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _serviceProviderMock.Setup(x => x.GetService(typeof(IUserStore<User>))).Returns(emailStore.Object);

        _userManagerMock.Setup(x => x.SupportsUserEmail).Returns(true);
        _userManagerMock.Setup(x => x.CreateAsync(It.IsAny<User>(), It.IsAny<string>()))
            .ReturnsAsync(IdentityResult.Success);

        emailStore.Setup(x => x.SetUserNameAsync(It.IsAny<User>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        emailStore.Setup(x => x.SetEmailAsync(It.IsAny<User>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        // Provide a valid token for confirmation
        _userManagerMock.Setup(x => x.GenerateEmailConfirmationTokenAsync(It.IsAny<User>()))
            .ReturnsAsync("dummy-confirm-token");

        // Provide a valid endpoint name and mock LinkGenerator to avoid NotSupportedException


        // Fix the LinkGenerator mock to use the correct parameter types
        _linkGeneratorMock
            .Setup(x => x.GetUriByAddress(
                It.IsAny<HttpContext>(),
                It.IsAny<object>(),
                It.IsAny<RouteValueDictionary>(),
                It.IsAny<RouteValueDictionary?>(),
                It.IsAny<string?>(),
                It.IsAny<HostString?>(),
                It.IsAny<PathString?>(),
                It.IsAny<FragmentString>(),
                It.IsAny<LinkOptions?>()
            ))
            .Returns("https://localhost/confirmEmail?userId=1&code=abc");

        // Act
        var result = await _authApi.RegisterUser(
            registration,
            new DefaultHttpContext(),
            _serviceProviderMock.Object,
            _linkGeneratorMock.Object,
            _emailSenderMock.Object
        );

        // Assert
        result.Result.Should().BeOfType<Ok>();
    }


    [Fact]
    public async Task RegisterUser_MissingFirstName_ReturnsValidationProblem()
    {
        // Arrange
        var registration = new RegisterRequest
        {
            Email = "test@example.com",
            FirstName = "",
            LastName = "User",
            Password = "Password123!"
        };

        var emailStore = new Mock<IUserEmailStore<User>>();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _serviceProviderMock.Setup(x => x.GetService(typeof(IUserStore<User>))).Returns(emailStore.Object);

        // Act
        var result = await _authApi.RegisterUser(
            registration,
            new DefaultHttpContext(),
            _serviceProviderMock.Object,
            _linkGeneratorMock.Object,
            _emailSenderMock.Object
        );

        // Assert
        result.Result.Should().BeOfType<ValidationProblem>();
        _userManagerMock.Verify(x => x.CreateAsync(It.IsAny<User>(), It.IsAny<string>()), Times.Never);
    }

    [Fact]
    public async Task LoginUser_InvalidCredentials_ReturnsProblem()
    {
        // Arrange
        var login = new LoginRequest { Email = "test@example.com", Password = "wrong" };
        _serviceProviderMock.Setup(x => x.GetService(typeof(SignInManager<User>))).Returns(_signInManagerMock.Object);

        _signInManagerMock.Setup(x => x.PasswordSignInAsync(
            It.IsAny<string>(), It.IsAny<string>(), It.IsAny<bool>(), It.IsAny<bool>()))
            .ReturnsAsync(Microsoft.AspNetCore.Identity.SignInResult.Failed);

        // Act
        var result = await _authApi.LoginUser(
            login, false, false, _serviceProviderMock.Object
        );

        // Assert
        result.Result.Should().BeOfType<ProblemHttpResult>();
    }

    [Fact]
    public async Task LoginUser_ValidCredentials_ReturnsEmpty()
    {
        // Arrange
        var login = new LoginRequest { Email = "test@example.com", Password = "Password123!" };
        _serviceProviderMock.Setup(x => x.GetService(typeof(SignInManager<User>))).Returns(_signInManagerMock.Object);

        _signInManagerMock.Setup(x => x.PasswordSignInAsync(
            It.IsAny<string>(), It.IsAny<string>(), It.IsAny<bool>(), It.IsAny<bool>()))
            .ReturnsAsync(Microsoft.AspNetCore.Identity.SignInResult.Success);

        // Act
        var result = await _authApi.LoginUser(
            login, false, false, _serviceProviderMock.Object
        );

        // Assert
        result.Result.Should().BeOfType<EmptyHttpResult>();
    }

    [Fact]
    public async Task GetUserInfo_UserNotFound_ReturnsNotFound()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);

        _userManagerMock.Setup(x => x.GetUserAsync(It.IsAny<ClaimsPrincipal>()))
            .ReturnsAsync((User?)null);

        // Act
        var result = await _authApi.GetUserInfo(claimsPrincipal, _serviceProviderMock.Object, new Mock<AppDbContext>().Object);

        // Assert
        result.Result.Should().BeOfType<NotFound>();
    }

    [Fact]
    public async Task GetUserInfo_UserFound_ReturnsOk()
    {
        // Arrange
        var claimsPrincipal = new ClaimsPrincipal();
        var user = new User { Email = "test@example.com" };
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);

        _userManagerMock.Setup(x => x.GetUserAsync(It.IsAny<ClaimsPrincipal>()))
            .ReturnsAsync(user);
        _userManagerMock.Setup(x => x.GetEmailAsync(user)).ReturnsAsync(user.Email);
        _userManagerMock.Setup(x => x.IsEmailConfirmedAsync(user)).ReturnsAsync(true);

        // Act
        var result = await _authApi.GetUserInfo(claimsPrincipal, _serviceProviderMock.Object, new Mock<AppDbContext>().Object);

        // Assert
        result.Result.Should().BeOfType<Ok<InfoResponse>>();
    }

    [Fact]
    public async Task LogoutUser_ReturnsOk()
    {
        _serviceProviderMock.Setup(x => x.GetService(typeof(SignInManager<User>))).Returns(_signInManagerMock.Object);
        _signInManagerMock.Setup(x => x.SignOutAsync()).Returns(Task.CompletedTask);

        var result = await _authApi.LogoutUser(false, false, _serviceProviderMock.Object);

        result.Result.Should().BeOfType<Ok>();
    }

    [Fact]
    public async Task ForgotPassword_UserNotFound_ReturnsOk()
    {
        var request = new ForgotPasswordRequest { Email = "notfound@example.com" };
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email)).ReturnsAsync((User?)null);

        var result = await _authApi.ForgotPassword(request, _serviceProviderMock.Object);

        result.Result.Should().BeOfType<Ok>();
    }

    [Fact]
    public async Task ForgotPassword_UserFoundAndConfirmed_SendsEmail_ReturnsOk()
    {
        var request = new ForgotPasswordRequest { Email = "found@example.com" };
        var user = new User { Email = request.Email };
        var emailSenderMock = new Mock<IEmailSender<User>>();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _serviceProviderMock.Setup(x => x.GetService(typeof(IEmailSender<User>))).Returns(emailSenderMock.Object);
        _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email)).ReturnsAsync(user);
        _userManagerMock.Setup(x => x.IsEmailConfirmedAsync(user)).ReturnsAsync(true);
        _userManagerMock.Setup(x => x.GeneratePasswordResetTokenAsync(user)).ReturnsAsync("reset-token");

        emailSenderMock.Setup(x => x.SendPasswordResetCodeAsync(user, request.Email, It.IsAny<string>()))
            .Returns(Task.CompletedTask);

        var result = await _authApi.ForgotPassword(request, _serviceProviderMock.Object);

        result.Result.Should().BeOfType<Ok>();
        emailSenderMock.Verify(x => x.SendPasswordResetCodeAsync(user, request.Email, It.IsAny<string>()), Times.Once);
    }

    [Fact]
    public async Task ResetPassword_UserNotFound_ReturnsValidationProblem()
    {
        var request = new ResetPasswordRequest { Email = "notfound@example.com", ResetCode = "code", NewPassword = "pass" };
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email)).ReturnsAsync((User?)null);

        // Mock the IdentityResult creation to avoid NullReferenceException in CreateValidationProblem
        var identityError = new IdentityError { Code = "InvalidToken", Description = "Invalid token." };
        var identityResult = IdentityResult.Failed(identityError);

        // Setup the userManager.ErrorDescriber.InvalidToken() to return a valid error
        var errorDescriber = new IdentityErrorDescriber();
        _userManagerMock.Object.ErrorDescriber = errorDescriber;

        // Create a valid IdentityResult for validation to avoid null reference inside CreateValidationProblem
        _userManagerMock.Setup(x => x.ResetPasswordAsync(It.IsAny<User>(), It.IsAny<string>(), It.IsAny<string>()))
            .ReturnsAsync(identityResult);

        var result = await _authApi.ResetPassword(request, _serviceProviderMock.Object);

        result.Result.Should().BeOfType<ValidationProblem>();
    }

    [Fact]
    public async Task ResetPassword_InvalidToken_ReturnsValidationProblem()
    {
        var request = new ResetPasswordRequest { Email = "user@example.com", ResetCode = "!!!", NewPassword = "pass" };
        var user = new User { Email = request.Email };
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email)).ReturnsAsync(user);
        _userManagerMock.Setup(x => x.IsEmailConfirmedAsync(user)).ReturnsAsync(true);

        // Ensure ErrorDescriber is set to avoid NullReferenceException
        _userManagerMock.Object.ErrorDescriber = new IdentityErrorDescriber();

        // Setup a mock identity result with errors for validation problem
        var identityError = new IdentityError { Code = "InvalidToken", Description = "The token is invalid." };
        _userManagerMock.Setup(x => x.ResetPasswordAsync(It.IsAny<User>(), It.IsAny<string>(), It.IsAny<string>()))
            .ReturnsAsync(IdentityResult.Failed(identityError));

        var result = await _authApi.ResetPassword(request, _serviceProviderMock.Object);

        result.Result.Should().BeOfType<ValidationProblem>();
    }

    [Fact]
    public async Task ResetPassword_Success_ReturnsOk()
    {
        var request = new ResetPasswordRequest
        {
            Email = "user@example.com",
            ResetCode = WebEncoders.Base64UrlEncode(System.Text.Encoding.UTF8.GetBytes("token")),
            NewPassword = "pass"
        };
        var user = new User { Email = request.Email };
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email)).ReturnsAsync(user);
        _userManagerMock.Setup(x => x.IsEmailConfirmedAsync(user)).ReturnsAsync(true);
        _userManagerMock.Setup(x => x.ResetPasswordAsync(user, "token", request.NewPassword)).ReturnsAsync(IdentityResult.Success);

        var result = await _authApi.ResetPassword(
            new ResetPasswordRequest
            {
                Email = request.Email,
                ResetCode = WebEncoders.Base64UrlEncode(System.Text.Encoding.UTF8.GetBytes("token")),
                NewPassword = "pass"
            },
            _serviceProviderMock.Object);

        result.Result.Should().BeOfType<Ok>();
    }

    [Fact]
    public async Task DeactivateUser_UserNotFound_ReturnsProblem()
    {
        var claimsPrincipal = new ClaimsPrincipal();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.GetUserAsync(claimsPrincipal)).ReturnsAsync((User?)null);

        var result = await _authApi.DeactivateUser(claimsPrincipal, _serviceProviderMock.Object);

        result.Result.Should().BeOfType<ProblemHttpResult>();
    }

    [Fact]
    public async Task DeactivateUser_UserNotConfirmed_ReturnsProblem()
    {
        var claimsPrincipal = new ClaimsPrincipal();
        var user = new User();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _userManagerMock.Setup(x => x.IsEmailConfirmedAsync(user)).ReturnsAsync(false);

        var result = await _authApi.DeactivateUser(claimsPrincipal, _serviceProviderMock.Object);

        result.Result.Should().BeOfType<ProblemHttpResult>();
    }

    [Fact]
    public async Task DeactivateUser_Success_ReturnsOk()
    {
        var claimsPrincipal = new ClaimsPrincipal();
        var user = new User();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.GetUserAsync(claimsPrincipal)).ReturnsAsync(user);
        _userManagerMock.Setup(x => x.IsEmailConfirmedAsync(user)).ReturnsAsync(true);
        _userManagerMock.Setup(x => x.SetLockoutEnabledAsync(user, true)).ReturnsAsync(IdentityResult.Success);
        _userManagerMock.Setup(x => x.SetLockoutEndDateAsync(user, It.IsAny<DateTimeOffset?>())).ReturnsAsync(IdentityResult.Success);

        var result = await _authApi.DeactivateUser(claimsPrincipal, _serviceProviderMock.Object);

        result.Result.Should().BeOfType<Ok>();
    }

    [Fact]
    public async Task RevalidateUser_UserNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "nonexistent";
        var code = "dummycode";
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync((User?)null);

        // Act
        var result = await _authApi.RevalidateUserByLink(userId, code, _serviceProviderMock.Object);

        // Assert
        result.Result.Should().BeOfType<ProblemHttpResult>();
    }

    [Fact]
    public async Task RevalidateUser_UserNotConfirmed_ReturnsProblem()
    {
        // Arrange
        var userId = "someuser";
        var code = "dummycode";
        var user = new User();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(user);
        _userManagerMock.Setup(x => x.IsEmailConfirmedAsync(user)).ReturnsAsync(false);

        // Act
        var result = await _authApi.RevalidateUserByLink(userId, code, _serviceProviderMock.Object);

        // Assert
        result.Result.Should().BeOfType<ProblemHttpResult>();
    }

    [Fact]
    public async Task RevalidateUser_Success_ReturnsOk()
    {
        // Arrange
        var userId = "someuser";
        var code = "dummycode";
        var user = new User();
        _serviceProviderMock.Setup(x => x.GetService(typeof(UserManager<User>))).Returns(_userManagerMock.Object);
        _userManagerMock.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(user);
        _userManagerMock.Setup(x => x.IsEmailConfirmedAsync(user)).ReturnsAsync(true);
        // Simulate successful revalidation (e.g., whatever the endpoint expects)
        // If the endpoint checks a token/code, you may want to mock that as well if needed

        // Act
        var result = await _authApi.RevalidateUserByLink(userId, code, _serviceProviderMock.Object);

        // Assert
        result.Result.Should().BeOfType<ProblemHttpResult>();
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

    private static Mock<SignInManager<User>> MockSignInManager(UserManager<User> userManager)
    {
        var contextAccessor = new Mock<IHttpContextAccessor>();
        var claimsFactory = new Mock<IUserClaimsPrincipalFactory<User>>();
        var options = new Mock<IOptions<IdentityOptions>>();
        var logger = new Mock<Microsoft.Extensions.Logging.ILogger<SignInManager<User>>>();
        var schemes = new Mock<Microsoft.AspNetCore.Authentication.IAuthenticationSchemeProvider>();
        var confirmation = new Mock<IUserConfirmation<User>>();

        return new Mock<SignInManager<User>>(
            userManager,
            contextAccessor.Object,
            claimsFactory.Object,
            options.Object,
            logger.Object,
            schemes.Object,
            confirmation.Object
        );
    }
}
