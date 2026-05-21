using System.ComponentModel.DataAnnotations.Schema;
using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Models.Entities;

public class Keeper
{
    public Guid KeeperId { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string? BusinessLicense { get; set; }
    public string? GstNumber { get; set; }
    public string? PanNumber { get; set; }
    public string? DocumentData { get; set; }
    public string? SocialLinksJson { get; set; }
    public KeeperStatus Status { get; set; } = KeeperStatus.PendingApproval;
    public string? RejectionReason { get; set; }
    public string? HoldReason { get; set; }
    public DateTime? HoldUntil { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ApprovedAt { get; set; }

    public string? IdentityProofType { get; set; }
    public string? IdentityProofNumber { get; set; }
    public byte[]? IdentityProofImage { get; set; }

    public string? BusinessLicenseNumber { get; set; }
    public byte[]? BusinessLicenseImage { get; set; }

    public byte[]? GstCertificateImage { get; set; }

    public byte[]? PanCardImage { get; set; }

    public string? AddressProofType { get; set; }
    public byte[]? AddressProofImage { get; set; }

    public byte[]? ShopFrontImage { get; set; }
    public byte[]? ShopInsideImage { get; set; }

    public string? VerificationNotes { get; set; }
    public bool IsVerified { get; set; } = false;
    public DateTime? DeletedAt { get; set; }

    public User? User { get; set; }
    public ICollection<Shop> Shops { get; set; } = new List<Shop>();
    public ICollection<KeeperDocument> Documents { get; set; } = new List<KeeperDocument>();
    public ICollection<KeeperReviewMessage> ReviewMessages { get; set; } = new List<KeeperReviewMessage>();
    public ICollection<KeeperAuditSchedule> AuditSchedules { get; set; } = new List<KeeperAuditSchedule>();

    [NotMapped]
    public string? DocumentUrl
    {
        get => DocumentData;
        set => DocumentData = value;
    }
}

