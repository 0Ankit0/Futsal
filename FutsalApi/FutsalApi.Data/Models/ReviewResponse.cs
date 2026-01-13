using System;

namespace FutsalApi.Data.Models;

public class ReviewResponse
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public int? UserImageId { get; set; }
    public int? ReviewImageId { get; set; }
    public string? ReviewImageUrl { get; set; }
    public int GroundId { get; set; }
    public string GroundName { get; set; } = string.Empty;
    public string GroundImageUrl { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}
