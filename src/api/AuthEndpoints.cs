using SixBee.Api.DTOs;
using SixBee.Auth;

namespace SixBee.Api;

public static class AuthEndpoints
{
    public static WebApplication MapAuthEndpoints(this WebApplication app)
    {
        app.MapPost("/api/auth/login", async (LoginRequest request, IAuthService authService) =>
        {
            var result = await authService.Login(request.Email, request.Password);

            if (result.Success)
                return Results.Ok(new LoginResponse(result.Token!, result.ExpiresAt!.Value));

            return Results.Json(new { error = result.Error }, statusCode: 401);
        }).AllowAnonymous();

        return app;
    }
}
