using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using SixBee.Core;

namespace SixBee.Auth;

public class AuthService : IAuthService
{
    private readonly IAccountRepository _accountRepository;
    private readonly JwtOptions _jwtOptions;

    public AuthService(IAccountRepository accountRepository, JwtOptions jwtOptions)
    {
        _accountRepository = accountRepository;
        _jwtOptions = jwtOptions;
    }

    public async Task<AuthResult> Login(string email, string password)
    {
        var errors = new List<ValidationError>();
        if (string.IsNullOrWhiteSpace(email))
            errors.Add(new ValidationError("Email", "Email is required"));
        if (string.IsNullOrWhiteSpace(password))
            errors.Add(new ValidationError("Password", "Password is required"));
        if (errors.Count > 0)
            throw new ValidationException(errors);

        var account = await _accountRepository.GetByEmail(email);
        if (account is null)
            return new AuthResult(false, Error: "Invalid credentials");

        if (!BCrypt.Net.BCrypt.Verify(password, account.PasswordHash))
            return new AuthResult(false, Error: "Invalid credentials");

        var (token, expiresAt) = GenerateToken(account);
        return new AuthResult(true, Token: token, ExpiresAt: expiresAt);
    }

    private (string Token, DateTimeOffset ExpiresAt) GenerateToken(Account account)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtOptions.Secret));
        var expires = DateTime.UtcNow.AddMinutes(_jwtOptions.ExpiryInMinutes);

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, account.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, account.Email)
            }),
            Expires = expires,
            Issuer = _jwtOptions.Issuer,
            Audience = _jwtOptions.Audience,
            SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256Signature)
        };

        var token = new JsonWebTokenHandler().CreateToken(descriptor);
        return (token, new DateTimeOffset(expires, TimeSpan.Zero));
    }
}
