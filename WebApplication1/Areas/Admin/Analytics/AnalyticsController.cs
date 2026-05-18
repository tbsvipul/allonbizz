using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.DTOs.Analytics;
using allonbiz.AdminAPI.DTOs.Admin;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/admin/analytics")]
[Authorize]
public class AnalyticsController : ControllerBase
{
    private readonly IAnalyticsService _analyticsService;
    public AnalyticsController(IAnalyticsService analyticsService) => _analyticsService = analyticsService;

    [HttpGet("users")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetUsers([FromQuery] AnalyticsRangeQueryDto query)
        => Ok(ApiResponse<UserAnalyticsDto>.Ok(await _analyticsService.GetUserAnalyticsAsync(query, HttpContext.RequestAborted)));

    [HttpGet("journeys")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetJourneys([FromQuery] AnalyticsRangeQueryDto query)
        => Ok(ApiResponse<JourneyAnalyticsResponseDto>.Ok(await _analyticsService.GetJourneyAnalyticsAsync(query, HttpContext.RequestAborted)));

    [HttpGet("revenue")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetRevenue([FromQuery] AnalyticsRangeQueryDto query)
        => Ok(ApiResponse<RevenueAnalyticsDto>.Ok(await _analyticsService.GetRevenueAnalyticsAsync(query, HttpContext.RequestAborted)));

    [HttpGet("realtime")]
    [RequirePermission(Permissions.AnalyticsView)]
    public async Task<IActionResult> GetRealtime()
        => Ok(ApiResponse<RealTimeMetricsDto>.Ok(await _analyticsService.GetRealTimeMetricsAsync(HttpContext.RequestAborted)));

    [HttpGet("reports/{reportType}")]
    [RequirePermission(Permissions.ReportsGenerate)]
    public async Task<IActionResult> GetReport(string reportType, [FromQuery] AnalyticsRangeQueryDto query, [FromQuery] string format = "json")
    {
        if (format.Equals("csv", StringComparison.OrdinalIgnoreCase))
        {
            var csv = await _analyticsService.GetPrebuiltReportCsvAsync(reportType, query, HttpContext.RequestAborted);
            return File(csv, "text/csv", $"{reportType.Trim().ToLowerInvariant()}.csv");
        }

        var normalizedReportType = reportType.Trim().ToLowerInvariant();
        return normalizedReportType switch
        {
            "users" => Ok(ApiResponse<UserAnalyticsDto>.Ok(await _analyticsService.GetUserAnalyticsAsync(query, HttpContext.RequestAborted))),
            "journeys" => Ok(ApiResponse<JourneyAnalyticsResponseDto>.Ok(await _analyticsService.GetJourneyAnalyticsAsync(query, HttpContext.RequestAborted))),
            "revenue" => Ok(ApiResponse<RevenueAnalyticsDto>.Ok(await _analyticsService.GetRevenueAnalyticsAsync(query, HttpContext.RequestAborted))),
            "dashboard" => Ok(ApiResponse<AdminDashboardSummaryDto>.Ok(await _analyticsService.GetFullDashboardAsync(HttpContext.RequestAborted))),
            _ => throw new NotSupportedException($"Prebuilt report '{reportType}' is not available.")
        };
    }

    [HttpPost("reports/custom")]
    [RequirePermission(Permissions.ReportsGenerate)]
    public async Task<IActionResult> CustomReport([FromBody] GenerateCustomReportDto dto)
    {
        if (dto.Format.Equals("csv", StringComparison.OrdinalIgnoreCase))
        {
            var csv = await _analyticsService.GenerateCustomReportCsvAsync(dto, HttpContext.RequestAborted);
            return File(csv, "text/csv", "custom-report.csv");
        }

        return Ok(ApiResponse<CustomAnalyticsReportDto>.Ok(await _analyticsService.GenerateCustomReportAsync(dto, HttpContext.RequestAborted)));
    }
}
