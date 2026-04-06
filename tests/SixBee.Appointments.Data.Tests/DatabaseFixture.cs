using Npgsql;
using SixBee.Migrations;

namespace SixBee.Appointments.Data.Tests;

public class DatabaseFixture : IAsyncLifetime
{
    public string ConnectionString { get; private set; } = null!;

    public Task InitializeAsync()
    {
        ConnectionString = Environment.GetEnvironmentVariable("TEST_DB_CONNECTION_STRING")
            ?? "Host=localhost;Port=5432;Database=sixbee_test;Username=sixbee;Password=sixbee";

        DbMigrator.Run(ConnectionString);
        return Task.CompletedTask;
    }

    public async Task DisposeAsync()
    {
        await using var connection = new NpgsqlConnection(ConnectionString);
        await connection.OpenAsync();
        await using var cmd = new NpgsqlCommand("DELETE FROM appointment", connection);
        await cmd.ExecuteNonQueryAsync();
    }
}

[CollectionDefinition("Database")]
public class DatabaseCollection : ICollectionFixture<DatabaseFixture>;
