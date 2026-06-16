namespace routent.AdminAPI.Constants;

public static class ErrorCodes
{
    public const string ValidationError = "VALIDATION_ERROR";
    public const string Unauthorized = "UNAUTHORIZED";
    public const string TokenExpired = "TOKEN_EXPIRED";
    public const string InsufficientPermissions = "INSUFFICIENT_PERMISSIONS";
    public const string ResourceNotFound = "RESOURCE_NOT_FOUND";
    public const string DuplicateEntity = "DUPLICATE_ENTITY";
    public const string UnprocessableEntity = "UNPROCESSABLE_ENTITY";
    public const string RateLimitExceeded = "RATE_LIMIT_EXCEEDED";
    public const string InternalServerError = "INTERNAL_SERVER_ERROR";
    public const string ServiceUnavailable = "SERVICE_UNAVAILABLE";
}
