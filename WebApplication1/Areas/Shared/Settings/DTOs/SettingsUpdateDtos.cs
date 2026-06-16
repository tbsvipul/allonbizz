using System.ComponentModel.DataAnnotations;
using routent.AdminAPI.DTOs.System;

namespace routent.AdminAPI.DTOs.Settings;

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
