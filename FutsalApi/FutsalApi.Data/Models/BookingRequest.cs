using System;

namespace FutsalApi.Data.Models;

public class BookingRequest
{
    public int GroundId { get; set; }
    public DateTime BookingDate { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }

}
