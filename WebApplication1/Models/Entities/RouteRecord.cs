using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Models.Entities;

public class RouteRecord
{
    public Guid RouteId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public double StartLatitude { get; set; }
    public double StartLongitude { get; set; }
    public string? StartAddress { get; set; }
    public double EndLatitude { get; set; }
    public double EndLongitude { get; set; }
    public string? EndAddress { get; set; }
    public double? DistanceKm { get; set; }
    public int? EstimatedMinutes { get; set; }
    public RouteStatus Status { get; set; } = RouteStatus.Planning;
    public int OffersFoundOnRoute { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }

    public User? User { get; set; }
}
