namespace SixBee.Api.DTOs;

public record UpdateAppointmentRequest(string Name, DateTimeOffset DateTime, string Description, string ContactNumber, string Email);
