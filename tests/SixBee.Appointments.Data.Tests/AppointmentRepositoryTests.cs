using Npgsql;

namespace SixBee.Appointments.Data.Tests;

[Collection("Database")]
public class AppointmentRepositoryTests : IAsyncLifetime
{
    private readonly DatabaseFixture _fixture;
    private AppointmentRepository _repo = null!;

    public AppointmentRepositoryTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    public Task InitializeAsync()
    {
        _repo = new AppointmentRepository(_fixture.ConnectionString);
        return Task.CompletedTask;
    }

    public async Task DisposeAsync()
    {
        await using var connection = new NpgsqlConnection(_fixture.ConnectionString);
        await connection.OpenAsync();
        await using var cmd = new NpgsqlCommand("DELETE FROM appointment", connection);
        await cmd.ExecuteNonQueryAsync();
    }

    private static Appointment MakeAppointment(DateTimeOffset? dateTime = null) => new()
    {
        Name = "Test Patient",
        DateTime = dateTime ?? DateTimeOffset.UtcNow.AddDays(1),
        Description = "Test appointment",
        ContactNumber = "07700900000",
        Email = "test@example.com"
    };

    [Fact]
    public async Task Create_ReturnsEntityWithGeneratedFields()
    {
        var input = MakeAppointment();

        var result = await _repo.Create(input);

        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal("pending", result.Status);
        Assert.NotEqual(default, result.CreatedAt);
        Assert.NotEqual(default, result.UpdatedAt);
        Assert.Equal(input.Name, result.Name);
        Assert.Equal(input.Description, result.Description);
        Assert.Equal(input.ContactNumber, result.ContactNumber);
        Assert.Equal(input.Email, result.Email);
    }

    [Fact]
    public async Task GetById_Found_ReturnsMatchingEntity()
    {
        var created = await _repo.Create(MakeAppointment());

        var result = await _repo.GetById(created.Id);

        Assert.NotNull(result);
        Assert.Equal(created.Id, result.Id);
        Assert.Equal(created.Name, result.Name);
        Assert.Equal(created.Status, result.Status);
    }

    [Fact]
    public async Task GetById_NotFound_ReturnsNull()
    {
        var result = await _repo.GetById(Guid.NewGuid());

        Assert.Null(result);
    }

    [Fact]
    public async Task GetAll_PaginationAndOrdering()
    {
        var baseDate = new DateTimeOffset(2025, 6, 1, 9, 0, 0, TimeSpan.Zero);
        for (var i = 0; i < 15; i++)
            await _repo.Create(MakeAppointment(baseDate.AddDays(i)));

        var (page1Items, totalCount1) = await _repo.GetAll(1, 10);
        var page1List = page1Items.ToList();
        Assert.Equal(10, page1List.Count);
        Assert.Equal(15, totalCount1);
        for (var i = 1; i < page1List.Count; i++)
            Assert.True(page1List[i].DateTime >= page1List[i - 1].DateTime);

        var (page2Items, totalCount2) = await _repo.GetAll(2, 10);
        Assert.Equal(5, page2Items.Count());
        Assert.Equal(15, totalCount2);
    }

    [Fact]
    public async Task Update_ChangesFieldsAndAdvancesUpdatedAt()
    {
        var created = await _repo.Create(MakeAppointment());
        await Task.Delay(50);

        created.Name = "Updated Name";
        created.Description = "Updated description";
        created.DateTime = created.DateTime.AddHours(2);

        var updated = await _repo.Update(created);

        Assert.Equal("Updated Name", updated.Name);
        Assert.Equal("Updated description", updated.Description);
        Assert.True(updated.UpdatedAt >= created.UpdatedAt);
        Assert.Equal(created.Status, updated.Status);
        Assert.Equal(created.Email, updated.Email);
        Assert.Equal(created.ContactNumber, updated.ContactNumber);
        Assert.Equal(created.CreatedAt, updated.CreatedAt);
    }

    [Fact]
    public async Task UpdateStatus_ChangesStatusAndAdvancesUpdatedAt()
    {
        var created = await _repo.Create(MakeAppointment());
        Assert.Equal("pending", created.Status);
        await Task.Delay(50);

        await _repo.UpdateStatus(created.Id, "approved");

        var result = await _repo.GetById(created.Id);
        Assert.NotNull(result);
        Assert.Equal("approved", result.Status);
        Assert.True(result.UpdatedAt >= created.UpdatedAt);
        Assert.Equal(created.Name, result.Name);
    }

    [Fact]
    public async Task Delete_RemovesRecord()
    {
        var created = await _repo.Create(MakeAppointment());

        await _repo.Delete(created.Id);

        var result = await _repo.GetById(created.Id);
        Assert.Null(result);
    }
}
