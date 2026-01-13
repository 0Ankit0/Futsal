using System;

using FutsalApi.Data.DTO;

namespace FutsalApi.Data.Models;

public class BookingResponse
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public int GroundId { get; set; }
    public DateTime BookingDate { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public BookingStatus Status { get; set; }
    public decimal TotalAmount { get; set; }
    public DateTime CreatedAt { get; set; }
    public string GroundName { get; set; } = string.Empty;
    public bool HasReview { get; set; }
}
