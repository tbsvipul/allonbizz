using System.ComponentModel.DataAnnotations;
using allonbiz.AdminAPI.DTOs.System;

namespace allonbiz.AdminAPI.DTOs.Settings;

public class UpdateSettingsDto
{
    [Required]
    public SystemConfigDto Config { get; set; } = new();
}

public class UpdateSecurityDto
{
    public bool Enforce2FA { get; set; }
    public int PasswordExpirationDays { get; set; }
}

public class SecuritySettingsDto
{
    public bool Enforce2FA { get; set; }
    public int PasswordExpirationDays { get; set; }
}
