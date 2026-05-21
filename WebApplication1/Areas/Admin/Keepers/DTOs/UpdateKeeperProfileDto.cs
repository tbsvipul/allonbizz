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

    [StringLength(100)]
    public string? IdentityProofType { get; set; }

    [StringLength(100)]
    public string? IdentityProofNumber { get; set; }

    public byte[]? IdentityProofImage { get; set; }

    [StringLength(100)]
    public string? BusinessLicenseNumber { get; set; }

    public byte[]? BusinessLicenseImage { get; set; }

    public byte[]? GstCertificateImage { get; set; }

    public byte[]? PanCardImage { get; set; }

    [StringLength(100)]
    public string? AddressProofType { get; set; }

    public byte[]? AddressProofImage { get; set; }

    public byte[]? ShopFrontImage { get; set; }

    public byte[]? ShopInsideImage { get; set; }
}
