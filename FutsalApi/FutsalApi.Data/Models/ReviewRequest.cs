using System;

namespace FutsalApi.Data.Models;

public class CreateReviewRequest
{
    public int BookingId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public int? ImageId { get; set; }
}

public class ReviewRequest
{
    public int GroundId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public int? ImageId { get; set; }
}

