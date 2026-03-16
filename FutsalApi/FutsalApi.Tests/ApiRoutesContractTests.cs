using FutsalApi.UI.Shared;

using FluentAssertions;

namespace FutsalApi.Tests;

public class ApiRoutesContractTests
{
    private static readonly HashSet<string> ValidPrefixes =
    [
        "User",
        "Booking",
        "FutsalGround",
        "Payment",
        "PaymentGateway",
        "Notifications",
        "Reviews",
        "Roles",
        "UserRoles",
        "images"
    ];

    [Theory]
    [InlineData(ApiRoutes.User.Register)]
    [InlineData(ApiRoutes.User.Login)]
    [InlineData(ApiRoutes.User.ForgotPassword)]
    [InlineData(ApiRoutes.User.ResendConfirmationEmail)]
    [InlineData(ApiRoutes.User.VerifyResetCode)]
    [InlineData(ApiRoutes.User.ResetPassword)]
    [InlineData(ApiRoutes.User.ManageInfo)]
    [InlineData(ApiRoutes.User.Deactivate)]
    [InlineData(ApiRoutes.Booking.Base)]
    [InlineData(ApiRoutes.FutsalGround.Base)]
    [InlineData(ApiRoutes.FutsalGround.Search)]
    [InlineData(ApiRoutes.Payment.Base)]
    [InlineData(ApiRoutes.PaymentGateway.KhaltiInitiate)]
    [InlineData(ApiRoutes.Notifications.Base)]
    [InlineData(ApiRoutes.Notifications.Send)]
    [InlineData(ApiRoutes.Reviews.Base)]
    [InlineData(ApiRoutes.Roles.Base)]
    [InlineData(ApiRoutes.UserRoles.Base)]
    public void ApiRoutes_ShouldUseValidApiRoutePrefix(string route)
    {
        route.Should().NotStartWith("/");

        var prefix = route.Split('/')[0];
        ValidPrefixes.Should().Contain(prefix);
    }
}
