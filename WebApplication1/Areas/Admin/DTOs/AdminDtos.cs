using System.ComponentModel.DataAnnotations;

using allonbiz.AdminAPI.Models.Enums;

namespace allonbiz.AdminAPI.DTOs.Admin;

public class CreateAdminRequestDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string LastName { get; set; } = string.Empty;

    [Required]
    public string Role { get; set; } = AdminRoles.Admin;
    public bool IsActive { get; set; } = true;
    public List<string>? Permissions { get; set; }
    public string? Password { get; set; }
}

public class UpdateAdminRequestDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string LastName { get; set; } = string.Empty;

    [Required]
    public string Role { get; set; } = AdminRoles.Admin;
    public bool IsActive { get; set; } = true;
    public List<string>? Permissions { get; set; }
    public string? Password { get; set; }
}

public class UpdateAdminProfileDto
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? Email { get; set; }
}

public class AdminListQueryDto : allonbiz.AdminAPI.DTOs.Common.PaginationParams
{
    public string? Search { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
}

public class AdminListItemDto
{
    public Guid AdminId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string FullName => $"{FirstName} {LastName}".Trim();
    public string Role { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public bool Is2FAEnabled { get; set; }
    public DateTime? LastLoginAt { get; set; }
}

public class AdminDetailDto : AdminListItemDto
{
    public List<string> Permissions { get; set; } = new();
    public int FailedLoginAttempts { get; set; }
    public DateTime? LockoutEnd { get; set; }
}
