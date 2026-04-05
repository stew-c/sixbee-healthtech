using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using SixBee.Core;

namespace SixBee.Auth.Tests;

public class AuthServiceTests
{
    private readonly IAccountRepository _accountRepository;
    private readonly AuthService _authService;
    private readonly Account _testAccount;

    private static readonly JwtOptions TestJwtOptions = new()
    {
        Secret = "this-is-a-test-secret-key-that-is-long-enough",
        Issuer = "test-issuer",
        Audience = "test-audience",
        ExpiryInMinutes = 60
    };

    public AuthServiceTests()
    {
        _accountRepository = Substitute.For<IAccountRepository>();
        _authService = new AuthService(_accountRepository, TestJwtOptions);

        _testAccount = new Account
        {
            Id = Guid.NewGuid(),
            Email = "admin@sixbee.co.uk",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("password123"),
            CreatedAt = DateTimeOffset.UtcNow
        };

        _accountRepository.GetByEmail("admin@sixbee.co.uk").Returns(_testAccount);
        _accountRepository.GetByEmail(Arg.Is<string>(e => e != "admin@sixbee.co.uk")).Returns((Account?)null);
    }

    [Fact]
    public async Task Login_WithEmptyEmail_ThrowsValidationException()
    {
        var ex = await Assert.ThrowsAsync<ValidationException>(() => _authService.Login("", "password123"));
        Assert.Contains(ex.Errors, e => e.Field == "Email");
    }

    [Fact]
    public async Task Login_WithEmptyPassword_ThrowsValidationException()
    {
        var ex = await Assert.ThrowsAsync<ValidationException>(() => _authService.Login("admin@sixbee.co.uk", ""));
        Assert.Contains(ex.Errors, e => e.Field == "Password");
    }

    [Fact]
    public async Task Login_WithValidCredentials_ReturnsSuccessWithToken()
    {
        var result = await _authService.Login("admin@sixbee.co.uk", "password123");

        Assert.True(result.Success);
        Assert.False(string.IsNullOrEmpty(result.Token));
        Assert.True(result.ExpiresAt > DateTimeOffset.UtcNow);
    }

    [Fact]
    public async Task Login_WithNonExistentEmail_ReturnsFailure()
    {
        var result = await _authService.Login("nobody@example.com", "password123");

        Assert.False(result.Success);
        Assert.Equal("Invalid credentials", result.Error);
    }

    [Fact]
    public async Task Login_WithWrongPassword_ReturnsFailure()
    {
        var result = await _authService.Login("admin@sixbee.co.uk", "wrongpassword");

        Assert.False(result.Success);
        Assert.Equal("Invalid credentials", result.Error);
    }

    [Fact]
    public async Task Login_WithWrongPassword_ReturnsSameErrorAsNonExistentEmail()
    {
        var wrongPassword = await _authService.Login("admin@sixbee.co.uk", "wrongpassword");
        var nonExistent = await _authService.Login("nobody@example.com", "password123");

        Assert.Equal(wrongPassword.Error, nonExistent.Error);
    }

    [Fact]
    public async Task Login_WithValidCredentials_TokenContainsExpectedClaims()
    {
        var result = await _authService.Login("admin@sixbee.co.uk", "password123");

        var handler = new JsonWebTokenHandler();
        var jwt = handler.ReadJsonWebToken(result.Token);

        Assert.Equal(_testAccount.Id.ToString(), jwt.GetClaim(JwtRegisteredClaimNames.Sub).Value);
        Assert.Equal(_testAccount.Email, jwt.GetClaim(JwtRegisteredClaimNames.Email).Value);
    }

    [Fact]
    public async Task Login_WithValidCredentials_TokenHasCorrectIssuerAndAudience()
    {
        var result = await _authService.Login("admin@sixbee.co.uk", "password123");

        var handler = new JsonWebTokenHandler();
        var jwt = handler.ReadJsonWebToken(result.Token);

        Assert.Equal(TestJwtOptions.Issuer, jwt.Issuer);
        Assert.Contains(TestJwtOptions.Audience, jwt.Audiences);
    }
}
