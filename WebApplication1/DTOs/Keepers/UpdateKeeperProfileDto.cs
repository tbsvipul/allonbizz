using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Keepers;

public class UpdateKeeperProfileDto
{
    public string? BusinessName { get; set; }
    public string? BusinessLicense { get; set; }
    public string? TaxId { get; set; }
    public string? Website { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public string? Address { get; set; }
}
