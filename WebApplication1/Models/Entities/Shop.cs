namespace allonbiz.AdminAPI.Models.Entities;

public class Shop
{
    public Guid ShopId { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Address { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public Guid KeeperId { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? GooglePlaceId { get; set; }
    public Guid? CategoryId { get; set; }
    public byte[]? ImageData { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsOpen { get; set; }
    public string? BusinessHoursJson { get; set; }
    public List<string>? Amenities { get; set; }
    public double? NotificationRadius { get; set; }
    public string? AdminNotes { get; set; }
    
    /// <summary>
    /// Comma-separated tags for the shop.
    /// Handled by ValueConverter in DbContext.
    /// </summary>
    public List<string> Tags { get; set; } = new();

    public bool IsVerified { get; set; }
    public bool IsActive { get; set; } = true;
    public string? RejectionReason { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Keeper? Keeper { get; set; }
    public Category? Category { get; set; }
    public ICollection<Offer> Offers { get; set; } = new List<Offer>();
    public ICollection<Review> Reviews { get; set; } = new List<Review>();
}
