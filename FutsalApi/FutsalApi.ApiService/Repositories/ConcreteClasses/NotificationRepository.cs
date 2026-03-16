
using System.Data;
using Dapper;
using FutsalApi.Data.DTO;
using FutsalApi.Data.Models;
using Microsoft.EntityFrameworkCore;

namespace FutsalApi.ApiService.Repositories;

/// <summary>
/// Repository for managing Notification entities.
/// Inherits from GenericRepository and provides additional methods specific to Notification.
/// </summary>
public class NotificationRepository : GenericRepository<Notification>, INotificationRepository
{
    private readonly AppDbContext _dbContext;
    private readonly IDbConnection _dbConnection;

    public NotificationRepository(AppDbContext dbContext, IDbConnection dbConnection) : base(dbContext)
    {
        _dbContext = dbContext;
        _dbConnection = dbConnection;
    }

    /// <summary>
    /// Retrieves Notifications for a specific User with pagination.
    /// </summary>
    public async Task<IEnumerable<NotificationResponse>> GetNotificationsByUserIdAsync(string userId, int page = 1, int pageSize = 10)
    {
        if (page <= 0 || pageSize <= 0)
        {
            throw new ArgumentOutOfRangeException("Page and pageSize must be greater than 0.");
        }

        return await _dbContext.Notifications
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new NotificationResponse
            {
                Id = r.Id,
                UserId = r.UserId,
                Message = r.Message,
                IsRead = r.IsRead,
                CreatedAt = r.CreatedAt
            })
            .ToListAsync();
    }

    /// <summary>
    /// Sends a Notification to multiple users.
    /// /// </summary>
    public async Task SendNotificationToMultipleUsersAsync(NotificationListModel notificationListModel)
    {
        if (notificationListModel == null)
        {
            throw new ArgumentNullException(nameof(notificationListModel), "NotificationListModel cannot be null.");
        }

        if (notificationListModel.UserId.Count == 0 || string.IsNullOrEmpty(notificationListModel.Message))
        {
            throw new ArgumentException("UserId list and message cannot be empty.");
        }

        var parameters = new
        {
            p_user_ids = notificationListModel.UserId.ToArray(),
            p_message = notificationListModel.Message
        };

        await _dbConnection.ExecuteAsync("send_notifications_to_multiple_users", parameters, commandType: CommandType.StoredProcedure);
    }

    /// <summary>
    /// Deletes a Notification only if it belongs to the specified user.
    /// </summary>
    public async Task<bool> UpdateStatusByUserIdAsync(int NotificationId, string userId)
    {
        var Notification = await _dbContext.Notifications.FirstOrDefaultAsync(r => r.Id == NotificationId && r.UserId == userId);
        if (Notification == null)
        {
            return false;
        }
        Notification.IsRead = true;

        _dbContext.Notifications.Update(Notification);
        await _dbContext.SaveChangesAsync();
        return true;
    }

    public async Task UpsertDeviceTokenAsync(string userId, string token, string platform)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User id is required.", nameof(userId));
        }

        if (string.IsNullOrWhiteSpace(token) || string.IsNullOrWhiteSpace(platform))
        {
            throw new ArgumentException("Token and platform are required.");
        }

        var normalizedPlatform = platform.Trim().ToLowerInvariant();
        var existingToken = await _dbContext.DeviceTokens!
            .FirstOrDefaultAsync(dt => dt.UserId == userId && dt.Platform == normalizedPlatform);

        if (existingToken is null)
        {
            await _dbContext.DeviceTokens!.AddAsync(new DeviceToken
            {
                UserId = userId,
                Token = token.Trim(),
                Platform = normalizedPlatform,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
        }
        else
        {
            existingToken.Token = token.Trim();
            existingToken.UpdatedAt = DateTime.UtcNow;
            _dbContext.DeviceTokens!.Update(existingToken);
        }

        await _dbContext.SaveChangesAsync();
    }

    public async Task<bool> RemoveDeviceTokenAsync(string userId, string token, string platform)
    {
        if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(platform))
        {
            return false;
        }

        var normalizedPlatform = platform.Trim().ToLowerInvariant();
        var tokenToRemove = await _dbContext.DeviceTokens!
            .FirstOrDefaultAsync(dt => dt.UserId == userId
                && dt.Platform == normalizedPlatform
                && (string.IsNullOrWhiteSpace(token) || dt.Token == token));

        if (tokenToRemove is null)
        {
            return false;
        }

        _dbContext.DeviceTokens!.Remove(tokenToRemove);
        await _dbContext.SaveChangesAsync();
        return true;
    }

}
