using System.ComponentModel.DataAnnotations;

namespace routent.AdminAPI.Models.Entities;

public class MediaAsset
{
    [Key]
    public Guid AssetId { get; set; } = Guid.NewGuid();
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public byte[]? Data { get; set; }
    public Guid? RelatedId { get; set; }
    public string AssetType { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
