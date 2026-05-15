using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Tags;

public class CreateTagRequestDto
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [StringLength(100)]
    public string? Type { get; set; }

    [StringLength(32)]
    public string? Color { get; set; }

    public string? IconData { get; set; }
}

public class UpdateTagRequestDto
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [StringLength(100)]
    public string? Type { get; set; }

    [StringLength(32)]
    public string? Color { get; set; }
    public string? IconData { get; set; }
    public bool IsActive { get; set; }
}

public class TagDetailDto
{
    public Guid TagId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Type { get; set; }
    public string? Color { get; set; }
    public string? IconData { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
