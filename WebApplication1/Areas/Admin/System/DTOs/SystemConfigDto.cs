namespace allonbiz.AdminAPI.DTOs.System;

public class SystemConfigDto
{
    public string BaseUrl { get; set; } = string.Empty;
    public string FirebaseProjectId { get; set; } = string.Empty;
    public string ApiVersion { get; set; } = "v1";
    public string Environment { get; set; } = "Production";
    public Dictionary<string, string> ExternalServices { get; set; } = new();
}
