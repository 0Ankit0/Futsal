using System;
using System.Security.Claims;

using FutsalApi.ApiService.Data;
using FutsalApi.ApiService.Models;
using FutsalApi.ApiService.Repositories;

using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace FutsalApi.ApiService.Routes;

public static class NotificationsApiEndpointRouteBuilderExtensions
{
    public static IEndpointConventionBuilder MapNotificationApi(this IEndpointRouteBuilder endpoints)
    {
        var routeGroup = endpoints.MapGroup("/Notifications").RequireAuthorization();

        // GET: /Notifications (with pagination)
        routeGroup.MapGet("/", async Task<Results<Ok<IEnumerable<Notification>>, ProblemHttpResult, NotFound>>
            ([FromServices] INotificationRepository repository,
             [FromServices] UserManager<User> userManager,
             ClaimsPrincipal claimsPrincipal,
             [FromQuery] int page = 1,
             [FromQuery] int pageSize = 10) =>
        {
            if (page <= 0 || pageSize <= 0)
            {
                return TypedResults.Problem(detail: "Page and pageSize must be greater than 0.", statusCode: StatusCodes.Status400BadRequest);
            }

            try
            {
                if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
                {
                    return TypedResults.NotFound();
                }
                var notifications = await repository.GetNotificationsByUserIdAsync(user.Id);
                return TypedResults.Ok(notifications);
            }
            catch (Exception ex)
            {
                return TypedResults.Problem($"An error occurred while retrieving notifications: {ex.Message}");
            }
        })
        .WithName("GetNotificationsByUserId")
        .WithSummary("Get Notifications of a user")
        .WithDescription("Get all the Notifications for a partucular user using userid")
        .Accepts<ClaimsPrincipal>("User")
        .Accepts<int>("page")
        .Accepts<int>("pageSize")
        .Produces<IEnumerable<Notification>>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        //Post: /Notifications/Send
        routeGroup.MapPost("/Send", async Task<Results<Ok<string>, ProblemHttpResult>>
            ([FromServices] INotificationRepository repository,
             [FromBody] NotificationListModel notificationList) =>
        {
            try
            {
                var result = await repository.SendNotificationToMultipleUsersAsync(notificationList);
                if (result)
                {
                    return TypedResults.Ok("Notifications sent successfully.");
                }
                else
                {
                    return TypedResults.Problem("Failed to send notifications.", statusCode: StatusCodes.Status400BadRequest);
                }
            }
            catch (Exception ex)
            {
                return TypedResults.Problem($"An error occurred while sending notifications: {ex.Message}");
            }
        })
        .WithName("SendNotificationToMultipleUsers")
        .WithSummary("Send Notification to multiple users")
        .WithDescription("Send Notification to multiple users")
        .Accepts<NotificationListModel>("notificationList")
        .Produces<string>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        // PUT: /Notifications/{notificationId}
        routeGroup.MapPut("/{notificationId:int}", async Task<Results<Ok<string>, ProblemHttpResult, NotFound>>
            ([FromServices] INotificationRepository repository,
            [FromServices] UserManager<User> userManager,
            ClaimsPrincipal claimsPrincipal,
             int notificationId) =>
        {
            try
            {
                if (await userManager.GetUserAsync(claimsPrincipal) is not { } user)
                {
                    return TypedResults.NotFound();
                }
                var result = await repository.UpdateStatusByUserIdAsync(notificationId, user.Id);
                if (result == false)
                {
                    return TypedResults.Problem("Failed to update the notification status.", statusCode: StatusCodes.Status400BadRequest);
                }
                else
                {
                    return TypedResults.Ok("Notification status updated successfully.");
                }
            }
            catch (Exception ex)
            {
                return TypedResults.Problem($"An error occurred while updating the notification status: {ex.Message}");
            }
        })
        .WithName("UpdateNotificationStatusByUserId")
        .WithSummary("Update Notification status by UserId")
        .WithDescription("Update Notification status by UserId")
        .Accepts<int>("notificationId")
        .Accepts<ClaimsPrincipal>("User")
        .Produces<string>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return routeGroup;
    }

}
