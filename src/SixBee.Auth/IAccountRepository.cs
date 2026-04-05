namespace SixBee.Auth;

public interface IAccountRepository
{
    Task<Account?> GetByEmail(string email);
}
