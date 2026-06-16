using Google.Cloud.Firestore;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.Services.Interfaces;

namespace routent.AdminAPI.Services;

public class NoOpFirestoreService : IFirestoreService
{
    public Task SyncCategoryAsync(Category category, CancellationToken ct = default) => Task.CompletedTask;
    public Task DeleteCategoryAsync(string categoryId, CancellationToken ct = default) => Task.CompletedTask;
    public Task<int> SyncAllCategoriesAsync(IEnumerable<Category> categories, CancellationToken ct = default) => Task.FromResult(0);
    public Task SyncOfferAsync(Offer offer, CancellationToken ct = default) => Task.CompletedTask;
    public Task DeleteOfferAsync(string offerId, CancellationToken ct = default) => Task.CompletedTask;
    public Task SyncJourneyAsync(Journey journey, CancellationToken ct = default) => Task.CompletedTask;
}

public class FirestoreService : IFirestoreService
{
    private readonly ILogger<FirestoreService> _logger;
    private readonly FirestoreDb _db;

    public FirestoreService(ILogger<FirestoreService> logger, IConfiguration config)
    {
        _logger = logger;
        _db = FirestoreDb.Create(config["Firebase:ProjectId"] ?? "locator-43add");
    }

    public async Task SyncCategoryAsync(Category category, CancellationToken ct = default)
    {
        var docRef = _db.Collection("categories").Document(category.CategoryId.ToString());
        await docRef.SetAsync(new
        {
            id = category.CategoryId,
            name = category.Name,
            icon = category.Icon,
            color = category.Color,
            parentId = category.ParentCategoryId,
            updatedAt = Timestamp.FromDateTime(category.UpdatedAt.ToUniversalTime())
        }, cancellationToken: ct);
    }

    public async Task DeleteCategoryAsync(string categoryId, CancellationToken ct = default) =>
        await _db.Collection("categories").Document(categoryId).DeleteAsync(cancellationToken: ct);

    public async Task<int> SyncAllCategoriesAsync(IEnumerable<Category> categories, CancellationToken ct = default)
    {
        var batch = _db.StartBatch();
        foreach (var cat in categories)
        {
            var docRef = _db.Collection("categories").Document(cat.CategoryId.ToString());
            batch.Set(docRef, new { id = cat.CategoryId, name = cat.Name });
        }
        await batch.CommitAsync(cancellationToken: ct);
        return categories.Count();
    }

    public async Task SyncOfferAsync(Offer offer, CancellationToken ct = default)
    {
        var docRef = _db.Collection("offers").Document(offer.OfferId.ToString());
        await docRef.SetAsync(new
        {
            id = offer.OfferId,
            title = offer.Title,
            shopId = offer.ShopId,
            keeperId = offer.KeeperId,
            status = offer.Status.ToString(),
            startDate = Timestamp.FromDateTime(offer.StartDate.ToUniversalTime()),
            endDate = Timestamp.FromDateTime(offer.EndDate.ToUniversalTime()),
            description = offer.Description,
            updatedAt = Timestamp.FromDateTime(offer.UpdatedAt.ToUniversalTime())
        }, cancellationToken: ct);
    }

    public async Task DeleteOfferAsync(string offerId, CancellationToken ct = default) =>
        await _db.Collection("offers").Document(offerId).DeleteAsync(cancellationToken: ct);

    public async Task SyncJourneyAsync(Journey journey, CancellationToken ct = default)
    {
        var docRef = _db.Collection("journeys").Document(journey.JourneyId.ToString());
        await docRef.SetAsync(new
        {
            id = journey.JourneyId,
            userId = journey.UserId,
            status = journey.Status,
            startName = journey.StartName,
            endName = journey.EndName,
            updatedAt = Timestamp.FromDateTime(DateTime.UtcNow)
        }, cancellationToken: ct);
    }
}
