using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Analytics;

public class GenerateCustomReportDto
{
    [Required]
    public string Dataset { get; set; } = string.Empty;
    public List<string> Metrics { get; set; } = new();
    public string? GroupBy { get; set; }
    public DateTime? DateFrom { get; set; }
    public DateTime? DateTo { get; set; }
    public Dictionary<string, string>? Filters { get; set; }
    public string Format { get; set; } = "json";
}
