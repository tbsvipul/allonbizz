using allonbiz.AdminAPI.Constants;

namespace allonbiz.AdminAPI.Models.Entities;

public class AdminAccount
{
    public Guid AdminId { get; set; } = Guid.NewGuid();
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Role { get; set; } = Roles.Admin; // super_admin | admin
    public List<string> Permissions { get; set; } = new();
    public bool IsActive { get; set; } = true;
    public bool Is2FAEnabled { get; set; } = false;
    public string? TotpSecret { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastLoginAt { get; set; }
    public string? LastLoginIp { get; set; }
    public int FailedLoginAttempts { get; set; }
    public DateTime? LockoutEnd { get; set; }
}
