using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.Categories;

public class CreateCategoryRequestDto
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public string Icon { get; set; } = string.Empty;

    [Required]
    [StringLength(32)]
    public string Color { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Description { get; set; }
    public Guid? ParentCategoryId { get; set; }
    [Range(0, int.MaxValue)]
    public int DisplayOrder { get; set; } = 0;
    public bool IsActive { get; set; } = true;
}

public class UpdateCategoryRequestDto
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public string Icon { get; set; } = string.Empty;

    [Required]
    [StringLength(32)]
    public string Color { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Description { get; set; }
    public Guid? ParentCategoryId { get; set; }
    [Range(0, int.MaxValue)]
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
}

public class CategoryTreeDto
{
    public Guid CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? ParentCategoryId { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public int BusinessCount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public List<CategoryTreeDto> Children { get; set; } = new();
}

public class ReorderCategoriesRequestDto
{
    [Required]
    public List<CategoryOrderDto> Orders { get; set; } = new();
}

public class CategoryOrderDto
{
    public Guid CategoryId { get; set; }
    public int DisplayOrder { get; set; }
}

public class CategoryAnalyticsDto
{
    public Guid CategoryId { get; set; }
    public int TotalViews { get; set; }
}
