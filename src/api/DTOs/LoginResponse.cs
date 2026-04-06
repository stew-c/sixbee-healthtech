namespace SixBee.Api.DTOs;

public record LoginResponse(string Token, DateTimeOffset ExpiresAt);
