using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Models.Enums;
using allonbiz.AdminAPI.Constants;

namespace allonbiz.AdminAPI.Data;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(AppDbContext context)
    {
        // Don't run seeder if data exists
        if (await context.Categories.AnyAsync())
        {
            return;
        }

        // 1. Categories
        var foodCategory = new Category { CategoryId = Guid.NewGuid(), Name = "Food & Drink", DisplayOrder = 1, IsActive = true };
        var retailCategory = new Category { CategoryId = Guid.NewGuid(), Name = "Retail", DisplayOrder = 2, IsActive = true };
        var servicesCategory = new Category { CategoryId = Guid.NewGuid(), Name = "Services", DisplayOrder = 3, IsActive = true };
        
        context.Categories.AddRange(foodCategory, retailCategory, servicesCategory);

        // 3. Keepers (Business Owners)
        // Note: No demo users or keepers created here anymore. 
        // Use management tools to create initial data.
        // Commit all changes
        await context.SaveChangesAsync();
    }
}
