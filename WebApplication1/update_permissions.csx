using System;
using System.IO;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Data;

var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
// Using connection string from typical local setup
optionsBuilder.UseNpgsql("Host=localhost;Database=navideals_dev;Username=postgres;Password=postgres");
using var db = new AppDbContext(optionsBuilder.Options);

var admins = db.AdminAccounts.Where(a => a.Role == "admin").ToList();
int updated = 0;
foreach(var admin in admins) {
    if (admin.Permissions != null && admin.Permissions.Contains("Admins.Manage")) {
        admin.Permissions.Remove("Admins.Manage");
        updated++;
    }
}
db.SaveChanges();
Console.WriteLine($"Updated {updated} admin accounts.");
