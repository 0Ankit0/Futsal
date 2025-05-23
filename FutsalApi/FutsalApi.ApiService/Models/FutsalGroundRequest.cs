using System;

namespace FutsalApi.ApiService.Models;

public class FutsalGroundRequest
{
    public string Name { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string Description { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public decimal PricePerHour { get; set; }
    public TimeSpan OpenTime { get; set; }
    public TimeSpan CloseTime { get; set; }


}
