namespace SixBee.Appointments;

public class Appointment
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public DateTimeOffset DateTime { get; set; }
    public string Description { get; set; } = "";
    public string ContactNumber { get; set; } = "";
    public string Email { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
