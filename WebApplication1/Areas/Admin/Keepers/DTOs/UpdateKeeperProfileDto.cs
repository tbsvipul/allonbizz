using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Keepers;

public class UpdateKeeperProfileDto
{
    [Required]
    [StringLength(200)]
    public string BusinessName { get; set; } = string.Empty;

    [StringLength(200)]
    public string? BusinessLicense { get; set; }

    [StringLength(50)]
    public string? GstNumber { get; set; }

    [StringLength(50)]
    public string? PanNumber { get; set; }

    [Phone]
    public string? ContactPhone { get; set; }

    public string? SocialLinksJson { get; set; }
}
