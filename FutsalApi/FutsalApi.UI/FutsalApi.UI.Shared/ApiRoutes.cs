namespace FutsalApi.UI.Shared;

public static class ApiRoutes
{
    public static class User
    {
        public const string Base = "User";
        public const string Register = $"{Base}/register";
        public const string Login = $"{Base}/login";
        public const string ForgotPassword = $"{Base}/forgotPassword";
        public const string ResendConfirmationEmail = $"{Base}/resendConfirmationEmail";
        public const string VerifyResetCode = $"{Base}/verifyResetCode";
        public const string ResetPassword = $"{Base}/resetPassword";

        public const string ManageBase = $"{Base}/manage";
        public const string ManageInfo = $"{ManageBase}/info";
        public const string Deactivate = $"{ManageBase}/deactivate";
    }

    public static class Booking
    {
        public const string Base = "Booking";
        public static string Cancel(int bookingId) => $"{Base}/cancel/{bookingId}";
    }

    public static class FutsalGround
    {
        public const string Base = "FutsalGround";
        public const string Search = $"{Base}/search";
        public static string ById(int id) => $"{Base}/{id}";
    }

    public static class Payment
    {
        public const string Base = "Payment";
    }

    public static class PaymentGateway
    {
        public const string Base = "PaymentGateway";
        public const string KhaltiInitiate = $"{Base}/khalti/initiate";
    }

    public static class Notifications
    {
        public const string Base = "Notifications";
        public const string Send = $"{Base}/Send";
        public static string ById(int notificationId) => $"{Base}/{notificationId}";
    }

    public static class Reviews
    {
        public const string Base = "Reviews";
        public static string Ground(int groundId) => $"{Base}/Ground/{groundId}";
    }

    public static class Roles
    {
        public const string Base = "Roles";
        public static string ById(string roleId) => $"{Base}/{roleId}";
        public static string Claims(string roleId) => $"{Base}/{roleId}/Claims";
    }

    public static class UserRoles
    {
        public const string Base = "UserRoles";
    }
}
