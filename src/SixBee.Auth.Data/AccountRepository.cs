using Npgsql;
using SixBee.Auth;
using SqlKata.Compilers;
using SqlKata.Execution;

namespace SixBee.Auth.Data;

public class AccountRepository : IAccountRepository
{
    private readonly string _connectionString;

    public AccountRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private QueryFactory CreateQueryFactory()
    {
        var connection = new NpgsqlConnection(_connectionString);
        return new QueryFactory(connection, new PostgresCompiler());
    }

    public async Task<Account?> GetByEmail(string email)
    {
        using var db = CreateQueryFactory();
        return await db.Query("account").Where("Email", email).FirstOrDefaultAsync<Account>();
    }
}
