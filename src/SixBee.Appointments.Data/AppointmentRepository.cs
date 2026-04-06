using Npgsql;
using SixBee.Appointments;
using SqlKata.Compilers;
using SqlKata.Execution;

namespace SixBee.Appointments.Data;

public class AppointmentRepository : IAppointmentRepository
{
    private readonly string _connectionString;

    public AppointmentRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private QueryFactory CreateQueryFactory()
    {
        var connection = new NpgsqlConnection(_connectionString);
        return new QueryFactory(connection, new PostgresCompiler());
    }

    public async Task<Appointment> Create(Appointment appointment)
    {
        using var db = CreateQueryFactory();
        var id = Guid.NewGuid();
        await db.Query("appointment").InsertAsync(new
        {
            Id = id,
            appointment.Name,
            appointment.DateTime,
            appointment.Description,
            appointment.ContactNumber,
            appointment.Email
        });
        return (await GetById(id))!;
    }

    public async Task<Appointment?> GetById(Guid id)
    {
        using var db = CreateQueryFactory();
        return await db.Query("appointment").Where("Id", id).FirstOrDefaultAsync<Appointment>();
    }

    public async Task<(IEnumerable<Appointment> Items, int TotalCount)> GetAll(int page, int pageSize)
    {
        using var db = CreateQueryFactory();
        var offset = (page - 1) * pageSize;
        var items = await db.Query("appointment").OrderBy("DateTime").Skip(offset).Take(pageSize).GetAsync<Appointment>();
        var totalCount = await db.Query("appointment").CountAsync<int>();
        return (items, totalCount);
    }

    public async Task<Appointment> Update(Appointment appointment)
    {
        using var db = CreateQueryFactory();
        await db.Query("appointment").Where("Id", appointment.Id).UpdateAsync(new
        {
            appointment.Name,
            appointment.DateTime,
            appointment.Description,
            appointment.ContactNumber,
            appointment.Email,
            UpdatedAt = DateTimeOffset.UtcNow
        });
        return (await GetById(appointment.Id))!;
    }

    public async Task UpdateStatus(Guid id, string status)
    {
        using var db = CreateQueryFactory();
        await db.Query("appointment").Where("Id", id).UpdateAsync(new
        {
            Status = status,
            UpdatedAt = DateTimeOffset.UtcNow
        });
    }

    public async Task Delete(Guid id)
    {
        using var db = CreateQueryFactory();
        await db.Query("appointment").Where("Id", id).DeleteAsync();
    }
}
