namespace allonbiz.AdminAPI.Middleware;

public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var startedAt = DateTime.UtcNow;
        var traceId = context.TraceIdentifier;

        _logger.LogInformation(
            "HTTP {Method} {Path} started at {StartedAt} (TraceId: {TraceId})",
            context.Request.Method,
            context.Request.Path,
            startedAt,
            traceId);

        await _next(context);

        var elapsedMilliseconds = (DateTime.UtcNow - startedAt).TotalMilliseconds;
        _logger.LogInformation(
            "HTTP {Method} {Path} responded {StatusCode} in {ElapsedMilliseconds:0.0000} ms (TraceId: {TraceId})",
            context.Request.Method,
            context.Request.Path,
            context.Response.StatusCode,
            elapsedMilliseconds,
            traceId);
    }
}
