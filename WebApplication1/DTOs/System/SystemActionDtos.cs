using System.ComponentModel.DataAnnotations;

namespace allonbiz.AdminAPI.DTOs.System;

public class ResolveErrorDto
{
    public string? ResolutionNotes { get; set; }
}

public class ToggleMaintenanceModeDto
{
    [Required]
    public bool IsEnabled { get; set; }
    public string? Reason { get; set; }
}
