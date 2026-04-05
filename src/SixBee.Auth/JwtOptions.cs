namespace SixBee.Auth;

public class JwtOptions
{
    public string Secret { get; set; } = "";
    public string Issuer { get; set; } = "";
    public string Audience { get; set; } = "";
    public int ExpiryInMinutes { get; set; } = 120;
}
