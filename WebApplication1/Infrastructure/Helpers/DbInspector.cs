using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Models.Entities;

namespace allonbiz.AdminAPI.Helpers
{
    public static class DbInspector
    {
        public static async Task InspectAsync(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            
            Console.WriteLine("--- Database Inspection ---");
            try 
            {
                var shopCount = await context.Shops.CountAsync();
                var keeperCount = await context.Keepers.CountAsync();
                var categoryCount = await context.Categories.CountAsync();
                var userCount = await context.Users.CountAsync();

                Console.WriteLine($"Shops: {shopCount}");
                Console.WriteLine($"Keepers: {keeperCount}");
                Console.WriteLine($"Categories: {categoryCount}");
                Console.WriteLine($"Users: {userCount}");

                if (shopCount > 0)
                {
                    var firstShop = await context.Shops.Include(s => s.Keeper).FirstOrDefaultAsync();
                    Console.WriteLine($"First Shop: {firstShop?.Name} (ID: {firstShop?.ShopId})");
                    Console.WriteLine($"  Has Keeper: {firstShop?.Keeper != null}");
                    Console.WriteLine($"  ImageUrl: {firstShop?.ImageUrl}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                if (ex.InnerException != null) Console.WriteLine($"Inner: {ex.InnerException.Message}");
            }
            Console.WriteLine("---------------------------");
        }
    }
}
