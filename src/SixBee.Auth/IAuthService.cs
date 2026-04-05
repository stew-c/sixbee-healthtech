namespace SixBee.Auth;

public interface IAuthService
{
    Task<AuthResult> Login(string email, string password);
}
