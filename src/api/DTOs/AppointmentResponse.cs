namespace SixBee.Api.DTOs;

public record AppointmentResponse(
    Guid Id, string Name, DateTimeOffset DateTime, string Description,
    string ContactNumber, string Email, string Status,
    DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public record AppointmentListResponse(
    IEnumerable<AppointmentResponse> Items, int TotalCount, int Page, int PageSize);
