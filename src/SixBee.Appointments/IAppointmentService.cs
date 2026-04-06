namespace SixBee.Appointments;

public interface IAppointmentService
{
    Task<Appointment> Create(Appointment appointment);
    Task<Appointment?> GetById(Guid id);
    Task<(IEnumerable<Appointment> Items, int TotalCount)> GetAll(int page, int pageSize);
    Task<Appointment?> Update(Guid id, Appointment appointment);
    Task<Appointment?> Approve(Guid id);
    Task<bool> Delete(Guid id);
}
