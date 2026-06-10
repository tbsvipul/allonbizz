using System.ComponentModel.DataAnnotations.Schema;
using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.Models.Entities;

public class User
{
    public Guid UserId { get; set; } = Guid.NewGuid();
    public string? FirebaseUid { get; set; }
    public string? Email { get; set; }
    public string? PhoneNumber { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? ProfilePhotoData { get; set; }
    public string? FcmToken { get; set; }
    public string Role { get; set; } = "customer"; // customer | keeper
    public bool IsActive { get; set; } = true;
    public UserStatus Status { get; set; } = UserStatus.Active;
    public string? StatusReason { get; set; }
    public DateTime? SuspendedUntil { get; set; }
    public DateTime? StatusChangedAt { get; set; }
    public double? LastLatitude { get; set; }
    public double? LastLongitude { get; set; }
    public double TotalSaved { get; set; }
    public double TotalKm { get; set; }
    public int TotalTrips { get; set; }
    public string? PasswordHash { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastLoginAt { get; set; }
    public string? LastLoginIp { get; set; }
    public int FailedLoginAttempts { get; set; }
    public DateTime? LockoutEnd { get; set; }
    public bool Is2FAEnabled { get; set; }
    public string? TotpSecret { get; set; }

    [NotMapped]
    public string? ProfilePhotoUrl
    {
        get => ProfilePhotoData;
        set => ProfilePhotoData = value;
    }
}
