using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Filters;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Helpers;

namespace allonbiz.AdminAPI.Controllers;

[ApiController]
[Route("api/v1/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService) => _userService = userService;

    [HttpGet]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> GetUsers([FromQuery] UserListQueryDto query)
    {
        var result = await _userService.GetUsersAsync(query, HttpContext.RequestAborted);
        return Ok(ApiResponse<PagedResponse<UserDetailDto>>.Ok(result));
    }

    [HttpGet("{userId:guid}")]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> GetUser(Guid userId)
    {
        var result = await _userService.GetUserDetailAsync(userId, HttpContext.RequestAborted);
        return Ok(ApiResponse<UserDetailDto>.Ok(result));
    }

    [HttpGet("{userId:guid}/profile")]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> GetUserProfile(Guid userId)
    {
        var result = await _userService.GetUserProfileAsync(userId, HttpContext.RequestAborted);
        return Ok(ApiResponse<AdminUserProfileDto>.Ok(result));
    }

    [HttpGet("{userId:guid}/activity")]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> GetUserActivity(Guid userId)
    {
        var result = await _userService.GetUserActivityAsync(userId, HttpContext.RequestAborted);
        return Ok(ApiResponse<UserActivityDto>.Ok(result));
    }

    [HttpGet("{userId:guid}/login-history")]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> GetLoginHistory(Guid userId, [FromQuery] PaginationParams paging)
    {
        var result = await _userService.GetLoginHistoryAsync(userId, paging, HttpContext.RequestAborted);
        return Ok(ApiResponse<PagedResponse<LoginHistoryItemDto>>.Ok(result));
    }

    [HttpPut("{userId:guid}/status")]
    [RequirePermission(Permissions.UsersEdit)]
    public async Task<IActionResult> UpdateStatus(Guid userId, [FromBody] UpdateStatusRequestDto dto)
    {
        await _userService.UpdateStatusAsync(userId, dto, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{userId:guid}/force-password-reset")]
    [RequirePermission(Permissions.UsersEdit)]
    public async Task<IActionResult> ForcePasswordReset(Guid userId)
    {
        await _userService.ForcePasswordResetAsync(userId, HttpContext.RequestAborted);
        return Ok(ApiResponse<object?>.Ok(null, "Password reset email sent"));
    }

    [HttpPost("{userId:guid}/reset-2fa")]
    [RequirePermission(Permissions.UsersEdit)]
    public async Task<IActionResult> Reset2FA(Guid userId)
    {
        await _userService.Reset2FAAsync(userId, User.GetUserId(), HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpDelete("{userId:guid}/sessions")]
    [RequirePermission(Permissions.UsersEdit)]
    public async Task<IActionResult> TerminateSessions(Guid userId)
    {
        await _userService.TerminateSessionsAsync(userId, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{userId:guid}/suspend")]
    [RequirePermission(Permissions.UsersSuspend)]
    public async Task<IActionResult> Suspend(Guid userId, [FromBody] SuspendUserRequestDto dto)
    {
        await _userService.SuspendUserAsync(userId, dto, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{userId:guid}/ban")]
    [RequirePermission(Permissions.UsersBan)]
    public async Task<IActionResult> Ban(Guid userId, [FromBody] BanUserRequestDto dto)
    {
        await _userService.BanUserAsync(userId, dto, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{userId:guid}/warn")]
    [RequirePermission(Permissions.UsersEdit)]
    public async Task<IActionResult> Warn(Guid userId, [FromBody] WarnUserRequestDto dto)
    {
        await _userService.SendWarningAsync(userId, dto, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("bulk-action")]
    public async Task<IActionResult> BulkAction([FromBody] BulkActionRequestDto dto)
    {
        var requiredPermission = ResolveBulkActionPermission(dto.Action);
        if (!User.HasPermission(requiredPermission))
        {
            return this.ForbiddenProblemResponse(
                $"The authenticated principal does not have the required permission '{requiredPermission}'.");
        }

        await _userService.BulkActionAsync(dto, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpGet("export")]
    [RequirePermission(Permissions.UsersExport)]
    public async Task Export([FromQuery] UserListQueryDto query)
    {
        var filename = $"users-export-{DateTime.UtcNow:yyyyMMddHHmm}.csv";
        Response.ContentType = "text/csv";
        Response.Headers.Append("Content-Disposition", $"attachment; filename={filename}");

        await _userService.ExportToCsvToStreamAsync(Response.Body, query, HttpContext.RequestAborted);
        await Response.Body.FlushAsync();
    }

    [HttpPut("{userId:guid}/convert-role")]
    [RequirePermission(Permissions.AdminsManage)]
    public async Task<IActionResult> ConvertRole(Guid userId, [FromBody] ConvertRoleRequestDto dto)
    {
        await _userService.ConvertRoleAsync(userId, dto, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("{userId:guid}/unban")]
    [RequirePermission(Permissions.UsersBan)]
    public async Task<IActionResult> Unban(Guid userId)
    {
        await _userService.UnbanUserAsync(userId, HttpContext.RequestAborted);
        return Ok(ApiResponse<object?>.Ok(null, "User unbanned successfully"));
    }

    [HttpPost("{userId:guid}/unsuspend")]
    [RequirePermission(Permissions.UsersSuspend)]
    public async Task<IActionResult> Unsuspend(Guid userId)
    {
        await _userService.UnsuspendUserAsync(userId, HttpContext.RequestAborted);
        return Ok(ApiResponse<object?>.Ok(null, "User unsuspended successfully"));
    }

    private static string ResolveBulkActionPermission(string? action)
    {
        return action?.Trim().ToLowerInvariant() switch
        {
            "activate" or "deactivate" => Permissions.UsersEdit,
            "suspend" or "unsuspend" => Permissions.UsersSuspend,
            "ban" or "unban" => Permissions.UsersBan,
            _ => throw new ArgumentException($"Unsupported bulk action '{action}'.")
        };
    }
}
