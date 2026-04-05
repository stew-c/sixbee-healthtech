namespace SixBee.Auth.Data.Tests;

[Collection("Database")]
public class AccountRepositoryTests
{
    private readonly AccountRepository _repo;

    public AccountRepositoryTests(DatabaseFixture fixture)
    {
        _repo = new AccountRepository(fixture.ConnectionString);
    }

    [Fact]
    public async Task GetByEmail_ExistingAccount_ReturnsAccount()
    {
        var result = await _repo.GetByEmail("admin@sixbee.co.uk");

        Assert.NotNull(result);
        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal("admin@sixbee.co.uk", result.Email);
        Assert.False(string.IsNullOrEmpty(result.PasswordHash));
        Assert.NotEqual(default, result.CreatedAt);
    }

    [Fact]
    public async Task GetByEmail_NonExistentEmail_ReturnsNull()
    {
        var result = await _repo.GetByEmail("nobody@example.com");

        Assert.Null(result);
    }

    [Fact]
    public async Task GetByEmail_IsCaseSensitive()
    {
        var result = await _repo.GetByEmail("Admin@SixBee.co.uk");

        Assert.Null(result);
    }
}
