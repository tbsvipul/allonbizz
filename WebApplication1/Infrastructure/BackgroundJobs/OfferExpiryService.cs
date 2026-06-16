using routent.AdminAPI.Data;
using routent.AdminAPI.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace routent.AdminAPI.Infrastructure.BackgroundJobs;

public class OfferExpiryService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<OfferExpiryService> _logger;

    public OfferExpiryService(IServiceProvider serviceProvider, ILogger<OfferExpiryService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("OfferExpiryService started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var now = DateTime.UtcNow;

                var expiredOffers = await dbContext.Offers
                    .Where(o => o.Status == OfferStatus.Active && o.EndDate < now)
                    .ToListAsync(stoppingToken);

                if (expiredOffers.Any())
                {
                    foreach (var offer in expiredOffers)
                    {
                        offer.Status = OfferStatus.Expired;
                        offer.IsActive = false;
                        offer.UpdatedAt = now;
                    }

                    await dbContext.SaveChangesAsync(stoppingToken);
                    _logger.LogInformation($"Updated {expiredOffers.Count} expired offers to Expired status.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while executing OfferExpiryService.");
            }

            // Check every 10 minutes
            await Task.Delay(TimeSpan.FromMinutes(10), stoppingToken);
        }
    }
}
