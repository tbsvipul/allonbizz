using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data.Interfaces;
using allonbiz.AdminAPI.DTOs.Admin;
using allonbiz.AdminAPI.DTOs.Common;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class AdminOfferService : IAdminOfferService
{
    private readonly IRepository<Offer> _offerRepo;

    public AdminOfferService(IRepository<Offer> offerRepo) => _offerRepo = offerRepo;

    public async Task<PagedResponse<AdminOfferListItemDto>> GetOffersAsync(AdminOfferListQueryDto query, CancellationToken ct = default)
    {
        var offers = _offerRepo.Query()
            .AsNoTracking()
            .Include(o => o.Keeper)
            .Include(o => o.Shop)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim();
            offers = offers.Where(o =>
                o.Title.Contains(search) ||
                (o.Keeper != null && o.Keeper.BusinessName.Contains(search)) ||
                (o.Shop != null && o.Shop.Name.Contains(search)));
        }

        if (!string.IsNullOrWhiteSpace(query.Status) &&
            Enum.TryParse<OfferStatus>(query.Status, true, out var status))
        {
            offers = offers.Where(o => o.Status == status);
        }

        var totalCount = await offers.CountAsync(ct);
        var items = await offers
            .OrderByDescending(o => o.CreatedAt)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .Select(o => new AdminOfferListItemDto
            {
                Id = o.OfferId,
                Title = o.Title,
                KeeperName = o.Keeper != null ? o.Keeper.BusinessName : "Unknown",
                ShopName = o.Shop != null ? o.Shop.Name : "Unknown",
                Status = o.Status.ToString(),
                Redemptions = o.CurrentRedemptions,
                StartDate = o.StartDate,
                EndDate = o.EndDate,
                CreatedAt = o.CreatedAt
            })
            .ToListAsync(ct);

        return new PagedResponse<AdminOfferListItemDto>
        {
            Data = items,
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task UpdateStatusAsync(Guid offerId, UpdateOfferStatusDto dto, CancellationToken ct = default)
    {
        if (!Enum.TryParse<OfferStatus>(dto.Status, true, out var status))
        {
            throw new ArgumentException("Invalid status");
        }

        var updated = await _offerRepo.Query()
            .Where(offer => offer.OfferId == offerId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(offer => offer.Status, status)
                .SetProperty(offer => offer.IsActive, status == OfferStatus.Active)
                .SetProperty(offer => offer.UpdatedAt, DateTime.UtcNow), ct);

        if (updated == 0)
        {
            throw new KeyNotFoundException($"Offer {offerId} not found.");
        }
    }

    public async Task DeleteAsync(Guid offerId, CancellationToken ct = default)
    {
        var deleted = await _offerRepo.Query()
            .Where(offer => offer.OfferId == offerId)
            .ExecuteDeleteAsync(ct);

        if (deleted == 0)
        {
            throw new KeyNotFoundException($"Offer {offerId} not found.");
        }
    }
}

public class AdminReviewService : IAdminReviewService
{
    private readonly IRepository<Review> _reviewRepo;

    public AdminReviewService(IRepository<Review> reviewRepo) => _reviewRepo = reviewRepo;

    public async Task<PagedResponse<AdminReviewSummaryDto>> GetReviewsAsync(AdminReviewListQueryDto query, CancellationToken ct = default)
    {
        var reviews = _reviewRepo.Query()
            .AsNoTracking()
            .Include(r => r.User)
            .Include(r => r.Shop)
            .AsQueryable();

        if (query.ShopId.HasValue)
        {
            reviews = reviews.Where(r => r.ShopId == query.ShopId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Status) &&
            Enum.TryParse<ReviewStatus>(query.Status, true, out var status))
        {
            reviews = reviews.Where(r => r.Status == status);
        }

        var totalCount = await reviews.CountAsync(ct);
        var items = await reviews
            .OrderByDescending(r => r.CreatedAt)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
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

        return new PagedResponse<AdminReviewSummaryDto>
        {
            Data = items,
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task UpdateStatusAsync(Guid reviewId, UpdateReviewStatusDto dto, CancellationToken ct = default)
    {
        var review = await _reviewRepo.GetByIdAsync(reviewId, ct)
            ?? throw new KeyNotFoundException($"Review {reviewId} not found.");

        if (!Enum.TryParse<ReviewStatus>(dto.Status, true, out var status))
        {
            throw new ArgumentException("Invalid status");
        }

        review.Status = status;
        _reviewRepo.Update(review);
        await _reviewRepo.SaveChangesAsync(ct);
    }
}

public class AdminJourneyService : IAdminJourneyService
{
    private readonly IRepository<Journey> _journeyRepo;

    public AdminJourneyService(IRepository<Journey> journeyRepo) => _journeyRepo = journeyRepo;

    public async Task<PagedResponse<AdminJourneyListDto>> GetJourneysAsync(AdminJourneyListQueryDto query, CancellationToken ct = default)
    {
        var journeys = _journeyRepo.Query()
            .AsNoTracking()
            .Include(j => j.User)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var term = query.Search.Trim().ToLower();
            journeys = journeys.Where(j =>
                (j.StartName != null && j.StartName.ToLower().Contains(term)) ||
                (j.EndName != null && j.EndName.ToLower().Contains(term)) ||
                (j.User != null && j.User.Email != null && j.User.Email.ToLower().Contains(term)));
        }

        if (!string.IsNullOrWhiteSpace(query.Status))
        {
            journeys = journeys.Where(j => j.Status == query.Status);
        }

        if (!string.IsNullOrWhiteSpace(query.Type))
        {
            journeys = journeys.Where(j => j.Type == query.Type);
        }

        var totalCount = await journeys.CountAsync(ct);
        var items = await journeys
            .OrderByDescending(j => j.StartTime)
            .Skip((query.PageNumber - 1) * query.PageSize)
            .Take(query.PageSize)
            .Select(j => new AdminJourneyListDto
            {
                JourneyId = j.JourneyId,
                UserId = j.UserId,
                UserEmail = j.User != null ? j.User.Email ?? string.Empty : string.Empty,
                UserName = j.User != null ? $"{j.User.FirstName} {j.User.LastName}".Trim() : "Unknown",
                Type = j.Type,
                Status = j.Status,
                StartName = j.StartName,
                EndName = j.EndName,
                Distance = j.Distance,
                Duration = j.Duration,
                OffersRedeemed = j.OffersRedeemed,
                TotalSavings = j.TotalSavings,
                StartTime = j.StartTime,
                EndTime = j.EndTime
            })
            .ToListAsync(ct);

        return new PagedResponse<AdminJourneyListDto>
        {
            Data = items,
            Pagination = new PaginationMeta
            {
                Page = query.PageNumber,
                PageSize = query.PageSize,
                TotalCount = totalCount
            }
        };
    }

    public async Task<AdminJourneyDetailDto> GetJourneyDetailAsync(Guid journeyId, CancellationToken ct = default)
    {
        var journey = await _journeyRepo.Query()
            .AsNoTracking()
            .Include(j => j.User)
            .FirstOrDefaultAsync(j => j.JourneyId == journeyId, ct)
            ?? throw new KeyNotFoundException($"Journey {journeyId} not found.");

        return new AdminJourneyDetailDto
        {
            JourneyId = journey.JourneyId,
            UserId = journey.UserId,
            UserEmail = journey.User?.Email ?? string.Empty,
            UserName = journey.User != null ? $"{journey.User.FirstName} {journey.User.LastName}".Trim() : "Unknown",
            Type = journey.Type,
            Status = journey.Status,
            StartName = journey.StartName,
            EndName = journey.EndName,
            Distance = journey.Distance,
            Duration = journey.Duration,
            OffersRedeemed = journey.OffersRedeemed,
            TotalSavings = journey.TotalSavings,
            StartTime = journey.StartTime,
            EndTime = journey.EndTime,
            StartLat = journey.StartLat,
            StartLng = journey.StartLng,
            EndLat = journey.EndLat,
            EndLng = journey.EndLng,
            LikesCount = journey.LikesCount,
            ViewsCount = journey.ViewsCount,
            Tags = DeserializeStringList(journey.TagsJson),
            ShopsEncountered = DeserializeStringList(journey.ShopsJson),
            Path = DeserializePath(journey.PathJson)
        };
    }

    public async Task DeleteJourneyAsync(Guid journeyId, CancellationToken ct = default)
    {
        var journey = await _journeyRepo.GetByIdAsync(journeyId, ct)
            ?? throw new KeyNotFoundException($"Journey {journeyId} not found.");

        _journeyRepo.Remove(journey);
        await _journeyRepo.SaveChangesAsync(ct);
    }

    private static List<string> DeserializeStringList(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new List<string>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<string>>(json) ?? new List<string>();
        }
        catch (JsonException)
        {
            return new List<string>();
        }
    }

    private static List<double[]> DeserializePath(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new List<double[]>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<double[]>>(json) ?? new List<double[]>();
        }
        catch (JsonException)
        {
            return new List<double[]>();
        }
    }
}
