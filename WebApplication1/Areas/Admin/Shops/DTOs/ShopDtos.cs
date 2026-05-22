using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Shops;

public class ShopSummaryDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string BusinessName { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsVerified { get; set; }
    public string VerifyStatus { get; set; } = "Pending";
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? ImageUrl { get; set; }
    public string? RejectionReason { get; set; }
    public string? DeactivateReason { get; set; }
}

public class ShopDetailDto
{
    public Guid ShopId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Address { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? CategoryName { get; set; }
    public Guid? CategoryId { get; set; }
    public string? KeeperBusinessName { get; set; }
    public string? KeeperName { get; set; }
    public Guid KeeperId { get; set; }
    public bool IsActive { get; set; }
    public bool IsVerified { get; set; }
    public string VerifyStatus { get; set; } = "Pending";
    public bool IsOpen { get; set; }
    public double? NotificationRadius { get; set; }
    public string? ImageUrl { get; set; }
    public List<string> ShopImages { get; set; } = new();
    public List<string> Tags { get; set; } = new();
    public List<string> Amenities { get; set; } = new();
    public string? RejectionReason { get; set; }
    public string? DeactivateReason { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<ShopOfferSummaryDto> RecentOffers { get; set; } = new();
}

public class ShopOfferSummaryDto
{
    public Guid OfferId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime EndDate { get; set; }
}

public class CreateShopRequestDto
{
    [Required]
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Address { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public Guid KeeperId { get; set; }
    public Guid? CategoryId { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? ImageUrl { get; set; }
    public List<string> ShopImages { get; set; } = new();
    public bool IsOpen { get; set; } = true;
    public double? NotificationRadius { get; set; }
    public List<string> Amenities { get; set; } = new();
    public List<string> Tags { get; set; } = new();
}

public class UpdateShopRequestDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Address { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public string? ImageUrl { get; set; }
    public List<string> ShopImages { get; set; } = new();
    public Guid? CategoryId { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsOpen { get; set; } = true;
    public double? NotificationRadius { get; set; }
    public List<string> Amenities { get; set; } = new();
    public List<string> Tags { get; set; } = new();
}

public class UpdateShopStatusDto
{
    [Required]
    public bool? IsActive { get; set; }
    public string? Reason { get; set; }
}

public class RejectShopRequestDto
{
    [Required]
    [StringLength(500)]
    public string Reason { get; set; } = string.Empty;
}

public class VerifyShopRequestDto
{
    [StringLength(500)]
    public string? Reason { get; set; }
}

public class AssignTagsDto
{
    [Required]
    public List<string> Tags { get; set; } = new();
}

public class ShopListQueryDto
{
    public string? Search { get; set; }
    public Guid? CategoryId { get; set; }
    public bool? IsVerified { get; set; }
    public string? VerifyStatus { get; set; }
    public bool? IsActive { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}
