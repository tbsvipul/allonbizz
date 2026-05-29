using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualBasic.FileIO;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.DTOs.Keepers;
using allonbiz.AdminAPI.DTOs.Shops;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Services.Interfaces;

namespace allonbiz.AdminAPI.Services;

public class KeeperContextService : IKeeperContextService
{
    private readonly AppDbContext _db;

    public KeeperContextService(AppDbContext db) => _db = db;

    public async Task<Keeper> GetRequiredKeeperAsync(Guid userId, CancellationToken ct = default)
    {
        return await _db.Keepers
            .Include(keeper => keeper.User)
            .FirstOrDefaultAsync(keeper => keeper.UserId == userId, ct)
            ?? throw new KeyNotFoundException($"Keeper account for user {userId} was not found.");
    }

    public async Task<Keeper> GetRequiredActiveKeeperAsync(Guid userId, CancellationToken ct = default)
    {
        var keeper = await GetRequiredKeeperAsync(userId, ct);
        EnsureKeeperCanManage(keeper);
        return keeper;
    }

    private static void EnsureKeeperCanManage(Keeper keeper)
    {
        if (keeper.Status is KeeperStatus.Approved or KeeperStatus.Active)
        {
            return;
        }

        var message = keeper.Status switch
        {
            KeeperStatus.PendingApproval => "Your keeper account is pending approval and cannot manage operations yet.",
            KeeperStatus.OnHold when keeper.HoldUntil.HasValue =>
                $"Your keeper account is on hold until {keeper.HoldUntil.Value:yyyy-MM-dd HH:mm:ss} UTC.",
            KeeperStatus.OnHold => "Your keeper account is on hold and cannot manage operations right now.",
            KeeperStatus.Rejected => "Your keeper account was rejected. Please review the status details and update your profile if needed.",
            KeeperStatus.Suspended => "Your keeper account is suspended and cannot manage operations right now.",
            _ => "Your keeper account cannot manage business operations right now."
        };

        throw new InvalidOperationException(message);
    }
}

public class KeeperProfileService : IKeeperProfileService
{
    private readonly AppDbContext _db;
    public KeeperProfileService(AppDbContext db) => _db = db;

    public async Task<KeeperProfileDto> GetProfileAsync(Guid keeperId)
    {
        var keeper = await _db.Keepers
            .AsNoTracking()
            .Include(item => item.User)
            .Include(item => item.Documents)
            .Include(item => item.ReviewMessages)
                .ThenInclude(message => message.Admin)
            .FirstOrDefaultAsync(item => item.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");

        return new KeeperProfileDto
        {
            KeeperId = keeper.KeeperId,
            UserId = keeper.UserId,
            BusinessName = keeper.BusinessName,
            Email = keeper.User?.Email ?? string.Empty,
            ContactPhone = keeper.User?.PhoneNumber,
            BusinessLicense = keeper.BusinessLicense,
            GstNumber = keeper.GstNumber,
            PanNumber = keeper.PanNumber,
            SocialLinksJson = keeper.SocialLinksJson,
            Status = keeper.Status,
            RejectionReason = keeper.RejectionReason,
            HoldReason = keeper.HoldReason,
            HoldUntil = keeper.HoldUntil,
            ApprovedAt = keeper.ApprovedAt,
            Documents = KeeperDocumentHelper.BuildDocuments(keeper),
            ReviewMessages = keeper.ReviewMessages
                .OrderByDescending(message => message.CreatedAt)
                .Select(message => new KeeperReviewMessageHistoryDto
                {
                    MessageId = message.MessageId.ToString(),
                    MessageType = message.MessageType,
                    Message = message.Message,
                    AdminName = message.Admin != null
                        ? $"{message.Admin.FirstName} {message.Admin.LastName}".Trim()
                        : "Admin",
                    IsReadByKeeper = message.IsReadByKeeper,
                    CreatedAt = message.CreatedAt
                })
                .ToList(),
            IdentityProofType = keeper.IdentityProofType,
            IdentityProofNumber = keeper.IdentityProofNumber,
            IdentityProofImage = keeper.IdentityProofImage,
            BusinessLicenseNumber = keeper.BusinessLicenseNumber,
            BusinessLicenseImage = keeper.BusinessLicenseImage,
            GstCertificateImage = keeper.GstCertificateImage,
            PanCardImage = keeper.PanCardImage,
            AddressProofType = keeper.AddressProofType,
            AddressProofImage = keeper.AddressProofImage,
            ShopFrontImage = keeper.ShopFrontImage,
            ShopInsideImage = keeper.ShopInsideImage
        };
    }

    public async Task UpdateProfileAsync(Guid keeperId, UpdateKeeperProfileDto dto)
    {
        var keeper = await _db.Keepers
            .Include(item => item.User)
            .FirstOrDefaultAsync(item => item.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");

        var now = DateTime.UtcNow;
        keeper.BusinessName = dto.BusinessName.Trim();
        keeper.BusinessLicense = NormalizeOptional(dto.BusinessLicense);
        keeper.GstNumber = NormalizeOptional(dto.GstNumber);
        keeper.PanNumber = NormalizeOptional(dto.PanNumber);
        keeper.SocialLinksJson = NormalizeOptional(dto.SocialLinksJson);

        keeper.IdentityProofType = NormalizeOptional(dto.IdentityProofType);
        keeper.IdentityProofNumber = NormalizeOptional(dto.IdentityProofNumber);
        keeper.IdentityProofImage = dto.IdentityProofImage;
        keeper.BusinessLicenseNumber = NormalizeOptional(dto.BusinessLicenseNumber);
        keeper.BusinessLicenseImage = dto.BusinessLicenseImage;
        keeper.GstCertificateImage = dto.GstCertificateImage;
        keeper.PanCardImage = dto.PanCardImage;
        keeper.AddressProofType = NormalizeOptional(dto.AddressProofType);
        keeper.AddressProofImage = dto.AddressProofImage;
        keeper.ShopFrontImage = dto.ShopFrontImage;
        keeper.ShopInsideImage = dto.ShopInsideImage;

        keeper.UpdatedAt = now;
        ApplyPendingResubmissionIfNeeded(keeper, now);

        if (keeper.User != null)
        {
            keeper.User.PhoneNumber = NormalizeOptional(dto.ContactPhone);
            keeper.User.UpdatedAt = now;
        }

        await _db.SaveChangesAsync();
    }

    public async Task<Guid> CreateDocumentAsync(Guid keeperId, UpsertKeeperDocumentDto dto)
    {
        var keeper = await _db.Keepers
            .Include(item => item.Documents)
            .FirstOrDefaultAsync(item => item.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");

        var now = DateTime.UtcNow;
        var document = new KeeperDocument
        {
            DocumentId = Guid.NewGuid(),
            KeeperId = keeperId,
            Name = NormalizeRequired(dto.Name, nameof(dto.Name)),
            DocumentType = NormalizeRequired(dto.Type, nameof(dto.Type)),
            DocumentReference = KeeperDocumentHelper.NormalizeDocumentReference(NormalizeRequired(dto.Url, nameof(dto.Url))),
            Status = "pending",
            CreatedAt = now,
            UpdatedAt = now
        };

        keeper.DocumentData = null;
        keeper.UpdatedAt = now;
        ApplyPendingResubmissionIfNeeded(keeper, now);

        _db.KeeperDocuments.Add(document);
        await _db.SaveChangesAsync();
        return document.DocumentId;
    }

    public async Task UpdateDocumentAsync(Guid keeperId, Guid documentId, UpsertKeeperDocumentDto dto)
    {
        var keeper = await _db.Keepers
            .Include(item => item.Documents)
            .FirstOrDefaultAsync(item => item.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");

        var now = DateTime.UtcNow;
        var document = FindOrMaterializeDocument(keeper, documentId, now);
        document.Name = NormalizeRequired(dto.Name, nameof(dto.Name));
        document.DocumentType = NormalizeRequired(dto.Type, nameof(dto.Type));
        document.DocumentReference = KeeperDocumentHelper.NormalizeDocumentReference(NormalizeRequired(dto.Url, nameof(dto.Url)));
        document.Status = "pending";
        document.ReviewNotes = null;
        document.ReviewedAt = null;
        document.ReviewedByAdminId = null;
        document.UpdatedAt = now;

        keeper.DocumentData = null;
        keeper.UpdatedAt = now;
        ApplyPendingResubmissionIfNeeded(keeper, now);

        await _db.SaveChangesAsync();
    }

    public async Task DeleteDocumentAsync(Guid keeperId, Guid documentId)
    {
        var keeper = await _db.Keepers
            .Include(item => item.Documents)
            .FirstOrDefaultAsync(item => item.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Keeper {keeperId} not found.");

        var now = DateTime.UtcNow;
        var document = FindOrMaterializeDocument(keeper, documentId, now);
        keeper.DocumentData = null;
        keeper.UpdatedAt = now;

        _db.KeeperDocuments.Remove(document);
        await _db.SaveChangesAsync();
    }

    public async Task<int> MarkReviewMessagesReadAsync(Guid keeperId)
    {
        var unreadMessages = await _db.KeeperReviewMessages
            .Where(message => message.KeeperId == keeperId && !message.IsReadByKeeper)
            .ToListAsync();

        if (unreadMessages.Count == 0)
        {
            return 0;
        }

        foreach (var message in unreadMessages)
        {
            message.IsReadByKeeper = true;
        }

        await _db.SaveChangesAsync();
        return unreadMessages.Count;
    }

    public async Task<Guid> RegisterShopAsync(Guid keeperId, RegisterShopDto dto)
    {
        if (dto.CategoryId.HasValue)
        {
            var categoryExists = await _db.Categories
                .AsNoTracking()
                .AnyAsync(category => category.CategoryId == dto.CategoryId.Value);
            if (!categoryExists)
            {
                throw new ArgumentException($"Category {dto.CategoryId.Value} was not found.");
            }
        }

        var now = DateTime.UtcNow;
        var shop = new Shop
        {
            ShopId = Guid.NewGuid(),
            KeeperId = keeperId,
            Name = NormalizeRequired(dto.Name, nameof(dto.Name)),
            Description = NormalizeOptional(dto.Description),
            Address = NormalizeRequired(dto.Address, nameof(dto.Address)),
            PhoneNumber = NormalizeOptional(dto.PhoneNumber),
            Email = NormalizeOptional(dto.Email),
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            ImageUrl = ImageConversionHelper.ParseBase64Image(dto.ShopProfileImage),
            ShopImages = dto.ShopImages?
                .Select(ImageConversionHelper.ParseBase64Image)
                .OfType<byte[]>()
                .ToList() ?? new List<byte[]>(),
            CategoryId = dto.CategoryId,
            IsOpen = dto.IsOpen,
            NotificationRadius = dto.NotificationRadius,
            CreatedAt = now,
            UpdatedAt = now,
            Amenities = NormalizeStringList(dto.Amenities),
            Tags = NormalizeStringList(dto.Tags)
        };
        _db.Shops.Add(shop);
        await _db.SaveChangesAsync();
        return shop.ShopId;
    }

    public async Task<List<ShopSummaryDto>> GetMyShopsAsync(Guid keeperId)
    {
        var shops = await _db.Shops
            .Include(s => s.Keeper)
            .Include(s => s.Category)
            .Where(s => s.KeeperId == keeperId)
            .ToListAsync();

        return shops.Select(s => new ShopSummaryDto
        {
            Id = s.ShopId,
            Name = s.Name,
            BusinessName = s.Keeper != null ? s.Keeper.BusinessName : "N/A",
            Location = s.Address ?? "Unknown",
            Category = s.Category != null ? s.Category.Name : "Uncategorized",
            Status = s.IsActive ? "Active" : "Inactive",
            IsVerified = s.IsVerified,
            VerifyStatus = s.VerifyStatus,
            IsOpen = s.IsOpen,
            Latitude = s.Latitude,
            Longitude = s.Longitude,
            ShopProfileImage = ImageConversionHelper.ToBase64DataUrl(s.ImageUrl),
            RejectionReason = s.RejectionReason,
            DeactivateReason = s.DeactivateReason
        }).ToList();
    }

    public async Task SyncWithGoogleBusinessAsync(Guid shopId)
    {
        var shop = await _db.Shops.FindAsync(shopId);
        if (shop == null)
        {
            throw new KeyNotFoundException($"Shop {shopId} not found.");
        }

        shop.IsVerified = true;
        shop.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
    }

    private KeeperDocument FindOrMaterializeDocument(Keeper keeper, Guid documentId, DateTime now)
    {
        var document = keeper.Documents.FirstOrDefault(item => item.DocumentId == documentId);
        if (document != null)
        {
            return document;
        }

        if (!string.IsNullOrWhiteSpace(keeper.DocumentData) && documentId == keeper.KeeperId)
        {
            document = new KeeperDocument
            {
                DocumentId = documentId,
                KeeperId = keeper.KeeperId,
                Name = "Business Document",
                DocumentType = "Primary",
                DocumentReference = KeeperDocumentHelper.NormalizeDocumentReference(keeper.DocumentData),
                Status = "pending",
                CreatedAt = keeper.CreatedAt,
                UpdatedAt = now
            };

            keeper.DocumentData = null;
            _db.KeeperDocuments.Add(document);
            return document;
        }

        throw new KeyNotFoundException($"Document {documentId} not found for keeper {keeper.KeeperId}.");
    }

    private static void ApplyPendingResubmissionIfNeeded(Keeper keeper, DateTime now)
    {
        if (keeper.Status is not (KeeperStatus.OnHold or KeeperStatus.Rejected))
        {
            return;
        }

        keeper.Status = KeeperStatus.PendingApproval;
        keeper.RejectionReason = null;
        keeper.HoldReason = null;
        keeper.HoldUntil = null;
        keeper.ApprovedAt = null;
        keeper.UpdatedAt = now;
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static List<string> NormalizeStringList(IEnumerable<string>? values)
    {
        return values?
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Select(value => value.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList()
            ?? new List<string>();
    }

    private static string NormalizeRequired(string? value, string fieldName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException($"{fieldName} is required.");
        }

        return value.Trim();
    }
}

public class KeeperOfferService : IKeeperOfferService
{
    private readonly AppDbContext _db;
    private readonly IFirestoreService _firestore;
    public KeeperOfferService(AppDbContext db, IFirestoreService firestore) 
    { 
        _db = db; 
        _firestore = firestore; 
    }

    public async Task<List<KeeperOfferDetailDto>> GetMyOffersAsync(Guid keeperId)
    {
        var offers = await _db.Offers
            .AsNoTracking()
            .Include(offer => offer.Shop)
            .Where(offer => offer.KeeperId == keeperId)
            .OrderByDescending(offer => offer.CreatedAt)
            .ToListAsync();

        return offers.Select(MapOfferDetail).ToList();
    }

    public async Task<Guid> CreateOfferAsync(Guid keeperId, CreateOfferDto dto)
    {
        await EnsureKeeperHasAtLeastOneShopAsync(keeperId);
        _ = await EnsureOwnedShopAsync(keeperId, dto.ShopId);

        var offerId = Guid.NewGuid();
        var offer = new Offer
        {
            OfferId = offerId,
            KeeperId = keeperId,
            ShopId = dto.ShopId,
            Title = dto.Title,
            Description = dto.Description,
            DiscountPercentage = dto.DiscountPercentage,
            DiscountAmount = dto.DiscountAmount,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            TermsAndConditions = dto.TermsAndConditions,
            ImageData = ImageConversionHelper.ParseBase64Image(dto.ImageUrl),
            Status = OfferStatus.Active,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _db.Offers.Add(offer);
        await _db.SaveChangesAsync();
        await _firestore.SyncOfferAsync(offer);
        return offerId;
    }

    public async Task<KeeperOfferDetailDto> GetOfferDetailAsync(Guid keeperId, Guid offerId)
    {
        var offer = await _db.Offers
            .AsNoTracking()
            .Include(item => item.Shop)
            .FirstOrDefaultAsync(item => item.OfferId == offerId);

        if (offer == null)
        {
            return null!;
        }

        if (offer.KeeperId != keeperId)
        {
            throw new UnauthorizedAccessException("Cannot access another keeper's offer.");
        }

        return MapOfferDetail(offer);
    }

    public async Task UpdateOfferAsync(Guid keeperId, Guid offerId, CreateOfferDto dto)
    {
        await EnsureKeeperHasAtLeastOneShopAsync(keeperId);
        _ = await EnsureOwnedShopAsync(keeperId, dto.ShopId);

        var offer = await _db.Offers.FindAsync(offerId);
        if (offer == null)
        {
            throw new KeyNotFoundException($"Offer {offerId} not found.");
        }

        if (offer.KeeperId != keeperId)
        {
            throw new UnauthorizedAccessException("Cannot update another keeper's offer.");
        }

        offer.ShopId = dto.ShopId;
        offer.Title = dto.Title;
        offer.Description = dto.Description;
        offer.DiscountPercentage = dto.DiscountPercentage;
        offer.DiscountAmount = dto.DiscountAmount;
        offer.StartDate = dto.StartDate;
        offer.EndDate = dto.EndDate;
        offer.TermsAndConditions = dto.TermsAndConditions;
        offer.ImageData = ImageConversionHelper.ParseBase64Image(dto.ImageUrl);
        offer.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await _firestore.SyncOfferAsync(offer);
    }

    public async Task DeleteOfferAsync(Guid keeperId, Guid offerId)
    {
        var offer = await _db.Offers.FindAsync(offerId);
        if (offer == null)
        {
            throw new KeyNotFoundException($"Offer {offerId} not found.");
        }

        if (offer.KeeperId != keeperId)
        {
            throw new UnauthorizedAccessException("Cannot delete another keeper's offer.");
        }

        _db.Offers.Remove(offer);
        await _db.SaveChangesAsync();
        await _firestore.DeleteOfferAsync(offerId.ToString());
    }

    public async Task<BulkOfferUploadResultDto> BulkUploadOffersAsync(Guid keeperId, Stream csvStream)
    {
        var ownedShopIds = await _db.Shops
            .AsNoTracking()
            .Where(shop => shop.KeeperId == keeperId)
            .Select(shop => shop.ShopId)
            .ToListAsync();

        if (ownedShopIds.Count == 0)
        {
            throw new InvalidOperationException("Create a shop first before creating offers.");
        }

        var ownedShopIdSet = ownedShopIds.ToHashSet();

        var result = new BulkOfferUploadResultDto();
        var offersToSync = new List<Offer>();

        using var reader = new StreamReader(csvStream, leaveOpen: true);
        using var parser = new TextFieldParser(reader)
        {
            TextFieldType = FieldType.Delimited,
            HasFieldsEnclosedInQuotes = true
        };
        parser.SetDelimiters(",");

        if (!parser.EndOfData)
        {
            _ = parser.ReadFields();
        }

        while (!parser.EndOfData)
        {
            string[]? fields;
            try
            {
                fields = parser.ReadFields();
            }
            catch (MalformedLineException ex)
            {
                result.FailedRows.Add(new BulkOfferUploadRowErrorDto
                {
                    RowNumber = (int)parser.ErrorLineNumber,
                    Message = $"Malformed CSV row: {ex.Message}"
                });
                continue;
            }

            var rowNumber = (int)parser.LineNumber;
            if (fields == null || fields.All(string.IsNullOrWhiteSpace))
            {
                continue;
            }

            if (fields.Length < 7)
            {
                result.FailedRows.Add(new BulkOfferUploadRowErrorDto
                {
                    RowNumber = rowNumber,
                    Message = "Expected at least 7 columns: title, description, discountPercentage, discountAmount, startDate, endDate, shopId."
                });
                continue;
            }

            if (!Guid.TryParse(fields[6].Trim(), out var shopId))
            {
                result.FailedRows.Add(new BulkOfferUploadRowErrorDto
                {
                    RowNumber = rowNumber,
                    Message = "shopId must be a valid GUID."
                });
                continue;
            }

            if (!ownedShopIdSet.Contains(shopId))
            {
                result.FailedRows.Add(new BulkOfferUploadRowErrorDto
                {
                    RowNumber = rowNumber,
                    Message = $"Shop {shopId} does not belong to the current keeper."
                });
                continue;
            }

            if (!TryParseDateTime(fields[4], out var startDate))
            {
                result.FailedRows.Add(new BulkOfferUploadRowErrorDto
                {
                    RowNumber = rowNumber,
                    Message = "startDate must be a valid date/time."
                });
                continue;
            }

            if (!TryParseDateTime(fields[5], out var endDate))
            {
                result.FailedRows.Add(new BulkOfferUploadRowErrorDto
                {
                    RowNumber = rowNumber,
                    Message = "endDate must be a valid date/time."
                });
                continue;
            }

            if (endDate <= startDate)
            {
                result.FailedRows.Add(new BulkOfferUploadRowErrorDto
                {
                    RowNumber = rowNumber,
                    Message = "endDate must be after startDate."
                });
                continue;
            }

            var offer = new Offer
            {
                OfferId = Guid.NewGuid(),
                KeeperId = keeperId,
                ShopId = shopId,
                Title = fields[0].Trim(),
                Description = NormalizeOptional(fields.ElementAtOrDefault(1)),
                DiscountPercentage = TryParseDecimal(fields.ElementAtOrDefault(2)),
                DiscountAmount = TryParseDecimal(fields.ElementAtOrDefault(3)),
                StartDate = startDate,
                EndDate = endDate,
                TermsAndConditions = NormalizeOptional(fields.ElementAtOrDefault(7)),
                Status = OfferStatus.Active,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Offers.Add(offer);
            offersToSync.Add(offer);
            result.ImportedCount += 1;
        }

        await _db.SaveChangesAsync();

        foreach (var offer in offersToSync)
        {
            await _firestore.SyncOfferAsync(offer);
        }

        return result;
    }

    private async Task<Shop> EnsureOwnedShopAsync(Guid keeperId, Guid shopId)
    {
        return await _db.Shops
            .AsNoTracking()
            .FirstOrDefaultAsync(shop => shop.ShopId == shopId && shop.KeeperId == keeperId)
            ?? throw new InvalidOperationException($"Shop {shopId} does not belong to the current keeper.");
    }

    private async Task EnsureKeeperHasAtLeastOneShopAsync(Guid keeperId)
    {
        var hasShops = await _db.Shops
            .AsNoTracking()
            .AnyAsync(shop => shop.KeeperId == keeperId);

        if (!hasShops)
        {
            throw new InvalidOperationException("Create a shop first before creating offers.");
        }
    }

    private static KeeperOfferDetailDto MapOfferDetail(Offer offer)
    {
        return new KeeperOfferDetailDto
        {
            OfferId = offer.OfferId,
            ShopId = offer.ShopId,
            ShopName = offer.Shop?.Name ?? "Unknown shop",
            Title = offer.Title,
            Description = offer.Description,
            DiscountPercentage = offer.DiscountPercentage,
            DiscountAmount = offer.DiscountAmount,
            StartDate = offer.StartDate,
            EndDate = offer.EndDate,
            TermsAndConditions = offer.TermsAndConditions,
            ImageUrl = ImageConversionHelper.ToBase64DataUrl(offer.ImageData),
            Status = offer.Status,
            RedemptionCount = offer.CurrentRedemptions,
            CreatedAt = offer.CreatedAt
        };
    }

    private static decimal? TryParseDecimal(string? value)
    {
        return decimal.TryParse(value?.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : null;
    }

    private static bool TryParseDateTime(string? value, out DateTime parsed)
    {
        return DateTime.TryParse(
            value?.Trim(),
            CultureInfo.InvariantCulture,
            DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal,
            out parsed);
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}

public class KeeperDashboardService : IKeeperDashboardService
{
    private readonly AppDbContext _db;
    public KeeperDashboardService(AppDbContext db) => _db = db;

    public async Task<KeeperDashboardDto> GetDashboardAsync(Guid keeperId)
    {
        var now = DateTime.UtcNow;
        var activeOffersCount = await _db.Offers
            .AsNoTracking()
            .CountAsync(offer =>
                offer.KeeperId == keeperId &&
                offer.IsActive &&
                offer.Status == OfferStatus.Active &&
                offer.StartDate <= now &&
                offer.EndDate >= now);

        var totalRedemptions = await _db.Redemptions
            .CountAsync(redemption =>
                redemption.Status == RedemptionStatus.Redeemed &&
                redemption.Offer != null &&
                redemption.Offer.KeeperId == keeperId);

        var totalReviews = await _db.Reviews
            .CountAsync(review => 
                (review.Shop != null && review.Shop.KeeperId == keeperId) || 
                (review.Offer != null && review.Offer.KeeperId == keeperId));

        var totalSalesValue = await _db.Redemptions
            .Where(redemption =>
                redemption.Status == RedemptionStatus.Redeemed &&
                redemption.Offer != null &&
                redemption.Offer.KeeperId == keeperId)
            .SumAsync(redemption => redemption.SavedAmount ?? redemption.Offer!.DiscountAmount ?? 0);

        var rangeStart = DateTime.UtcNow.Date.AddDays(-6);
        var trendDb = await _db.Redemptions
            .Where(redemption =>
                redemption.Status == RedemptionStatus.Redeemed &&
                redemption.Offer != null &&
                redemption.Offer.KeeperId == keeperId &&
                redemption.RedeemedAt >= rangeStart)
            .GroupBy(redemption => redemption.RedeemedAt.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .ToListAsync();

        var trend = Enumerable.Range(0, 7)
            .Select(offset => rangeStart.AddDays(offset))
            .Select(date => new RedemptionTrendDto
            {
                Date = date,
                Count = trendDb.FirstOrDefault(t => t.Date == date)?.Count ?? 0
            })
            .ToList();

        return new KeeperDashboardDto 
        { 
            ActiveOffersCount = activeOffersCount,
            TotalRedemptions = totalRedemptions,
            TotalSalesValue = totalSalesValue,
            TotalReviews = totalReviews,
            RedemptionTrend = trend
        };
    }

    public async Task<KeeperTrafficDto> GetTrafficAnalyticsAsync(Guid keeperId, Guid shopId)
    {
        var shop = await _db.Shops
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.ShopId == shopId && item.KeeperId == keeperId)
            ?? throw new KeyNotFoundException($"Shop {shopId} not found.");
        if (!shop.Latitude.HasValue || !shop.Longitude.HasValue)
        {
            return new KeeperTrafficDto();
        }

        var radiusKm = shop.NotificationRadius.HasValue && shop.NotificationRadius.Value > 0
            ? shop.NotificationRadius.Value
            : 2;
        var oneHourAgo = DateTime.UtcNow.AddHours(-1);

        var lat = shop.Latitude.Value;
        var lng = shop.Longitude.Value;
        var latDelta = radiusKm / 111.0;
        var lngDelta = radiusKm / (111.0 * Math.Cos(lat * Math.PI / 180.0));
        
        var minLat = lat - latDelta;
        var maxLat = lat + latDelta;
        var minLng = lng - lngDelta;
        var maxLng = lng + lngDelta;

        var currentViewers = await _db.Users
            .AsNoTracking()
            .Where(user => user.IsActive &&
                           user.Status == UserStatus.Active &&
                           EF.Functions.ILike(user.Role, "customer") &&
                           user.LastLatitude.HasValue &&
                           user.LastLongitude.HasValue &&
                           user.LastLatitude >= minLat && user.LastLatitude <= maxLat &&
                           user.LastLongitude >= minLng && user.LastLongitude <= maxLng &&
                           user.LastLoginAt.HasValue &&
                           user.LastLoginAt.Value >= oneHourAgo)
            .Select(user => new { user.LastLatitude, user.LastLongitude })
            .ToListAsync();

        var nearbyViewerCount = currentViewers.Count(user =>
            GeoHelper.CalculateDistanceKm(lat, lng, user.LastLatitude!.Value, user.LastLongitude!.Value) <= radiusKm);

        var since = DateTime.UtcNow.AddDays(-14);
        var journeys = await _db.Journeys
            .AsNoTracking()
            .Where(journey => journey.StartTime >= since &&
                              journey.EndTime.HasValue &&
                              journey.Status == "completed" &&
                              journey.User != null &&
                              journey.User.IsActive &&
                              journey.User.Status == UserStatus.Active &&
                              EF.Functions.ILike(journey.User.Role, "customer") &&
                              journey.EndLat.HasValue &&
                              journey.EndLng.HasValue &&
                              journey.EndLat >= minLat && journey.EndLat <= maxLat &&
                              journey.EndLng >= minLng && journey.EndLng <= maxLng)
            .Select(journey => new { journey.StartTime, journey.EndLat, journey.EndLng })
            .ToListAsync();

        var predictedTraffic = journeys
            .Where(journey => GeoHelper.CalculateDistanceKm(lat, lng, journey.EndLat!.Value, journey.EndLng!.Value) <= radiusKm)
            .GroupBy(journey => journey.StartTime.Hour)
            .Select(group => new HourlyTrafficDto
            {
                Hour = group.Key,
                PredictedCount = group.Count()
            })
            .OrderBy(item => item.Hour)
            .ToList();

        return new KeeperTrafficDto
        {
            CurrentViewersNearShop = nearbyViewerCount,
            PredictedTraffic = predictedTraffic
        };
    }

    public async Task<KeeperAnalyticsDto> GetAnalyticsAsync(Guid keeperId)
    {
        var now = DateTime.UtcNow;
        var shopIds = await _db.Shops
            .AsNoTracking()
            .Where(shop => shop.KeeperId == keeperId)
            .OrderByDescending(shop => shop.CreatedAt)
            .Select(shop => new { shop.ShopId, shop.Name, shop.IsActive })
            .ToListAsync();

        var offers = await _db.Offers
            .AsNoTracking()
            .Where(offer => offer.KeeperId == keeperId)
            .Select(offer => new { offer.OfferId, offer.ShopId, offer.Status, offer.IsActive, offer.StartDate, offer.EndDate })
            .ToListAsync();

        var shopAnalytics = new List<KeeperShopAnalyticsDto>();
        var totalSavings = 0m;
        var totalRedemptions = 0;

        var redemptionsByShop = await _db.Redemptions
            .Where(redemption =>
                redemption.Status == RedemptionStatus.Redeemed &&
                redemption.Offer != null &&
                redemption.Offer.KeeperId == keeperId)
            .GroupBy(redemption => redemption.ShopId)
            .Select(g => new { 
                ShopId = g.Key, 
                RedemptionCount = g.Count(), 
                Savings = g.Sum(r => r.SavedAmount ?? r.Offer!.DiscountAmount ?? 0) 
            })
            .ToListAsync();

        foreach (var shop in shopIds)
        {
            var rData = redemptionsByShop.FirstOrDefault(r => r.ShopId == shop.ShopId);
            var sCount = rData?.RedemptionCount ?? 0;
            var sSavings = rData?.Savings ?? 0m;
            shopAnalytics.Add(new KeeperShopAnalyticsDto
            {
                ShopId = shop.ShopId,
                ShopName = shop.Name,
                OfferCount = offers.Count(o => o.ShopId == shop.ShopId),
                RedemptionCount = sCount,
                Savings = sSavings
            });
            totalRedemptions += sCount;
            totalSavings += sSavings;
        }

        var rangeStart = DateTime.UtcNow.Date.AddDays(-29);
        var trendDb = await _db.Redemptions
            .Where(redemption =>
                redemption.Status == RedemptionStatus.Redeemed &&
                redemption.Offer != null &&
                redemption.Offer.KeeperId == keeperId &&
                redemption.RedeemedAt >= rangeStart)
            .GroupBy(redemption => redemption.RedeemedAt.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .ToListAsync();

        var trend = Enumerable.Range(0, 30)
            .Select(offset => rangeStart.AddDays(offset))
            .Select(date => new RedemptionTrendDto
            {
                Date = date,
                Count = trendDb.FirstOrDefault(t => t.Date == date)?.Count ?? 0
            })
            .ToList();

        return new KeeperAnalyticsDto
        {
            TotalShops = shopIds.Count,
            ActiveShops = shopIds.Count(item => item.IsActive),
            TotalOffers = offers.Count,
            ActiveOffers = offers.Count(item => item.IsActive && item.Status == OfferStatus.Active && item.StartDate <= now && item.EndDate >= now),
            TotalRedemptions = totalRedemptions,
            TotalSavings = totalSavings,
            RedemptionTrend = trend,
            Shops = shopAnalytics
        };
    }
}
