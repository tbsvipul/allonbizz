using System.Globalization;
using System.Text;
using System.Text.Json;
using CsvHelper;
using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Data.Interfaces;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class UserService : IUserService
{
    private readonly AppDbContext _db;
    private readonly IRepository<User> _userRepo;
    private readonly IRepository<Redemption> _redemptionRepo;
    private readonly IRepository<Review> _reviewRepo;
    private readonly IRepository<Notification> _notificationRepo;
    private readonly IRepository<Journey> _journeyRepo;
    private readonly IRepository<UserReport> _reportRepo;
    private readonly IAuthService _authService;
    private readonly IAuditService _auditService;
    private readonly ILogger<UserService> _logger;

    public UserService(
        AppDbContext db,
        IRepository<User> userRepo,
        IRepository<Redemption> redemptionRepo,
        IRepository<Review> reviewRepo,
        IRepository<Notification> notificationRepo,
        IRepository<Journey> journeyRepo,
        IRepository<UserReport> reportRepo,
        IAuthService authService,
        IAuditService auditService,
        ILogger<UserService> logger)
    {
        _db = db;
        _userRepo = userRepo;
        _redemptionRepo = redemptionRepo;
        _reviewRepo = reviewRepo;
        _notificationRepo = notificationRepo;
        _journeyRepo = journeyRepo;
        _reportRepo = reportRepo;
        _authService = authService;
        _auditService = auditService;
        _logger = logger;
    }

    public async Task<PagedResponse<UserDetailDto>> GetUsersAsync(UserListQueryDto query, CancellationToken ct = default)
    {
        var q = _userRepo.Query().AsNoTracking();

        if (!string.IsNullOrEmpty(query.Search))
            q = q.Where(u => (u.Email != null && u.Email.Contains(query.Search)) || u.FirstName.Contains(query.Search) || u.LastName.Contains(query.Search));
        if (!string.IsNullOrEmpty(query.Status))
            q = ApplyStatusFilter(q, query.Status);
        if (!string.IsNullOrEmpty(query.Role))
            q = q.Where(u => u.Role.ToLower() == query.Role.ToLower());
        if (query.DateFrom.HasValue)
            q = q.Where(u => u.CreatedAt >= query.DateFrom.Value);
        if (query.DateTo.HasValue)
            q = q.Where(u => u.CreatedAt <= query.DateTo.Value);

        q = query.SortBy?.ToLower() switch
        {
            "email" => query.SortOrder == "asc" ? q.OrderBy(u => u.Email) : q.OrderByDescending(u => u.Email),
            "name" => query.SortOrder == "asc" ? q.OrderBy(u => u.FirstName) : q.OrderByDescending(u => u.FirstName),
            _ => query.SortOrder == "asc" ? q.OrderBy(u => u.CreatedAt) : q.OrderByDescending(u => u.CreatedAt)
        };

        var totalCount = await q.CountAsync(ct);
        var users = await q
            .Skip((query.Page - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(ct);

        var items = users.Select(u => new UserDetailDto
        {
            UserId = u.UserId,
            Email = u.Email ?? string.Empty,
            FirstName = u.FirstName,
            LastName = u.LastName,
            Phone = u.PhoneNumber,
            AvatarUrl = u.ProfilePhotoUrl,
            Status = MapStatus(u),
            Role = u.Role,
            Is2FAEnabled = u.Is2FAEnabled,
            CreatedAt = u.CreatedAt,
            LastLoginAt = u.LastLoginAt,
            LastLoginIp = u.LastLoginIp
        }).ToList();

        return new PagedResponse<UserDetailDto>
        {
            Data = items,
            Pagination = new PaginationMeta
            {
                Page = query.Page,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<UserDetailDto> GetUserDetailAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        return await BuildUserDetailAsync(user, ct);
    }

    public async Task<AdminUserProfileDto> GetUserProfileAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _userRepo.Query()
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.UserId == userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        var summary = await BuildUserDetailAsync(user, ct);
        var activity = await GetUserActivityAsync(userId, ct);
        var loginHistory = await GetLoginHistoryAsync(userId, new PaginationParams
        {
            PageNumber = 1,
            PageSize = 20
        }, ct);

        var profile = new AdminUserProfileDto
        {
            Summary = summary,
            Activity = activity,
            LoginHistory = loginHistory.Data.ToList()
        };

        if (string.Equals(user.Role, "customer", StringComparison.OrdinalIgnoreCase))
        {
            profile.Customer = await BuildCustomerProfileAsync(user, ct);
        }

        if (string.Equals(user.Role, "keeper", StringComparison.OrdinalIgnoreCase))
        {
            profile.Keeper = await BuildKeeperProfileAsync(user, ct);
        }

        return profile;
    }

    public async Task<UserActivityDto> GetUserActivityAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _userRepo.Query().AsNoTracking().FirstOrDefaultAsync(u => u.UserId == userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        var recentJourneys = await _journeyRepo.Query()
            .AsNoTracking()
            .Where(j => j.UserId == userId)
            .OrderByDescending(j => j.StartTime)
            .Take(10)
            .Select(j => new ActivityItemDto
            {
                Type = "journey",
                Description = $"Journey started from {j.StartName ?? "Unknown"}",
                Timestamp = j.StartTime
            })
            .ToListAsync(ct);

        var recentRedemptions = await _redemptionRepo.Query()
            .AsNoTracking()
            .Include(r => r.Offer)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.RedeemedAt)
            .Take(10)
            .Select(r => new ActivityItemDto
            {
                Type = "redemption",
                Description = $"Redeemed offer {(r.Offer != null ? r.Offer.Title : r.OfferId.ToString())}",
                Timestamp = r.RedeemedAt
            })
            .ToListAsync(ct);

        var recentReviews = await _reviewRepo.Query()
            .AsNoTracking()
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .Take(10)
            .Select(r => new ActivityItemDto
            {
                Type = "review",
                Description = $"Submitted a {r.Rating}-star review",
                Timestamp = r.CreatedAt
            })
            .ToListAsync(ct);

        var totalOrders = await _redemptionRepo.Query().CountAsync(r => r.UserId == userId, ct);
        var totalReviews = await _reviewRepo.Query().CountAsync(r => r.UserId == userId, ct);
        var totalReports = await _reportRepo.Query().CountAsync(r => r.ReportedBy == userId, ct);

        var recentActivities = recentJourneys
            .Concat(recentRedemptions)
            .Concat(recentReviews)
            .OrderByDescending(activity => activity.Timestamp)
            .Take(20)
            .ToList();

        return new UserActivityDto
        {
            UserId = userId,
            LastActiveAt = recentActivities.FirstOrDefault()?.Timestamp ?? user.LastLoginAt,
            RecentActivities = recentActivities,
            TotalOrders = totalOrders,
            TotalReviews = totalReviews,
            TotalReports = totalReports
        };
    }

    public async Task<PagedResponse<LoginHistoryItemDto>> GetLoginHistoryAsync(Guid userId, PaginationParams paging, CancellationToken ct = default)
    {
        var user = await _userRepo.Query().AsNoTracking().FirstOrDefaultAsync(u => u.UserId == userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        var loginEventsQuery = _db.RefreshTokens
            .AsNoTracking()
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.CreatedAt);

        var totalCount = await loginEventsQuery.CountAsync(ct);
        var pagedItems = await loginEventsQuery
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .Select(t => new LoginHistoryItemDto
            {
                LoginAt = t.CreatedAt,
                IpAddress = t.CreatedByIp ?? string.Empty,
                UserAgent = null,
                Location = null,
                Success = true
            })
            .ToListAsync(ct);

        return new PagedResponse<LoginHistoryItemDto>
        {
            Data = pagedItems,
            Pagination = new PaginationMeta
            {
                Page = paging.PageNumber,
                PageSize = paging.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task UpdateStatusAsync(Guid userId, UpdateStatusRequestDto dto, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        ApplyUserStatus(user, dto.Status, dto.Reason, null);
        _userRepo.Update(user);

        if (user.Status != UserStatus.Active)
        {
            await RevokeActiveTokensAsync(userId, ct);
        }

        await _userRepo.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} status updated to {Status}", userId, dto.Status);
    }

    public async Task ForcePasswordResetAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        if (string.IsNullOrWhiteSpace(user.Email))
        {
            throw new InvalidOperationException("User does not have an email address for password reset.");
        }

        await RevokeActiveTokensAsync(userId, ct);
        await _userRepo.SaveChangesAsync(ct);
        await _authService.ForgotPasswordAsync(user.Email);
        _logger.LogInformation("Password reset requested for user {UserId}", userId);
    }

    public async Task Reset2FAAsync(Guid userId, Guid actorAdminId, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        user.Is2FAEnabled = false;
        user.TotpSecret = null;
        user.UpdatedAt = DateTime.UtcNow;
        _userRepo.Update(user);
        await RevokeActiveTokensAsync(userId, ct);
        await _userRepo.SaveChangesAsync(ct);
        await _auditService.LogAsync(actorAdminId, "USER_RESET_2FA", nameof(User), userId.ToString(), null, "N/A");
    }

    public async Task TerminateSessionsAsync(Guid userId, CancellationToken ct = default)
    {
        _ = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        await RevokeActiveTokensAsync(userId, ct);
        await _userRepo.SaveChangesAsync(ct);
        _logger.LogInformation("All sessions terminated for user {UserId}", userId);
    }

    public async Task SuspendUserAsync(Guid userId, SuspendUserRequestDto dto, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        ApplyUserStatus(
            user,
            UserStatus.Suspended.ToString(),
            dto.Reason,
            dto.DurationDays.HasValue ? DateTime.UtcNow.AddDays(dto.DurationDays.Value) : null);
        _userRepo.Update(user);
        await RevokeActiveTokensAsync(userId, ct);
        await _userRepo.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} suspended. Reason: {Reason}", userId, dto.Reason);
    }

    public async Task BanUserAsync(Guid userId, BanUserRequestDto dto, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        ApplyUserStatus(user, UserStatus.Banned.ToString(), dto.Reason, null);
        _userRepo.Update(user);
        await RevokeActiveTokensAsync(userId, ct);
        await _userRepo.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} banned. Reason: {Reason}", userId, dto.Reason);
    }

    public async Task SendWarningAsync(Guid userId, WarnUserRequestDto dto, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        var notification = new Notification
        {
            UserId = userId,
            Title = "Account warning",
            Message = dto.Message,
            Type = NotificationType.SystemMessage,
            Priority = MapPriority(dto.Severity),
            TargetAudience = NotificationAudienceHelper.Normalize(user.Role),
            Status = NotificationStatus.Sent,
            RecipientCount = 1,
            SentAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _notificationRepo.AddAsync(notification, ct);
        await _notificationRepo.SaveChangesAsync(ct);
        _logger.LogInformation("Warning sent to user {UserId}: {Message}", userId, dto.Message);
    }

    public async Task BulkActionAsync(BulkActionRequestDto dto, CancellationToken ct = default)
    {
        foreach (var userId in dto.UserIds)
        {
            var user = await _userRepo.GetByIdAsync(userId, ct);
            if (user != null)
            {
                switch (dto.Action.Trim().ToLowerInvariant())
                {
                    case "activate":
                        ApplyUserStatus(user, UserStatus.Active.ToString(), dto.Reason, null);
                        break;
                    case "deactivate":
                        ApplyUserStatus(user, UserStatus.Deactivated.ToString(), dto.Reason, null);
                        break;
                    case "suspend":
                        ApplyUserStatus(user, UserStatus.Suspended.ToString(), dto.Reason, null);
                        break;
                    case "unsuspend":
                        ApplyUserStatus(user, UserStatus.Active.ToString(), null, null);
                        break;
                    case "ban":
                        ApplyUserStatus(user, UserStatus.Banned.ToString(), dto.Reason, null);
                        break;
                    case "unban":
                        ApplyUserStatus(user, UserStatus.Active.ToString(), null, null);
                        break;
                    default:
                        throw new ArgumentException($"Unsupported bulk action '{dto.Action}'.");
                }

                _userRepo.Update(user);
            }
        }

        foreach (var affectedUserId in dto.UserIds.Distinct())
        {
            if (!dto.Action.Equals("activate", StringComparison.OrdinalIgnoreCase))
            {
                await RevokeActiveTokensAsync(affectedUserId, ct);
            }
        }

        await _userRepo.SaveChangesAsync(ct);
        _logger.LogInformation("Bulk action {Action} applied to {Count} users", dto.Action, dto.UserIds.Count);
    }

    public async Task ExportToCsvToStreamAsync(Stream outputStream, UserListQueryDto query, CancellationToken ct = default)
    {
        using var writer = new StreamWriter(outputStream, Encoding.UTF8, leaveOpen: true);
        using var csv = new CsvWriter(writer, CultureInfo.InvariantCulture);

        int page = 1;
        const int batchSize = 1000;

        while (true)
        {
            var batchQuery = _userRepo.Query().AsNoTracking();
            
            if (!string.IsNullOrEmpty(query.Search))
                batchQuery = batchQuery.Where(u => (u.Email != null && u.Email.Contains(query.Search)) || u.FirstName.Contains(query.Search) || u.LastName.Contains(query.Search));
            if (!string.IsNullOrEmpty(query.Status))
                batchQuery = ApplyStatusFilter(batchQuery, query.Status);
            if (!string.IsNullOrEmpty(query.Role))
                batchQuery = batchQuery.Where(u => u.Role == query.Role);

            var usersBatch = await batchQuery
                .OrderBy(u => u.UserId)
                .Skip((page - 1) * batchSize)
                .Take(batchSize)
                .ToListAsync(ct);

            var batch = usersBatch.Select(u => new UserDetailDto
            {
                UserId = u.UserId,
                Email = u.Email ?? string.Empty,
                FirstName = u.FirstName,
                LastName = u.LastName,
                Status = MapStatus(u),
                Role = u.Role,
                CreatedAt = u.CreatedAt,
                LastLoginAt = u.LastLoginAt,
                LastLoginIp = u.LastLoginIp
            }).ToList();

            if (batch.Count == 0) break;

            csv.WriteRecords(batch);
            await writer.FlushAsync();
            
            page++;
            if (batch.Count < batchSize) break;
        }
    }

    private static readonly HashSet<string> AllowedRoles = new(StringComparer.OrdinalIgnoreCase)
    { "customer", "keeper" };

    public async Task ConvertRoleAsync(Guid userId, ConvertRoleRequestDto dto, CancellationToken ct = default)
    {
        if (!AllowedRoles.Contains(dto.NewRole))
            throw new ArgumentException($"Role '{dto.NewRole}' is not allowed.");

        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        user.Role = dto.NewRole;
        user.UpdatedAt = DateTime.UtcNow;
        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} role converted to {NewRole}", userId, dto.NewRole);
    }

    public async Task UnbanUserAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        ApplyUserStatus(user, UserStatus.Active.ToString(), null, null);
        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} unbanned", userId);
    }

    public async Task UnsuspendUserAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _userRepo.GetByIdAsync(userId, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        ApplyUserStatus(user, UserStatus.Active.ToString(), null, null);
        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} unsuspended", userId);
    }

    private static IQueryable<User> ApplyStatusFilter(IQueryable<User> query, string status)
    {
        return status.Trim().ToLowerInvariant() switch
        {
            "active" => query.Where(u => u.Status == UserStatus.Active && u.IsActive),
            "inactive" => query.Where(u => !u.IsActive || u.Status == UserStatus.Deactivated),
            "suspended" => query.Where(u => u.Status == UserStatus.Suspended),
            "banned" => query.Where(u => u.Status == UserStatus.Banned),
            "pending" or "pendingverification" => query.Where(u => u.Status == UserStatus.PendingVerification),
            _ => query
        };
    }

    private static string MapStatus(User user)
    {
        return user.Status switch
        {
            UserStatus.Active when user.IsActive => "Active",
            UserStatus.Suspended => "Suspended",
            UserStatus.Banned => "Banned",
            UserStatus.PendingVerification => "PendingVerification",
            UserStatus.Deactivated => "Inactive",
            _ when !user.IsActive => "Inactive",
            _ => user.Status.ToString()
        };
    }

    private static void ApplyUserStatus(User user, string statusValue, string? reason, DateTime? suspendedUntil)
    {
        var normalizedStatus = statusValue.Trim().ToLowerInvariant() switch
        {
            "inactive" => nameof(UserStatus.Deactivated),
            _ => statusValue
        };

        if (!Enum.TryParse<UserStatus>(normalizedStatus, true, out var status))
        {
            throw new ArgumentException($"Unsupported user status '{statusValue}'.");
        }

        user.Status = status;
        user.IsActive = status == UserStatus.Active;
        user.StatusReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
        user.SuspendedUntil = status == UserStatus.Suspended ? suspendedUntil : null;
        user.StatusChangedAt = DateTime.UtcNow;
        user.UpdatedAt = DateTime.UtcNow;
    }

    private static NotificationPriority MapPriority(string? severity)
    {
        return severity?.Trim().ToLowerInvariant() switch
        {
            "critical" => NotificationPriority.Critical,
            "high" => NotificationPriority.High,
            "low" => NotificationPriority.Low,
            _ => NotificationPriority.Normal
        };
    }

    private async Task<UserDetailDto> BuildUserDetailAsync(User user, CancellationToken ct)
    {
        var totalOrders = await _redemptionRepo.Query().CountAsync(r => r.UserId == user.UserId, ct);
        var totalReviews = await _reviewRepo.Query().CountAsync(r => r.UserId == user.UserId, ct);
        var warningCount = await _notificationRepo.Query().CountAsync(n =>
            n.UserId == user.UserId &&
            n.Type == NotificationType.SystemMessage, ct);

        return new UserDetailDto
        {
            UserId = user.UserId,
            Email = user.Email ?? string.Empty,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Phone = user.PhoneNumber,
            AvatarUrl = user.ProfilePhotoUrl,
            Status = MapStatus(user),
            Role = user.Role,
            Is2FAEnabled = user.Is2FAEnabled,
            CreatedAt = user.CreatedAt,
            LastLoginAt = user.LastLoginAt,
            LastLoginIp = user.LastLoginIp,
            TotalOrders = totalOrders,
            TotalReviews = totalReviews,
            WarningCount = warningCount
        };
    }

    private async Task<CustomerUserProfileDto> BuildCustomerProfileAsync(User user, CancellationToken ct)
    {
        var journeys = await _journeyRepo.Query()
            .AsNoTracking()
            .Include(j => j.User)
            .Where(j => j.UserId == user.UserId)
            .OrderByDescending(j => j.StartTime)
            .Take(20)
            .Select(j => new JourneyHistoryDto
            {
                JourneyId = j.JourneyId,
                UserId = j.UserId,
                UserEmail = j.User != null ? j.User.Email ?? string.Empty : string.Empty,
                Type = j.Type,
                StartName = j.StartName,
                StartLat = j.StartLat,
                StartLng = j.StartLng,
                EndName = j.EndName,
                EndLat = j.EndLat,
                EndLng = j.EndLng,
                StartTime = j.StartTime,
                EndTime = j.EndTime,
                Distance = j.Distance,
                Duration = j.Duration,
                Tags = DeserializeStringList(j.TagsJson),
                ShopsEncountered = DeserializeStringList(j.ShopsJson)
            })
            .ToListAsync(ct);

        var redemptions = await _redemptionRepo.Query()
            .AsNoTracking()
            .Include(r => r.Offer)
            .Include(r => r.Shop)
            .Where(r => r.UserId == user.UserId)
            .OrderByDescending(r => r.RedeemedAt)
            .Take(20)
            .Select(r => new UserRedemptionSummaryDto
            {
                RedemptionId = r.RedemptionId,
                OfferId = r.OfferId,
                ShopId = r.ShopId,
                OfferTitle = r.Offer != null ? r.Offer.Title : "Unknown offer",
                ShopName = r.Shop != null ? r.Shop.Name : "Unknown shop",
                Status = r.Status.ToString(),
                SavedAmount = r.SavedAmount,
                LoyaltyPointsEarned = r.LoyaltyPointsEarned,
                RedeemedAt = r.RedeemedAt
            })
            .ToListAsync(ct);

        var reviews = await _reviewRepo.Query()
            .AsNoTracking()
            .Include(r => r.Shop)
            .Include(r => r.Offer)
            .Where(r => r.UserId == user.UserId)
            .OrderByDescending(r => r.CreatedAt)
            .Take(20)
            .Select(r => new ReviewDto
            {
                ReviewId = r.ReviewId,
                UserId = r.UserId,
                UserFullName = $"{user.FirstName} {user.LastName}".Trim(),
                ShopId = r.ShopId,
                ShopName = r.Shop != null ? r.Shop.Name : "Unknown",
                OfferId = r.OfferId,
                OfferTitle = r.Offer != null ? r.Offer.Title : null,
                Rating = r.Rating,
                Comment = r.Comment,
                Reply = r.Reply,
                RepliedAt = r.RepliedAt,
                CreatedAt = r.CreatedAt,
                Status = r.Status.ToString()
            })
            .ToListAsync(ct);

        return new CustomerUserProfileDto
        {
            Journeys = journeys,
            Redemptions = redemptions,
            Reviews = reviews
        };
    }

    private async Task<KeeperUserProfileDto?> BuildKeeperProfileAsync(User user, CancellationToken ct)
    {
        var keeper = await _db.Keepers
            .AsNoTracking()
            .Include(k => k.Documents)
            .FirstOrDefaultAsync(k => k.UserId == user.UserId, ct);

        if (keeper == null)
        {
            return null;
        }

        var shops = await _db.Shops
            .AsNoTracking()
            .Include(s => s.Category)
            .Where(s => s.KeeperId == keeper.KeeperId)
            .OrderByDescending(s => s.CreatedAt)
            .Select(s => new ShopSummaryDto
            {
                Id = s.ShopId,
                Name = s.Name,
                BusinessName = keeper.BusinessName,
                Location = s.Address ?? "Unknown",
                Category = s.Category != null ? s.Category.Name : "Uncategorized",
                Status = s.IsActive ? "Active" : "Inactive",
                IsVerified = s.IsVerified,
                Latitude = s.Latitude,
                Longitude = s.Longitude,
                ImageUrl = s.ImageUrl
            })
            .ToListAsync(ct);

        var offers = await _db.Offers
            .AsNoTracking()
            .Include(o => o.Shop)
            .Where(o => o.KeeperId == keeper.KeeperId)
            .OrderByDescending(o => o.CreatedAt)
            .Take(20)
            .Select(o => new AdminOfferListItemDto
            {
                Id = o.OfferId,
                Title = o.Title,
                KeeperName = keeper.BusinessName,
                ShopName = o.Shop != null ? o.Shop.Name : "Unknown",
                Status = o.Status.ToString(),
                Redemptions = o.CurrentRedemptions,
                StartDate = o.StartDate,
                EndDate = o.EndDate,
                CreatedAt = o.CreatedAt
            })
            .ToListAsync(ct);

        var shopIds = shops.Select(shop => shop.Id).ToList();
        var reviews = shopIds.Count == 0
            ? new List<AdminReviewSummaryDto>()
            : await _reviewRepo.Query()
                .AsNoTracking()
                .Include(r => r.User)
                .Include(r => r.Shop)
                .Where(r => r.ShopId.HasValue && shopIds.Contains(r.ShopId.Value))
                .OrderByDescending(r => r.CreatedAt)
                .Take(20)
                .Select(r => new AdminReviewSummaryDto
                {
                    ReviewId = r.ReviewId,
                    UserName = r.User != null ? $"{r.User.FirstName} {r.User.LastName}".Trim() : "Anonymous",
                    ShopName = r.Shop != null ? r.Shop.Name : "Unknown",
                    Rating = r.Rating,
                    Comment = r.Comment,
                    Status = r.Status.ToString(),
                    CreatedAt = r.CreatedAt,
                    Reply = r.Reply,
                    RepliedAt = r.RepliedAt
                })
                .ToListAsync(ct);

        return new KeeperUserProfileDto
        {
            KeeperId = keeper.KeeperId,
            BusinessName = keeper.BusinessName,
            BusinessLicense = keeper.BusinessLicense,
            GstNumber = keeper.GstNumber,
            PanNumber = keeper.PanNumber,
            Status = keeper.Status.ToString(),
            RejectionReason = keeper.RejectionReason ?? keeper.HoldReason,
            ApprovedAt = keeper.ApprovedAt,
            Documents = BuildKeeperDocuments(keeper),
            Shops = shops,
            Offers = offers,
            ShopReviews = reviews
        };
    }

    private static List<KeeperDocumentDto> BuildKeeperDocuments(Keeper keeper)
    {
        if (keeper.Documents.Count > 0)
        {
            return keeper.Documents
                .OrderBy(document => document.CreatedAt)
                .Select(document => new KeeperDocumentDto
                {
                    Id = document.DocumentId.ToString(),
                    Name = document.Name,
                    Type = document.DocumentType,
                    Url = document.DocumentReference
                })
                .ToList();
        }

        if (string.IsNullOrWhiteSpace(keeper.DocumentData))
        {
            return new List<KeeperDocumentDto>();
        }

        var documentUrl = keeper.DocumentData.StartsWith("http", StringComparison.OrdinalIgnoreCase) ||
                          keeper.DocumentData.StartsWith("data:", StringComparison.OrdinalIgnoreCase)
            ? keeper.DocumentData
            : $"data:application/octet-stream;base64,{keeper.DocumentData}";

        return new List<KeeperDocumentDto>
        {
            new()
            {
                Id = keeper.KeeperId.ToString(),
                Name = "Business Document",
                Type = "Primary",
                Url = documentUrl
            }
        };
    }

    private static List<string> DeserializeStringList(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new List<string>();
        }

        return JsonSerializer.Deserialize<List<string>>(json) ?? new List<string>();
    }

    private async Task RevokeActiveTokensAsync(Guid userId, CancellationToken ct)
    {
        var tokens = await _db.RefreshTokens
            .Where(t => t.UserId == userId && !t.IsUsed && !t.IsRevoked)
            .ToListAsync(ct);

        foreach (var token in tokens)
        {
            token.IsRevoked = true;
        }
    }
}
