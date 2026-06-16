using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace routent.AdminAPI.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IHostEnvironment _environment;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger,
        IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            var traceId = Activity.Current?.Id ?? context.TraceIdentifier;
            
            if (ex is UnauthorizedAccessException || ex is KeyNotFoundException || ex is ArgumentException || ex is InvalidOperationException || ex is NotSupportedException)
            {
                _logger.LogWarning("Business exception (TraceId: {TraceId}): {Message}", traceId, ex.Message);
            }
            else
            {
                _logger.LogError(ex, "Unhandled exception (TraceId: {TraceId}): {Message}", traceId, ex.Message);
            }

            if (context.Response.HasStarted)
            {
                _logger.LogWarning("Response already started; skipping exception body rewrite.");
                return;
            }

            await HandleExceptionAsync(context, ex, traceId, _environment.IsDevelopment());
        }
    }

    private static async Task HandleExceptionAsync(
        HttpContext context,
        Exception exception,
        string traceId,
        bool includeExceptionDetails)
    {
        context.Response.ContentType = "application/problem+json";
        context.Response.Headers["X-Trace-Id"] = traceId;

        var (statusCode, title, detail) = exception switch
        {
            KeyNotFoundException => (HttpStatusCode.NotFound, "Resource Not Found", exception.Message),
            UnauthorizedAccessException => (HttpStatusCode.Unauthorized, "Unauthorized Access", exception.Message),
            InvalidOperationException => (HttpStatusCode.UnprocessableEntity, "Business Rule Violation", exception.Message),
            ArgumentException => (HttpStatusCode.BadRequest, "Validation Error", exception.Message),
            NotSupportedException => (HttpStatusCode.NotImplemented, "Feature Not Available", exception.Message),
            _ => (
                HttpStatusCode.InternalServerError,
                "Internal Server Error",
                includeExceptionDetails
                    ? exception.Message
                    : "An unexpected error occurred. Please use the trace ID to contact support.")
        };

        context.Response.StatusCode = (int)statusCode;

        var problemDetails = new ProblemDetails
        {
            Status = (int)statusCode,
            Title = title,
            Detail = detail,
            Instance = context.Request.Path,
            Type = $"https://httpstatuses.com/{(int)statusCode}",
            Extensions = { ["traceId"] = traceId }
        };

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        await context.Response.WriteAsync(JsonSerializer.Serialize(problemDetails, options));
    }
}
