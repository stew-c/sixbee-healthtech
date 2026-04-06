namespace SixBee.Api.DTOs;

public record CreateAppointmentRequest(string Name, DateTimeOffset DateTime, string Description, string ContactNumber, string Email);
