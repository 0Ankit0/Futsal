// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

using System.ComponentModel.DataAnnotations;
using System.Diagnostics;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;

using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Http.Metadata;


using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Options;
using FutsalApi.Data.Models; 
using Auth; 
using FutsalApi.Data.DTO;
using Google.Apis.Auth;
using FutsalApi.ApiService.Services;



[assembly: InternalsVisibleTo("FutsalApi.Tests")]
namespace FutsalApi.ApiService.Routes;

public class AuthApiEndpointRouteBuilderExtensions
{
    private readonly EmailAddressAttribute _emailAddressAttribute = new();

    private readonly string confirmEmailEndpointName = "ConfirmEmail";
    public void MapEndpoint(IEndpointRouteBuilder endpoints)
    {
        ArgumentNullException.ThrowIfNull(endpoints);

        var timeProvider = endpoints.ServiceProvider.GetRequiredService<TimeProvider>();
        var bearerTokenOptions = endpoints.ServiceProvider.GetRequiredService<IOptionsMonitor<BearerTokenOptions>>();
        var emailSender = endpoints.ServiceProvider.GetRequiredService<IEmailSender<User>>();
        var linkGenerator = endpoints.ServiceProvider.GetRequiredService<LinkGenerator>();


        var routeGroup = endpoints.MapGroup("User")
            .WithTags("User");

        routeGroup.MapPost("/register", RegisterUser)
        .WithName("RegisterUser")
        .WithSummary("Registers a new user.")
        .WithDescription("Creates a new user account with the provided email and password.")
        .Accepts<RegisterRequest>("application/json")
        .Produces<Ok>(StatusCodes.Status200OK)
        .Produces<ValidationProblem>(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPost("/login", LoginUser)
        .WithName("LoginUser")
        .WithSummary("Logs in a user.")
        .WithDescription("Authenticates a user with the provided email and password.")
        .Accepts<LoginRequest>("application/json")
        .Produces<Ok<AccessTokenResponse>>(StatusCodes.Status200OK)
        .Produces<EmptyHttpResult>(StatusCodes.Status204NoContent)
        .ProducesProblem(StatusCodes.Status401Unauthorized)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPost("/google", GoogleTokenLogin)
        .WithName("GoogleTokenLogin")
        .WithSummary("Authenticates user with Google ID token.")
        .WithDescription("Verifies Google ID token from Flutter app and creates/logs in user.")
        .Accepts<GoogleTokenRequest>("application/json")
        .Produces<Ok<AccessTokenResponse>>(StatusCodes.Status200OK)
        .Produces<EmptyHttpResult>(StatusCodes.Status204NoContent)
        .ProducesProblem(StatusCodes.Status401Unauthorized)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPost("/logout", LogoutUser)
        .WithName("LogoutUser")
        .WithSummary("Logs out a user.")
        .WithDescription("Logs out the user and invalidates the authentication cookie or bearer token.")
        .Produces<Ok>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPost("/refresh", RefreshToken)
        .WithName("RefreshToken")
        .WithSummary("Refreshes the access token using the refresh token.")
        .WithDescription("Generates a new access token using the provided refresh token.")
        .Accepts<RefreshRequest>("application/json")
        .Produces<Ok<AccessTokenResponse>>(StatusCodes.Status200OK)
        .Produces<UnauthorizedHttpResult>(StatusCodes.Status401Unauthorized)
        .Produces<SignInHttpResult>(StatusCodes.Status200OK)
        .Produces<ChallengeHttpResult>(StatusCodes.Status401Unauthorized);

        routeGroup.MapGet("/confirmEmail", ConfirmEmail)
        .WithName("ConfirmEmail")
        .WithSummary("Confirms the user's email address.")
        .WithDescription("Confirms the user's email address using the provided user ID and confirmation code.")
        .Produces<ContentHttpResult>(StatusCodes.Status200OK)
        .Produces<UnauthorizedHttpResult>(StatusCodes.Status401Unauthorized)
        .ProducesProblem(StatusCodes.Status500InternalServerError);
        // .Add(endpointBuilder =>
        // {
        //     var finalPattern = ((RouteEndpointBuilder)endpointBuilder).RoutePattern.RawText;
        //     confirmEmailEndpointName = $"{nameof(MapEndpoint)}-{finalPattern}";
        //     endpointBuilder.Metadata.Add(new EndpointNameMetadata(confirmEmailEndpointName));
        // });

        routeGroup.MapPost("/resendConfirmationEmail", ResendConfirmationEmail)
        .WithName("ResendConfirmationEmail")
        .WithSummary("Resends the email confirmation link.")
        .WithDescription("Resends the email confirmation link to the provided email address.")
        .Accepts<ResendConfirmationEmailRequest>("application/json")
        .Produces<Ok>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPost("/forgotPassword", ForgotPassword)
        .WithName("ForgotPassword")
        .WithSummary("Sends a password reset code to the user's email.")
        .WithDescription("Sends a password reset code to the provided email address.")
        .Accepts<ForgotPasswordRequest>("application/json")
        .Produces<Ok>(StatusCodes.Status200OK)
        .Produces<ValidationProblem>(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPost("/resetPassword", ResetPassword)
        .WithName("ResetPassword")
        .WithSummary("Resets the user's password.")
        .WithDescription("Resets the user's password using the provided email, reset code, and new password.")
        .Accepts<ResetPasswordRequest>("application/json")
        .Produces<Ok>(StatusCodes.Status200OK)
        .Produces<ValidationProblem>(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        routeGroup.MapPost("/verifyResetCode", VerifyResetCode)
        .WithName("VerifyResetCode")
        .WithSummary("Verifies the password reset code for a user.")
        .WithDescription("Checks if the provided reset code is valid for the given email.")
        .Accepts<VerifyResetCodeRequest>("application/json")
        .Produces<Ok>(StatusCodes.Status200OK)
        .Produces<ValidationProblem>(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        var accountGroup = routeGroup.MapGroup("/manage").RequireAuthorization();

        accountGroup.MapPost("/deactivate", DeactivateUser)
        .WithName("DeactivateUser")
        .WithSummary("Deactivate a user.")
        .WithDescription("Deactivate a user account.")
        .Produces<Ok>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        accountGroup.MapPost("/sendRevalidateEmail", SendRevalidateEmailEndpoint)
        .WithName("SendRevalidateEmail")
        .WithSummary("Sends a revalidation link to the user's email.")
        .WithDescription("Sends a revalidation link to the provided email address for account revalidation.")
        .Accepts<ResendConfirmationEmailRequest>("application/json")
        .AllowAnonymous()
        .Produces<Ok>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        accountGroup.MapGet("/revalidate", RevalidateUserByLink)
        .WithName("RevalidateUser")
        .WithSummary("Revalidates a user via email link.")
        .WithDescription("Revalidates a user account using a link sent to their email.")
        .AllowAnonymous()
        .Produces<ContentHttpResult>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        accountGroup.MapGet("/setup2fa", GenerateTwoFactorSetupCode)
        .WithName("GenerateTwoFactorSetupCode")
        .WithSummary("Generates a two-factor authentication setup code for the user.")
        .WithDescription("Generates a time-based one-time password (TOTP) for the user during the two-factor authentication setup process.")
        .Produces<Ok<string>>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);


        accountGroup.MapPost("/2fa", TwoFactor)
        .WithName("TwoFactor")
        .WithSummary("Enables or disables two-factor authentication (2FA) for the user.")
        .WithDescription("Enables or disables two-factor authentication (2FA) for the user.")
        .Accepts<TwoFactorRequest>("application/json")
        .Produces<Ok<TwoFactorResponse>>(StatusCodes.Status200OK)
        .Produces<ValidationProblem>(StatusCodes.Status400BadRequest)
        .Produces<NotFound>(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        accountGroup.MapGet("/info", GetUserInfo)
        .WithName("GetUserInfo")
        .WithSummary("Retrieves the user's information.")
        .WithDescription("Retrieves the user's information, including email and 2FA status.")
        .Produces<Ok<InfoResponse>>(StatusCodes.Status200OK)
        .Produces<ValidationProblem>(StatusCodes.Status400BadRequest)
        .Produces<NotFound>(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        accountGroup.MapPost("/info", UpdateUserInfo)
        .WithName("UpdateUserInfo")
        .WithSummary("Updates the user's information.")
        .WithDescription("Updates the user's information, including email and password.")
        .Accepts<InfoRequest>("application/json")
        .Produces<Ok<InfoResponse>>(StatusCodes.Status200OK)
        .Produces<ValidationProblem>(StatusCodes.Status400BadRequest)
        .Produces<NotFound>(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);
    }

    internal async Task SendConfirmationEmailAsync(
        User user,
        UserManager<User> userManager,
        HttpContext context,
        string email,
        string? confirmEmailEndpointName,
        LinkGenerator linkGenerator,
        IEmailSender<User> emailSender,
        bool isChange = false)
    {
        if (confirmEmailEndpointName is null)
        {
            throw new NotSupportedException("No email confirmation endpoint was registered!");
        }

        var code = isChange
            ? await userManager.GenerateChangeEmailTokenAsync(user, email)
            : await userManager.GenerateEmailConfirmationTokenAsync(user);
        code = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(code));

        var userId = await userManager.GetUserIdAsync(user);
        var routeValues = new RouteValueDictionary()
        {
            ["userId"] = userId,
            ["code"] = code,
        };

        if (isChange)
        {
            routeValues.Add("changedEmail", email);
        }

        var confirmEmailUrl = linkGenerator.GetUriByName(context, confirmEmailEndpointName, routeValues)
            ?? throw new NotSupportedException($"Could not find endpoint named '{confirmEmailEndpointName}'.");

        _ = emailSender.SendConfirmationLinkAsync(user, email, HtmlEncoder.Default.Encode(confirmEmailUrl));
    }

    internal async Task<Results<Ok, ValidationProblem>> RegisterUser(
        [FromBody] RegisterRequest registration,
        HttpContext context,
        [FromServices] IServiceProvider sp,
        // string? confirmEmailEndpointName,
        LinkGenerator linkGenerator,
        IEmailSender<User> emailSender)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        if (!userManager.SupportsUserEmail)
        {
            throw new NotSupportedException($"{nameof(MapEndpoint)} requires a user store with email support.");
        }
        var userStore = sp.GetRequiredService<IUserStore<User>>();
        var emailStore = (IUserEmailStore<User>)userStore;
        var validationErrors = ValidateRegisterRequest(registration);
        if (validationErrors is not null)
        {
            return TypedResults.ValidationProblem(validationErrors);
        }

        var email = registration.Email.Trim();
        var username = string.IsNullOrWhiteSpace(registration.UserName) ? email : registration.UserName.Trim();
        if (string.IsNullOrEmpty(email) || !_emailAddressAttribute.IsValid(email))
        {
            return CreateValidationProblem(IdentityResult.Failed(userManager.ErrorDescriber.InvalidEmail(email)));
        }
        var user = new User
        {
            FirstName = registration.FirstName.Trim(),
            LastName = registration.LastName.Trim()
        };
        await userStore.SetUserNameAsync(user, username, CancellationToken.None);
        await emailStore.SetEmailAsync(user, email, CancellationToken.None);
        var result = await userManager.CreateAsync(user, registration.Password);
        if (!result.Succeeded)
        {
            return CreateValidationProblem(result);
        }
        await SendConfirmationEmailAsync(user, userManager, context, email, confirmEmailEndpointName, linkGenerator, emailSender);
        return TypedResults.Ok();
    }

    private static Dictionary<string, string[]>? ValidateRegisterRequest(RegisterRequest registration)
    {
        var validationContext = new ValidationContext(registration);
        var validationResults = new List<ValidationResult>();
        var isValid = Validator.TryValidateObject(registration, validationContext, validationResults, true);

        if (!isValid)
        {
            return validationResults
                .SelectMany(result => result.MemberNames.DefaultIfEmpty(string.Empty)
                    .Select(memberName => new { memberName, result.ErrorMessage }))
                .GroupBy(x => x.memberName)
                .ToDictionary(
                    group => group.Key,
                    group => group.Select(x => x.ErrorMessage ?? "The field is invalid.").ToArray());
        }

        return null;
    }


    internal async Task<Results<Ok<AccessTokenResponse>, EmptyHttpResult, ProblemHttpResult>> LoginUser(
        [FromBody] LoginRequest login, [FromQuery] bool? useCookies, [FromQuery] bool? useSessionCookies, [FromServices] IServiceProvider sp)
    {
        var signInManager = sp.GetRequiredService<SignInManager<User>>();
        var userManager = sp.GetRequiredService<UserManager<User>>();
        
        var user = await userManager.FindByEmailAsync(login.Email);
        if (user == null)
        {
            return TypedResults.Problem("Invalid email or password.", statusCode: StatusCodes.Status401Unauthorized);
        }
        
        var useCookieScheme = (useCookies == true) || (useSessionCookies == true);
        var isPersistent = (useCookies == true) && (useSessionCookies != true);
        signInManager.AuthenticationScheme = useCookieScheme ? IdentityConstants.ApplicationScheme : IdentityConstants.BearerScheme;
        var result = await signInManager.PasswordSignInAsync(user.UserName!, login.Password, isPersistent, lockoutOnFailure: true);
        if (result.RequiresTwoFactor)
        {
            if (!string.IsNullOrEmpty(login.TwoFactorCode))
            {
                result = await signInManager.TwoFactorAuthenticatorSignInAsync(login.TwoFactorCode, isPersistent, rememberClient: isPersistent);
            }
            else if (!string.IsNullOrEmpty(login.TwoFactorRecoveryCode))
            {
                result = await signInManager.TwoFactorRecoveryCodeSignInAsync(login.TwoFactorRecoveryCode);
            }
            else
            {
                return TypedResults.Problem("Two-factor authentication is required. Please provide the two-factor code.", statusCode: StatusCodes.Status428PreconditionRequired);
            }
        }
        if (result.IsLockedOut)
        {
            return TypedResults.Problem("User account locked out.", statusCode: StatusCodes.Status423Locked);
        }
        if (!result.Succeeded)
        {
            return TypedResults.Problem(result.ToString(), statusCode: StatusCodes.Status401Unauthorized);
        }
        return TypedResults.Empty;
    }

    internal async Task<Results<Ok<AccessTokenResponse>, EmptyHttpResult, ProblemHttpResult>> GoogleTokenLogin(
        [FromBody] GoogleTokenRequest request, [FromQuery] bool? useCookies, [FromQuery] bool? useSessionCookies, [FromServices] IServiceProvider sp)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        var signInManager = sp.GetRequiredService<SignInManager<User>>();
        
        try
        {
            // Verify the Google ID token without audience validation
            // The Flutter app manages its own Google Sign-In with its own client ID
            var payload = await Google.Apis.Auth.GoogleJsonWebSignature.ValidateAsync(request.IdToken);

            if (payload == null || string.IsNullOrEmpty(payload.Email))
            {
                return TypedResults.Problem("Invalid Google token.", statusCode: StatusCodes.Status401Unauthorized);
            }

            // Find or create user
            var user = await userManager.FindByEmailAsync(payload.Email);
            if (user == null)
            {
                user = new User
                {
                    FirstName = payload.GivenName ?? "",
                    LastName = payload.FamilyName ?? "",
                    UserName = payload.Email,
                    Email = payload.Email,
                    EmailConfirmed = true // Google emails are already verified
                };
                
                var createResult = await userManager.CreateAsync(user);
                if (!createResult.Succeeded)
                {
                    return TypedResults.Problem("Failed to create user account.", statusCode: StatusCodes.Status500InternalServerError);
                }
            }

            // Sign in the user
            var useCookieScheme = (useCookies == true) || (useSessionCookies == true);
            var isPersistent = (useCookies == true) && (useSessionCookies != true);
            signInManager.AuthenticationScheme = useCookieScheme ? IdentityConstants.ApplicationScheme : IdentityConstants.BearerScheme;
            
            await signInManager.SignInAsync(user, isPersistent);
            
            return TypedResults.Empty;
        }
        catch (Exception ex)
        {
            return TypedResults.Problem($"Google authentication failed: {ex.Message}", statusCode: StatusCodes.Status401Unauthorized);
        }
    }

    internal async Task<Results<Ok, ProblemHttpResult>> LogoutUser(
        [FromQuery] bool? useCookies, [FromQuery] bool? useSessionCookies, [FromServices] IServiceProvider sp)
    {
        var signInManager = sp.GetRequiredService<SignInManager<User>>();
        var useCookieScheme = (useCookies == true) || (useSessionCookies == true);
        signInManager.AuthenticationScheme = useCookieScheme ? IdentityConstants.ApplicationScheme : IdentityConstants.BearerScheme;
        await signInManager.SignOutAsync();
        return TypedResults.Ok();
    }

    internal async Task<Results<Ok<AccessTokenResponse>, UnauthorizedHttpResult, SignInHttpResult, ChallengeHttpResult>> RefreshToken(
        [FromBody] RefreshRequest refreshRequest, [FromServices] IServiceProvider sp)
    {
        var signInManager = sp.GetRequiredService<SignInManager<User>>();
        var bearerTokenOptions = sp.GetRequiredService<IOptionsMonitor<BearerTokenOptions>>();
        var timeProvider = sp.GetRequiredService<TimeProvider>();
        var refreshTokenProtector = bearerTokenOptions.Get(IdentityConstants.BearerScheme).RefreshTokenProtector;
        var refreshTicket = refreshTokenProtector.Unprotect(refreshRequest.RefreshToken);
        if (refreshTicket?.Properties?.ExpiresUtc is not { } expiresUtc ||
            timeProvider.GetUtcNow() >= expiresUtc ||
            await signInManager.ValidateSecurityStampAsync(refreshTicket.Principal) is not User user)
        {
            return TypedResults.Challenge();
        }
        var newPrincipal = await signInManager.CreateUserPrincipalAsync(user);
        return TypedResults.SignIn(newPrincipal, authenticationScheme: IdentityConstants.BearerScheme);
    }

    internal async Task<Results<ContentHttpResult, UnauthorizedHttpResult>> ConfirmEmail(
        [FromQuery] string userId, [FromQuery] string code, [FromQuery] string? changedEmail, [FromServices] IServiceProvider sp)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        if (await userManager.FindByIdAsync(userId) is not { } user)
        {
            return TypedResults.Unauthorized();
        }
        try
        {
            code = Encoding.UTF8.GetString(WebEncoders.Base64UrlDecode(code));
        }
        catch (FormatException)
        {
            return TypedResults.Unauthorized();
        }
        IdentityResult result;
        if (string.IsNullOrEmpty(changedEmail))
        {
            result = await userManager.ConfirmEmailAsync(user, code);
        }
        else
        {
            result = await userManager.ChangeEmailAsync(user, changedEmail, code);
            if (result.Succeeded)
            {
                result = await userManager.SetUserNameAsync(user, changedEmail);
            }
        }
        if (!result.Succeeded)
        {
            return TypedResults.Unauthorized();
        }
        return TypedResults.Text("Thank you for confirming your email.");
    }

    internal async Task<Ok> ResendConfirmationEmail(
        [FromBody] ResendConfirmationEmailRequest resendRequest,
        HttpContext context,
        [FromServices] IServiceProvider sp,
        string? confirmEmailEndpointName,
        LinkGenerator linkGenerator,
        IEmailSender<User> emailSender)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        if (await userManager.FindByEmailAsync(resendRequest.Email) is not { } user)
        {
            return TypedResults.Ok();
        }
        await SendConfirmationEmailAsync(user, userManager, context, resendRequest.Email, confirmEmailEndpointName, linkGenerator, emailSender);
        return TypedResults.Ok();
    }

    internal async Task<Results<Ok, ValidationProblem>> ForgotPassword(
        [FromBody] ForgotPasswordRequest resetRequest, [FromServices] IServiceProvider sp)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        var user = await userManager.FindByEmailAsync(resetRequest.Email);
        if (user is not null && await userManager.IsEmailConfirmedAsync(user))
        {
            var code = await userManager.GeneratePasswordResetTokenAsync(user);
            code = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(code));
            var emailSender = sp.GetRequiredService<IEmailSender<User>>();
            _ = emailSender.SendPasswordResetCodeAsync(user, resetRequest.Email, HtmlEncoder.Default.Encode(code));
        }
        return TypedResults.Ok();
    }

    internal async Task<Results<Ok, ValidationProblem>> ResetPassword(
        [FromBody] ResetPasswordRequest resetRequest, [FromServices] IServiceProvider sp)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        var user = await userManager.FindByEmailAsync(resetRequest.Email);
        if (user is null || !(await userManager.IsEmailConfirmedAsync(user)))
        {
            return CreateValidationProblem(IdentityResult.Failed(userManager.ErrorDescriber.InvalidToken()));
        }
        IdentityResult result;
        try
        {
            var code = Encoding.UTF8.GetString(WebEncoders.Base64UrlDecode(resetRequest.ResetCode));
            result = await userManager.ResetPasswordAsync(user, code, resetRequest.NewPassword);
        }
        catch (FormatException)
        {
            result = IdentityResult.Failed(userManager.ErrorDescriber.InvalidToken());
        }
        if (!result.Succeeded)
        {
            return CreateValidationProblem(result);
        }
        return TypedResults.Ok();
    }

    internal async Task<Results<Ok, ValidationProblem>> VerifyResetCode(
        [FromBody] VerifyResetCodeRequest verifyRequest, [FromServices] IServiceProvider sp)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        var user = await userManager.FindByEmailAsync(verifyRequest.Email);
        if (user is null || !(await userManager.IsEmailConfirmedAsync(user)))
        {
            return CreateValidationProblem(IdentityResult.Failed(userManager.ErrorDescriber.InvalidToken()));
        }
        try
        {
            var code = Encoding.UTF8.GetString(WebEncoders.Base64UrlDecode(verifyRequest.ResetCode));
            var isValid = await userManager.VerifyUserTokenAsync(user, userManager.Options.Tokens.PasswordResetTokenProvider, "ResetPassword", code);
            if (!isValid)
            {
                return CreateValidationProblem("InvalidResetCode", "The reset code is invalid or expired.");
            }
        }
        catch (FormatException)
        {
            return CreateValidationProblem("InvalidResetCode", "The reset code format is invalid.");
        }
        return TypedResults.Ok();
    }

    internal async Task<Results<Ok, ProblemHttpResult>> DeactivateUser(
        ClaimsPrincipal claimsPrincipal, [FromServices] IServiceProvider sp)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
        {
            return TypedResults.Problem("User not found.", statusCode: StatusCodes.Status404NotFound);
        }
        if (user is null || !await userManager.IsEmailConfirmedAsync(user))
        {
            return TypedResults.Problem("User not found or email not confirmed.", statusCode: StatusCodes.Status400BadRequest);
        }
        await userManager.SetLockoutEnabledAsync(user, true);
        var result = await userManager.SetLockoutEndDateAsync(user, DateTimeOffset.UtcNow.AddYears(100));
        if (!result.Succeeded)
        {
            return TypedResults.Problem(result.ToString(), statusCode: StatusCodes.Status500InternalServerError);
        }
        return TypedResults.Ok();
    }

    internal async Task<Results<ContentHttpResult, ProblemHttpResult>> RevalidateUserByLink(
    [FromQuery] string userId, [FromQuery] string code, [FromServices] IServiceProvider sp)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        if (await userManager.FindByIdAsync(userId) is not { } user)
        {
            return TypedResults.Problem("User not found.", statusCode: StatusCodes.Status404NotFound);
        }
        try
        {
            code = Encoding.UTF8.GetString(WebEncoders.Base64UrlDecode(code));
        }
        catch (FormatException)
        {
            return TypedResults.Problem("Invalid code format.", statusCode: StatusCodes.Status400BadRequest);
        }

        var isValid = await userManager.VerifyUserTokenAsync(user, userManager.Options.Tokens.EmailConfirmationTokenProvider, "RevalidateUser", code);
        if (!isValid)
        {
            return TypedResults.Problem("Invalid or expired revalidation code.", statusCode: StatusCodes.Status400BadRequest);
        }

        // Perform the revalidation (e.g., unlock user, reset lockout, etc.)
        var result = await userManager.SetLockoutEndDateAsync(user, null);
        if (!result.Succeeded)
        {
            return TypedResults.Problem("Failed to revalidate user.", statusCode: StatusCodes.Status500InternalServerError);
        }

        return TypedResults.Text("Your account has been revalidated.");
    }

    internal async Task<Results<Ok<TwoFactorSetupResponse>, ProblemHttpResult>> GenerateTwoFactorSetupCode(
    ClaimsPrincipal claimsPrincipal, [FromServices] IServiceProvider sp)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();

        // Get the authenticated user
        if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
        {
            return TypedResults.Problem("User not found.", statusCode: StatusCodes.Status404NotFound);
        }

        // Ensure the user has an authenticator key
        var authenticatorKey = await userManager.GetAuthenticatorKeyAsync(user);
        if (string.IsNullOrEmpty(authenticatorKey))
        {
            // Generate a new authenticator key if it doesn't exist
            await userManager.ResetAuthenticatorKeyAsync(user);
            authenticatorKey = await userManager.GetAuthenticatorKeyAsync(user);
        }

        // Generate a QR code URI for authenticator apps (e.g., Google Authenticator)
        var email = await userManager.GetEmailAsync(user) ?? "user";
        var issuer = "RecommendationSystem"; // Change to your app's name

        if (string.IsNullOrEmpty(authenticatorKey))
        {
            return TypedResults.Problem("Authenticator key could not be generated.", statusCode: StatusCodes.Status500InternalServerError);
        }

        var qrCodeUri = GenerateQrCodeUri(issuer, email, authenticatorKey);

        // Return all setup info
        return TypedResults.Ok(new TwoFactorSetupResponse
        {
            SharedKey = authenticatorKey,
            QrCodeUri = qrCodeUri
        });
    }

    // Helper to generate QR code URI for authenticator apps
    private static string GenerateQrCodeUri(string issuer, string email, string secret)
    {
        return $"otpauth://totp/{Uri.EscapeDataString(issuer)}:{Uri.EscapeDataString(email)}?secret={secret}&issuer={Uri.EscapeDataString(issuer)}&digits=6";
    }


    internal async Task<Results<Ok<TwoFactorResponse>, ValidationProblem, NotFound>> TwoFactor(
        ClaimsPrincipal claimsPrincipal, [FromBody] TwoFactorRequest tfaRequest, [FromServices] IServiceProvider sp)
    {
        var signInManager = sp.GetRequiredService<SignInManager<User>>();
        var userManager = signInManager.UserManager;
        if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
        {
            return TypedResults.NotFound();
        }
        if (tfaRequest.Enable == true)
        {
            if (tfaRequest.ResetSharedKey)
            {
                return CreateValidationProblem("CannotResetSharedKeyAndEnable",
                    "Resetting the 2fa shared key must disable 2fa until a 2fa token based on the new shared key is validated.");
            }
            else if (string.IsNullOrEmpty(tfaRequest.TwoFactorCode))
            {
                return CreateValidationProblem("RequiresTwoFactor",
                    "No 2fa token was provided by the request. A valid 2fa token is required to enable 2fa.");
            }
            else if (!await userManager.VerifyTwoFactorTokenAsync(user, userManager.Options.Tokens.AuthenticatorTokenProvider, tfaRequest.TwoFactorCode))
            {
                return CreateValidationProblem("InvalidTwoFactorCode",
                    "The 2fa token provided by the request was invalid. A valid 2fa token is required to enable 2fa.");
            }
            await userManager.SetTwoFactorEnabledAsync(user, true);
        }
        else if (tfaRequest.Enable == false || tfaRequest.ResetSharedKey)
        {
            await userManager.SetTwoFactorEnabledAsync(user, false);
        }
        if (tfaRequest.ResetSharedKey)
        {
            await userManager.ResetAuthenticatorKeyAsync(user);
        }
        string[]? recoveryCodes = null;
        if (tfaRequest.ResetRecoveryCodes || (tfaRequest.Enable == true && await userManager.CountRecoveryCodesAsync(user) == 0))
        {
            var recoveryCodesEnumerable = await userManager.GenerateNewTwoFactorRecoveryCodesAsync(user, 10);
            recoveryCodes = recoveryCodesEnumerable?.ToArray();
        }
        if (tfaRequest.ForgetMachine)
        {
            await signInManager.ForgetTwoFactorClientAsync();
        }
        var key = await userManager.GetAuthenticatorKeyAsync(user);
        if (string.IsNullOrEmpty(key))
        {
            await userManager.ResetAuthenticatorKeyAsync(user);
            key = await userManager.GetAuthenticatorKeyAsync(user);
            if (string.IsNullOrEmpty(key))
            {
                throw new NotSupportedException("The user manager must produce an authenticator key after reset.");
            }
        }
        return TypedResults.Ok(new TwoFactorResponse
        {
            SharedKey = key,
            RecoveryCodes = recoveryCodes,
            RecoveryCodesLeft = recoveryCodes?.Length ?? await userManager.CountRecoveryCodesAsync(user),
            IsTwoFactorEnabled = await userManager.GetTwoFactorEnabledAsync(user),
            IsMachineRemembered = await signInManager.IsTwoFactorClientRememberedAsync(user),
        });
    }

    internal async Task<Results<Ok<InfoResponse>, ValidationProblem, NotFound>> GetUserInfo(
        ClaimsPrincipal claimsPrincipal, [FromServices] IServiceProvider sp, [FromServices] AppDbContext dbContext)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
        {
            return TypedResults.NotFound();
        }
        return TypedResults.Ok(await CreateInfoResponseAsync(user, userManager, dbContext));
    }

    internal async Task<Results<Ok<InfoResponse>, ValidationProblem, NotFound>> UpdateUserInfo(
        ClaimsPrincipal claimsPrincipal,
        [FromBody] InfoRequest infoRequest,
        HttpContext context,
        [FromServices] IServiceProvider sp,
        string? confirmEmailEndpointName,
        LinkGenerator linkGenerator,
        IEmailSender<User> emailSender,
        [FromServices] AppDbContext dbContext)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
        {
            return TypedResults.NotFound();
        }
        if (!string.IsNullOrEmpty(infoRequest.NewEmail) && !_emailAddressAttribute.IsValid(infoRequest.NewEmail))
        {
            return CreateValidationProblem(IdentityResult.Failed(userManager.ErrorDescriber.InvalidEmail(infoRequest.NewEmail)));
        }
        if (!string.IsNullOrEmpty(infoRequest.FirstName))
        {
            user.FirstName = infoRequest.FirstName.Trim();
        }
        if (!string.IsNullOrEmpty(infoRequest.LastName))
        {
            user.LastName = infoRequest.LastName.Trim();
        }
        if (!string.IsNullOrEmpty(infoRequest.NewPassword))
        {
            if (string.IsNullOrEmpty(infoRequest.OldPassword))
            {
                return CreateValidationProblem("OldPasswordRequired",
                    "The old password is required to set a new password. If the old password is forgotten, use /resetPassword.");
            }
            var changePasswordResult = await userManager.ChangePasswordAsync(user, infoRequest.OldPassword, infoRequest.NewPassword);
            if (!changePasswordResult.Succeeded)
            {
                return CreateValidationProblem(changePasswordResult);
            }
        }
        if (!string.IsNullOrEmpty(infoRequest.NewEmail))
        {
            var email = await userManager.GetEmailAsync(user);
            if (email != infoRequest.NewEmail)
            {
                await SendConfirmationEmailAsync(user, userManager, context, infoRequest.NewEmail, confirmEmailEndpointName, linkGenerator, emailSender, isChange: true);
            }
        }
        if (infoRequest.ProfileImageId.HasValue)
        {
            user.ProfileImageId = infoRequest.ProfileImageId.Value;
        }
        // Only update username if it is provided and not empty/null, and is different from current
        if (infoRequest.Username != null)
        {
            var trimmedUsername = infoRequest.Username.Trim();
            if (!string.IsNullOrEmpty(trimmedUsername) && user.UserName != trimmedUsername)
            {
                var setUserNameResult = await userManager.SetUserNameAsync(user, trimmedUsername);
                if (!setUserNameResult.Succeeded)
                {
                    return CreateValidationProblem(setUserNameResult);
                }
            }
        }
        if (!string.IsNullOrEmpty(infoRequest.PhoneNumber) && user.PhoneNumber != infoRequest.PhoneNumber)
        {
            var setPhoneNumberResult = await userManager.SetPhoneNumberAsync(user, infoRequest.PhoneNumber);
            if (!setPhoneNumberResult.Succeeded)
            {
                return CreateValidationProblem(setPhoneNumberResult);
            }
        }
        var updateResult = await userManager.UpdateAsync(user);
        if (!updateResult.Succeeded)
        {
            return CreateValidationProblem(updateResult);
        }
        return TypedResults.Ok(await CreateInfoResponseAsync(user, userManager, dbContext));
    }
    internal async Task<Ok> SendRevalidateEmailEndpoint(
        [FromBody] ResendConfirmationEmailRequest request,
        HttpContext context,
        [FromServices] IServiceProvider sp,
        LinkGenerator linkGenerator,
        IEmailSender<User> emailSender)
    {
        var userManager = sp.GetRequiredService<UserManager<User>>();
        var user = await userManager.FindByEmailAsync(request.Email);
        if (user is null)
        {
            return TypedResults.Ok();
        }
        await SendRevalidateEmailAsync(user, userManager, context, request.Email, linkGenerator, emailSender);
        return TypedResults.Ok();
    }
    internal async Task SendRevalidateEmailAsync(
    User user,
    UserManager<User> userManager,
    HttpContext context,
    string email,
    LinkGenerator linkGenerator,
    IEmailSender<User> emailSender)
    {
        var code = await userManager.GenerateUserTokenAsync(user, userManager.Options.Tokens.EmailConfirmationTokenProvider, "RevalidateUser");
        code = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(code));

        var userId = await userManager.GetUserIdAsync(user);
        var routeValues = new RouteValueDictionary()
        {
            ["userId"] = userId,
            ["code"] = code,
        };

        var revalidateUrl = linkGenerator.GetUriByName(context, "RevalidateUser", routeValues)
            ?? throw new NotSupportedException("Could not find endpoint named 'RevalidateUser'.");

        _ = emailSender.SendConfirmationLinkAsync(user, email, $"Revalidate your account: {HtmlEncoder.Default.Encode(revalidateUrl)}");
    }

    private ValidationProblem CreateValidationProblem(string errorCode, string errorDescription) =>
        TypedResults.ValidationProblem(new Dictionary<string, string[]> {
            { errorCode, [errorDescription] }
        });

    private ValidationProblem CreateValidationProblem(IdentityResult result)
    {
        Debug.Assert(!result.Succeeded);
        var errorDictionary = new Dictionary<string, string[]>(1);

        foreach (var error in result.Errors)
        {
            string[] newDescriptions;

            if (errorDictionary.TryGetValue(error.Code, out var descriptions))
            {
                newDescriptions = new string[descriptions.Length + 1];
                Array.Copy(descriptions, newDescriptions, descriptions.Length);
                newDescriptions[descriptions.Length] = error.Description;
            }
            else
            {
                newDescriptions = [error.Description];
            }

            errorDictionary[error.Code] = newDescriptions;
        }

        return TypedResults.ValidationProblem(errorDictionary);
    }

    private async Task<InfoResponse> CreateInfoResponseAsync(User user, UserManager<User> userManager, AppDbContext dbContext)
    {
        var profileImage = user.ProfileImageId.HasValue ? await dbContext.Images!.FindAsync(user.ProfileImageId.Value) : null;
        var totalBookings = await dbContext.Bookings!.CountAsync(b => b.UserId == user.Id);
        var totalReviews = await dbContext.Reviews!.CountAsync(r => r.UserId == user.Id);
        var totalFavorites = await dbContext.FavouriteFutsalGrounds!.CountAsync(f => f.UserId == user.Id);

        return new()
        {
            Id = user.Id,
            Email = await userManager.GetEmailAsync(user) ?? throw new NotSupportedException("Users must have an email."),
            IsEmailConfirmed = await userManager.IsEmailConfirmedAsync(user),
            ProfileImageUrl = profileImage?.FilePath, // imageurl
            Username = await userManager.GetUserNameAsync(user), // username
            PhoneNumber = await userManager.GetPhoneNumberAsync(user), // phone number
            IsPhoneNumberConfirmed = await userManager.IsPhoneNumberConfirmedAsync(user), // isphoneverified
            FirstName = user.FirstName,
            LastName = user.LastName,
            TotalBookings = totalBookings,
            TotalReviews = totalReviews,
            TotalFavorites = totalFavorites
        };
    }

    private sealed class IdentityEndpointsConventionBuilder(RouteGroupBuilder inner) : IEndpointConventionBuilder
    {
        private IEndpointConventionBuilder InnerAsConventionBuilder => inner;

        public void Add(Action<EndpointBuilder> convention) => InnerAsConventionBuilder.Add(convention);
        public void Finally(Action<EndpointBuilder> finallyConvention) => InnerAsConventionBuilder.Finally(finallyConvention);
    }

    [AttributeUsage(AttributeTargets.Parameter)]
    private sealed class FromBodyAttribute : Attribute, IFromBodyMetadata
    {
    }






}
