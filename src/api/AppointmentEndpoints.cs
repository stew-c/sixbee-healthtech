using SixBee.Api.DTOs;
using SixBee.Appointments;

namespace SixBee.Api;

public static class AppointmentEndpoints
{
    public static WebApplication MapAppointmentEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/appointments").RequireAuthorization();

        group.MapPost("/", async (CreateAppointmentRequest request, IAppointmentService service) =>
        {
            var appointment = ToEntity(request);
            var result = await service.Create(appointment);
            return Results.Created($"/api/appointments/{result.Id}", ToResponse(result));
        }).AllowAnonymous();

        group.MapGet("/", async (int? page, int? pageSize, IAppointmentService service) =>
        {
            var p = page ?? 1;
            var ps = pageSize ?? 10;
            var (items, totalCount) = await service.GetAll(p, ps);
            return Results.Ok(new AppointmentListResponse(items.Select(ToResponse), totalCount, p, ps));
        });

        group.MapGet("/{id:guid}", async (Guid id, IAppointmentService service) =>
        {
            var appointment = await service.GetById(id);
            return appointment is null ? Results.NotFound() : Results.Ok(ToResponse(appointment));
        });

        group.MapPut("/{id:guid}", async (Guid id, UpdateAppointmentRequest request, IAppointmentService service) =>
        {
            var appointment = ToEntity(request);
            var result = await service.Update(id, appointment);
            return result is null ? Results.NotFound() : Results.Ok(ToResponse(result));
        });

        group.MapPatch("/{id:guid}/approve", async (Guid id, IAppointmentService service) =>
        {
            var result = await service.Approve(id);
            return result is null ? Results.NotFound() : Results.Ok(ToResponse(result));
        });

        group.MapDelete("/{id:guid}", async (Guid id, IAppointmentService service) =>
        {
            var deleted = await service.Delete(id);
            return deleted ? Results.NoContent() : Results.NotFound();
        });

        return app;
    }

    private static AppointmentResponse ToResponse(Appointment a) =>
        new(a.Id, a.Name, a.DateTime, a.Description, a.ContactNumber, a.Email, a.Status, a.CreatedAt, a.UpdatedAt);

    private static Appointment ToEntity(CreateAppointmentRequest r) =>
        new() { Name = r.Name, DateTime = r.DateTime, Description = r.Description, ContactNumber = r.ContactNumber, Email = r.Email };

    private static Appointment ToEntity(UpdateAppointmentRequest r) =>
        new() { Name = r.Name, DateTime = r.DateTime, Description = r.Description, ContactNumber = r.ContactNumber, Email = r.Email };
}
