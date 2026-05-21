using AspNetCoreRateLimit;
using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using allonbiz.AdminAPI.Data;
using allonbiz.AdminAPI.Mappings;
using allonbiz.AdminAPI.Middleware;
using allonbiz.AdminAPI.Services;
using allonbiz.AdminAPI.Services.Interfaces;
using allonbiz.AdminAPI.Validators;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.Constants;
using allonbiz.AdminAPI.Helpers;
using allonbiz.AdminAPI.Data.Interfaces;
using allonbiz.AdminAPI.Data.Repositories;
using AutoMapper;
using Serilog;
using System.Text;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);
var isDevelopment = builder.Environment.IsDevelopment();
var defaultConnectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");
var redisConnectionString = builder.Configuration.GetConnectionString("Redis");

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("logs/allonbizs-admin-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();
builder.Host.UseSerilog();

builder.Services.AddProblemDetails();

builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(defaultConnectionString, npgsqlOptions =>
        npgsqlOptions.EnableRetryOnFailure(5, TimeSpan.FromSeconds(10), null));
});

var jwtSecret = builder.Configuration["JwtSettings:SecretKey"]
    ?? throw new InvalidOperationException("JwtSettings:SecretKey is not configured.");

if (jwtSecret.Length < 32 || IsPlaceholderSecret(jwtSecret))
{
    throw new InvalidOperationException("JwtSettings:SecretKey must be a real secret and at least 32 characters long.");
}

Microsoft.IdentityModel.Logging.IdentityModelEventSource.ShowPII = isDevelopment;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = !isDevelopment;
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["JwtSettings:Issuer"],
            ValidAudience = builder.Configuration["JwtSettings:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
});

var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("Development", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod());

    options.AddPolicy("Production", policy =>
        policy.WithOrigins(corsOrigins)
              .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE")
              .WithHeaders("Authorization", "Content-Type")
              .SetPreflightMaxAge(TimeSpan.FromMinutes(10)));
});

var healthChecks = builder.Services.AddHealthChecks()
    .AddNpgSql(defaultConnectionString);

if (!isDevelopment && !string.IsNullOrWhiteSpace(redisConnectionString) && !IsPlaceholderRedisConnection(redisConnectionString))
{
    healthChecks.AddRedis(redisConnectionString);
}
builder.Services.AddAutoMapper(cfg => cfg.AddMaps(typeof(Program).Assembly));
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<LoginRequestValidator>();
builder.Services.AddMemoryCache();
builder.Services.AddOptions();

builder.Services.Configure<IpRateLimitOptions>(builder.Configuration.GetSection("RateLimiting"));
builder.Services.AddInMemoryRateLimiting();
builder.Services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var problemDetails = new ValidationProblemDetails(context.ModelState)
        {
            Status = StatusCodes.Status400BadRequest,
            Title = "Request validation failed.",
            Instance = context.HttpContext.Request.Path
        };
        problemDetails.Extensions["traceId"] = context.HttpContext.TraceIdentifier;

        return new BadRequestObjectResult(problemDetails)
        {
            ContentTypes = { "application/problem+json" }
        };
    };
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "allonbiz Admin API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAdminAuthService, AdminAuthService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IJourneyService, JourneyService>();
builder.Services.AddScoped<IAuditService, AuditService>();

builder.Services.AddScoped<IReviewService, PlatformFeatureService>();
builder.Services.AddScoped<ILoyaltyService, PlatformFeatureService>();
builder.Services.AddScoped<IAdminPanelService, PlatformFeatureService>();
builder.Services.AddScoped<IRuleService, PlatformFeatureService>();
builder.Services.AddScoped<IPlacesService, PlatformFeatureService>();

builder.Services.AddScoped<IKeeperService, KeeperService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IShopService, ShopService>();
builder.Services.AddScoped<ITagService, TagService>();
builder.Services.AddScoped<IModerationService, ModerationService>();
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
builder.Services.AddScoped<ISettingsService, SettingsService>();
builder.Services.AddScoped<ISystemService, SystemService>();

if (builder.Environment.IsDevelopment())
{
    builder.Services.AddScoped<IFirestoreService, NoOpFirestoreService>();
}
else
{
    builder.Services.AddScoped<IFirestoreService, FirestoreService>();
}
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IAdminOfferService, AdminOfferService>();
builder.Services.AddScoped<IAdminReviewService, AdminReviewService>();
builder.Services.AddScoped<IAdminJourneyService, AdminJourneyService>();


builder.Services.AddScoped<IUserProfileService, UserProfileService>();
builder.Services.AddScoped<IRouteService, RouteService>();
builder.Services.AddScoped<IOfferService, UserOfferService>();
builder.Services.AddScoped<IUserHistoryService, UserHistoryService>();
builder.Services.AddScoped<IFavouriteService, FavouriteService>();
builder.Services.AddScoped<IChatService, ChatService>();

builder.Services.AddScoped<IKeeperProfileService, KeeperProfileService>();
builder.Services.AddScoped<IKeeperOfferService, KeeperOfferService>();
builder.Services.AddScoped<IKeeperDashboardService, KeeperDashboardService>();
builder.Services.AddScoped<IKeeperContextService, KeeperContextService>();

var app = builder.Build();

try
{
    using (var repairScope = app.Services.CreateScope())
    {
        var context = repairScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var logger = repairScope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        await DatabaseMigrationBootstrapper.RepairMigrationHistoryIfNeededAsync(context, logger, app.Lifetime.ApplicationStopping);
    }

    try
    {
        using (var migrationScope = app.Services.CreateScope())
        {
            var context = migrationScope.ServiceProvider.GetRequiredService<AppDbContext>();
            await context.Database.MigrateAsync(app.Lifetime.ApplicationStopping);
        }
    }
    catch (Exception ex)
    {
        using var loggerScope = app.Services.CreateScope();
        var logger = loggerScope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        logger.LogWarning(ex, "Database migration skipped or failed");
    }

    try
    {
        using (var repairScope = app.Services.CreateScope())
        {
            var context = repairScope.ServiceProvider.GetRequiredService<AppDbContext>();
            var logger = repairScope.ServiceProvider.GetRequiredService<ILogger<Program>>();
            await DatabaseMigrationBootstrapper.RepairLegacyRuntimeDataAsync(context, logger, app.Lifetime.ApplicationStopping);
        }
    }
    catch (Exception ex)
    {
        using var loggerScope = app.Services.CreateScope();
        var logger = loggerScope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Database legacy runtime data repair failed");
    }
}
catch (Exception ex)
{
    using var loggerScope = app.Services.CreateScope();
    var logger = loggerScope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    logger.LogCritical(ex, "Database bootstrapping failed");
}

app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "allonbiz Admin API v1"));
}
else
{
    app.UseHsts();
}

app.UseHttpsRedirection();

var uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "uploads");
if (!Directory.Exists(uploadsPath))
{
    Directory.CreateDirectory(uploadsPath);
}
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads"
});

app.UseRouting();
app.UseMiddleware<RequestLoggingMiddleware>();
app.UseCors(app.Environment.IsDevelopment() ? "Development" : "Production");
app.UseIpRateLimiting();
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<AuditLoggingMiddleware>();

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();

static bool IsPlaceholderSecret(string value)
{
    var normalized = value.Trim();
    return normalized.Contains("REPLACE_WITH", StringComparison.OrdinalIgnoreCase)
        || normalized.Contains("YOUR_", StringComparison.OrdinalIgnoreCase)
        || normalized.Contains("CHANGE_ME", StringComparison.OrdinalIgnoreCase)
        || normalized.Contains("CHANGE-THIS", StringComparison.OrdinalIgnoreCase)
        || normalized.Contains("PLACEHOLDER", StringComparison.OrdinalIgnoreCase);
}

static bool IsPlaceholderRedisConnection(string value)
{
    var normalized = value.Trim();
    return normalized.Contains("REDIS_HOST", StringComparison.OrdinalIgnoreCase)
        || normalized.Contains("PLACEHOLDER", StringComparison.OrdinalIgnoreCase)
        || normalized.Contains("CHANGE_ME", StringComparison.OrdinalIgnoreCase)
        || normalized.Contains("CHANGE-THIS", StringComparison.OrdinalIgnoreCase);
}

public partial class Program { }
