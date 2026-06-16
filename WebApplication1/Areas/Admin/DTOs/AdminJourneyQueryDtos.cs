using routent.AdminAPI.DTOs.Common;

namespace routent.AdminAPI.DTOs.Admin;

public class AdminJourneyListQueryDto : PaginationParams
{
    public string? Search { get; set; }
    public string? Status { get; set; }
    public string? Type { get; set; }
}
