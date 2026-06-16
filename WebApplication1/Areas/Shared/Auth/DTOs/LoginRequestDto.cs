using System.ComponentModel.DataAnnotations;

namespace routent.AdminAPI.DTOs.Auth;

public class LoginRequestDto
{
    [Required]
    [EmailAddress]
    [StringLength(320)]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string Password { get; set; } = string.Empty;

    [StringLength(12)]
    public string? Totp { get; set; }  // Required only if 2FA enabled
}

public class LoginResponseDto
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public int ExpiresIn { get; set; }      // seconds
    public AdminProfileDto Admin { get; set; } = null!;
    public string? FirebaseToken { get; set; }
}

public class AdminProfileDto
{
    public Guid AdminId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public List<string> Permissions { get; set; } = new();
    public bool Is2FAEnabled { get; set; }
    public DateTime? LastLoginAt { get; set; }
}
