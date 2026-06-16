namespace routent.AdminAPI.Models.Entities;

public class Journey
{
    public Guid JourneyId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Status { get; set; } = "active";
    public string Type { get; set; } = "freeRoam";
    public DateTime StartTime { get; set; } = DateTime.UtcNow;
    public DateTime? EndTime { get; set; }
    
    public string? StartName { get; set; }
    public double StartLat { get; set; }
    public double StartLng { get; set; }
    
    public string? EndName { get; set; }
    public double? EndLat { get; set; }
    public double? EndLng { get; set; }
    
    public double Distance { get; set; }
    public long Duration { get; set; }
    
    public string? TagsJson { get; set; } // Stores array of strings
    public string? ShopsJson { get; set; } // Stores array of shop details
    
    public int OffersRedeemed { get; set; }
    public decimal TotalSavings { get; set; }
    public int LikesCount { get; set; }
    public int ViewsCount { get; set; }
    public string? PathJson { get; set; }

    public User? User { get; set; }
}
