using FutsalApi.ApiService.Data;
using FutsalApi.ApiService.Models;

namespace FutsalApi.ApiService.Repositories;

/// <summary>
/// Interface for NotificationRepository, providing additional methods specific to Notification.
/// </summary>
public interface INotificationRepository : IGenericrepository<Notification>
{
    Task<IEnumerable<Notification>> GetNotificationsByUserIdAsync(string userId, int page = 1, int pageSize = 10);
    Task<bool> UpdateStatusByUserIdAsync(int notificationId, string userId);

    Task<bool> SendNotificationToMultipleUsersAsync(NotificationListModel notificationListModel);
}