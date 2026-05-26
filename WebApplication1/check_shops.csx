
using System;
using System.IO;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using allonbiz.AdminAPI.Data;

var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
optionsBuilder.UseNpgsql("Host=localhost;Database=allonbiz;Username=postgres;Password=postgres");
using var db = new AppDbContext(optionsBuilder.Options);

var shops = db.Shops.ToList();
foreach(var shop in shops) {
    Console.WriteLine($"ShopId: {shop.ShopId}, Name: {shop.Name}, Cover: {shop.ImageUrl != null}, GalleryCount: {shop.ShopImages?.Count ?? 0}");
}

