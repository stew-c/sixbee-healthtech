namespace SixBee.Appointments;

public interface IAppointmentRepository
{
    Task<Appointment> Create(Appointment appointment);
    Task<Appointment?> GetById(Guid id);
    Task<(IEnumerable<Appointment> Items, int TotalCount)> GetAll(int page, int pageSize);
    Task<Appointment> Update(Appointment appointment);
    Task<Appointment?> UpdateStatus(Guid id, string status);
    Task<int> Delete(Guid id);
}
