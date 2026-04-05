namespace SixBee.Auth;

public record AuthResult(bool Success, string? Token = null, DateTimeOffset? ExpiresAt = null, string? Error = null);
