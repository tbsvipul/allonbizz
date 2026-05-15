namespace allonbiz.AdminAPI.Models.Entities;

public class Favourite
{
    public Guid FavouriteId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid? ShopId { get; set; }
    public Guid? OfferId { get; set; }
    public string Type { get; set; } = "shop"; // shop | offer
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Shop? Shop { get; set; }
    public Offer? Offer { get; set; }
}
