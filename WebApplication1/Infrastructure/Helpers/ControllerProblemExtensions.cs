using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace routent.AdminAPI.Helpers;

public static class ControllerProblemExtensions
{
    public static ObjectResult ValidationProblemResponse(
        this ControllerBase controller,
        string detail,
        string key = "request",
        string title = "Request validation failed.")
    {
        var modelState = new ModelStateDictionary();
        modelState.AddModelError(key, detail);

        var factory = controller.HttpContext.RequestServices.GetRequiredService<ProblemDetailsFactory>();
        var problem = factory.CreateValidationProblemDetails(
            controller.HttpContext,
            modelState,
            statusCode: StatusCodes.Status400BadRequest,
            title: title,
            detail: detail);

        return new BadRequestObjectResult(problem)
        {
            ContentTypes = { "application/problem+json" }
        };
    }
    public static ObjectResult BadRequestProblemResponse(
        this ControllerBase controller,
        string detail,
        string title = "Bad Request")
    {
        return CreateProblemResult(controller.HttpContext, StatusCodes.Status400BadRequest, title, detail);
    }

    public static ObjectResult NotFoundProblemResponse(
        this ControllerBase controller,
        string detail,
        string title = "Resource not found.")
    {
        return CreateProblemResult(controller.HttpContext, StatusCodes.Status404NotFound, title, detail);
    }

    public static ObjectResult UnauthorizedProblemResponse(
        this ControllerBase controller,
        string detail,
        string title = "Unauthorized")
    {
        return CreateProblemResult(controller.HttpContext, StatusCodes.Status401Unauthorized, title, detail);
    }

    public static ObjectResult ForbiddenProblemResponse(
        this ControllerBase controller,
        string detail = "You do not have permission to access this resource.",
        string title = "Forbidden")
    {
        return CreateProblemResult(controller.HttpContext, StatusCodes.Status403Forbidden, title, detail);
    }

    public static ObjectResult CreateProblemResult(
        HttpContext httpContext,
        int statusCode,
        string title,
        string detail)
    {
        var factory = httpContext.RequestServices.GetRequiredService<ProblemDetailsFactory>();
        var problem = factory.CreateProblemDetails(
            httpContext,
            statusCode: statusCode,
            title: title,
            detail: detail);

        return new ObjectResult(problem)
        {
            StatusCode = statusCode,
            ContentTypes = { "application/problem+json" }
        };
    }
}
