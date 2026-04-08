using System.Text.RegularExpressions;
using SixBee.Core;

namespace SixBee.Appointments;

public partial class AppointmentService : IAppointmentService
{
    private readonly IAppointmentRepository _appointmentRepository;

    public AppointmentService(IAppointmentRepository appointmentRepository)
    {
        _appointmentRepository = appointmentRepository;
    }

    private static void ValidateFields(Appointment appointment)
    {
        var errors = new List<ValidationError>();

        if (string.IsNullOrWhiteSpace(appointment.Name))
            errors.Add(new ValidationError("Name", "Name is required"));
        else if (appointment.Name.Length > 255)
            errors.Add(new ValidationError("Name", "Name must be 255 characters or fewer"));

        if (appointment.DateTime == default)
            errors.Add(new ValidationError("DateTime", "Date and time is required"));

        if (string.IsNullOrWhiteSpace(appointment.Description))
            errors.Add(new ValidationError("Description", "Description is required"));
        else if (appointment.Description.Length > 255)
            errors.Add(new ValidationError("Description", "Description must be 255 characters or fewer"));

        if (string.IsNullOrWhiteSpace(appointment.ContactNumber))
            errors.Add(new ValidationError("ContactNumber", "Contact number is required"));
        else if (!UkMobileRegex().IsMatch(appointment.ContactNumber))
            errors.Add(new ValidationError("ContactNumber", "Contact number format is invalid"));

        if (string.IsNullOrWhiteSpace(appointment.Email))
            errors.Add(new ValidationError("Email", "Email is required"));
        else if (appointment.Email.Length > 255)
            errors.Add(new ValidationError("Email", "Email must be 255 characters or fewer"));
        else if (!EmailRegex().IsMatch(appointment.Email))
            errors.Add(new ValidationError("Email", "Email format is invalid"));

        if (errors.Count > 0)
            throw new ValidationException(errors);
    }

    [GeneratedRegex(@"^07\d{9}$")]
    private static partial Regex UkMobileRegex();

    [GeneratedRegex(@"^[^@\s]+@[^@\s]+\.[^@\s]+$")]
    private static partial Regex EmailRegex();

    public async Task<Appointment> Create(Appointment appointment)
    {
        ValidateFields(appointment);

        if (appointment.DateTime <= DateTimeOffset.UtcNow)
            throw new ValidationException([new ValidationError("DateTime", "Appointment date must be in the future")]);

        return await _appointmentRepository.Create(appointment);
    }

    public async Task<Appointment?> GetById(Guid id)
    {
        return await _appointmentRepository.GetById(id);
    }

    public async Task<(IEnumerable<Appointment> Items, int TotalCount)> GetAll(int page, int pageSize)
    {
        return await _appointmentRepository.GetAll(page, pageSize);
    }

    public async Task<Appointment?> Update(Guid id, Appointment appointment)
    {
        var existing = await _appointmentRepository.GetById(id);
        if (existing is null)
            return null;

        ValidateFields(appointment);

        existing.Name = appointment.Name;
        existing.DateTime = appointment.DateTime;
        existing.Description = appointment.Description;
        existing.ContactNumber = appointment.ContactNumber;
        existing.Email = appointment.Email;

        return await _appointmentRepository.Update(existing);
    }

    public async Task<Appointment?> Approve(Guid id)
    {
        var appointment = await _appointmentRepository.GetById(id);
        if (appointment is null)
            return null;

        if (appointment.Status == AppointmentStatus.Approved)
            return appointment;

        return await _appointmentRepository.UpdateStatus(id, AppointmentStatus.Approved);
    }

    public async Task<bool> Delete(Guid id)
    {
        var affected = await _appointmentRepository.Delete(id);
        return affected > 0;
    }
}
