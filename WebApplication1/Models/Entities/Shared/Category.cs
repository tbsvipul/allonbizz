using System.ComponentModel.DataAnnotations.Schema;

namespace routent.AdminAPI.Models.Entities;

public class Category
{
    public Guid CategoryId { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string? IconData { get; set; }
    public string? Color { get; set; }
    public string? Description { get; set; }
    public Guid? ParentCategoryId { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Category? ParentCategory { get; set; }
    public ICollection<Category> SubCategories { get; set; } = new List<Category>();

    [NotMapped]
    public string? Icon
    {
        get => IconData;
        set => IconData = value;
    }
}
