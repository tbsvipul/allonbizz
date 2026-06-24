#r "bin/Debug/net8.0/routent.AdminAPI.dll"
#r "nuget: Microsoft.EntityFrameworkCore, 8.0.0"
#r "nuget: Npgsql.EntityFrameworkCore.PostgreSQL, 8.0.0"

using System;
using System.IO;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using routent.AdminAPI.Data;

var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
optionsBuilder.UseNpgsql("Host=localhost;Port=5432;Database=navideals_dev;Username=postgres;Password=admin;");
using (var db = new AppDbContext(optionsBuilder.Options))
{
    var shops = db.Shops.ToList();
    Console.WriteLine($"Total shops: {shops.Count}");
    foreach(var shop in shops.Take(5)) {
        Console.WriteLine($"ShopId: {shop.ShopId}, Name: {shop.Name}");
    }
}
