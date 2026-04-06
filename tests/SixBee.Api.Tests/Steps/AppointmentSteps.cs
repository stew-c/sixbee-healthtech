using System.Net.Http.Json;
using System.Text.Json;
using NSubstitute;
using Reqnroll;
using SixBee.Appointments;
using SixBee.Core;

namespace SixBee.Api.Tests.Steps;

[Binding]
public class AppointmentSteps : IClassFixture<TestApiFactory>
{
    private readonly ScenarioContext _context;
    private readonly TestApiFactory _factory;
    private readonly HttpClient _client;
    private readonly Guid _knownId = Guid.NewGuid();

    public AppointmentSteps(ScenarioContext context, TestApiFactory factory)
    {
        _context = context;
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Add("Authorization", "Bearer test-token");
    }

    private static Appointment MakeAppointment(string name = "Test Patient", string status = "pending") => new()
    {
        Id = Guid.NewGuid(),
        Name = name,
        DateTime = DateTimeOffset.UtcNow.AddDays(1),
        Description = "Test appointment",
        ContactNumber = "07700900000",
        Email = "test@example.com",
        Status = status,
        CreatedAt = DateTimeOffset.UtcNow,
        UpdatedAt = DateTimeOffset.UtcNow
    };

    [When("a patient submits a booking with name {string}")]
    public async Task WhenAPatientSubmitsABookingWithName(string name)
    {
        var created = MakeAppointment(name);
        _factory.MockAppointmentService.Create(Arg.Any<Appointment>()).Returns(created);

        var response = await _client.PostAsJsonAsync("/api/appointments", new
        {
            name,
            dateTime = DateTimeOffset.UtcNow.AddDays(1),
            description = "Test appointment",
            contactNumber = "07700900000",
            email = "test@example.com"
        });
        _context.Set(response, "Response");
        _context.Set(await response.Content.ReadAsStringAsync(), "ResponseBody");
    }

    [When("a patient submits a booking with missing name")]
    public async Task WhenAPatientSubmitsABookingWithMissingName()
    {
        _factory.MockAppointmentService.Create(Arg.Any<Appointment>())
            .Returns<Appointment>(_ => throw new ValidationException([new ValidationError("Name", "Name is required")]));

        var response = await _client.PostAsJsonAsync("/api/appointments", new
        {
            name = "",
            dateTime = DateTimeOffset.UtcNow.AddDays(1),
            description = "Test",
            contactNumber = "07700900000",
            email = "test@example.com"
        });
        _context.Set(response, "Response");
    }

    [When("a patient submits a booking with a past date")]
    public async Task WhenAPatientSubmitsABookingWithAPastDate()
    {
        _factory.MockAppointmentService.Create(Arg.Any<Appointment>())
            .Returns<Appointment>(_ => throw new ValidationException([new ValidationError("DateTime", "Appointment date must be in the future")]));

        var response = await _client.PostAsJsonAsync("/api/appointments", new
        {
            name = "Test",
            dateTime = DateTimeOffset.UtcNow.AddDays(-1),
            description = "Test",
            contactNumber = "07700900000",
            email = "test@example.com"
        });
        _context.Set(response, "Response");
    }

    [Given("there are {int} appointments")]
    public void GivenThereAreAppointments(int count)
    {
        var items = Enumerable.Range(0, 10).Select(_ => MakeAppointment());
        _factory.MockAppointmentService.GetAll(1, 10)
            .Returns((items, count));
    }

    [When("an admin requests page {int} with page size {int}")]
    public async Task WhenAnAdminRequestsPageWithPageSize(int page, int pageSize)
    {
        var response = await _client.GetAsync($"/api/appointments?page={page}&pageSize={pageSize}");
        _context.Set(response, "Response");
        _context.Set(await response.Content.ReadAsStringAsync(), "ResponseBody");
    }

    [Given("an appointment exists with name {string}")]
    public void GivenAnAppointmentExistsWithName(string name)
    {
        var appt = MakeAppointment(name);
        appt.Id = _knownId;
        _context.Set(appt, "ExistingAppointment");
    }

    [When("an admin updates the appointment name to {string}")]
    public async Task WhenAnAdminUpdatesTheAppointmentNameTo(string newName)
    {
        var updated = MakeAppointment(newName);
        updated.Id = _knownId;
        _factory.MockAppointmentService.Update(_knownId, Arg.Any<Appointment>()).Returns(updated);

        var response = await _client.PutAsJsonAsync($"/api/appointments/{_knownId}", new
        {
            name = newName,
            dateTime = DateTimeOffset.UtcNow.AddDays(1),
            description = "Test",
            contactNumber = "07700900000",
            email = "test@example.com"
        });
        _context.Set(response, "Response");
        _context.Set(await response.Content.ReadAsStringAsync(), "ResponseBody");
    }

    [Given("a pending appointment exists")]
    public void GivenAPendingAppointmentExists()
    {
        var appt = MakeAppointment();
        appt.Id = _knownId;
        _context.Set(appt, "ExistingAppointment");
    }

    [When("an admin approves the appointment")]
    public async Task WhenAnAdminApprovesTheAppointment()
    {
        var approved = MakeAppointment();
        approved.Id = _knownId;
        approved.Status = "approved";
        _factory.MockAppointmentService.Approve(_knownId).Returns(approved);

        var response = await _client.PatchAsync($"/api/appointments/{_knownId}/approve", null);
        _context.Set(response, "Response");
        _context.Set(await response.Content.ReadAsStringAsync(), "ResponseBody");
    }

    [Given("an appointment exists")]
    public void GivenAnAppointmentExists()
    {
        _factory.MockAppointmentService.Delete(_knownId).Returns(true);
    }

    [When("an admin deletes the appointment")]
    public async Task WhenAnAdminDeletesTheAppointment()
    {
        var response = await _client.DeleteAsync($"/api/appointments/{_knownId}");
        _context.Set(response, "Response");
    }

    [When("an unauthenticated user requests the appointment list")]
    public async Task WhenAnUnauthenticatedUserRequestsTheAppointmentList()
    {
        var unauthClient = _factory.CreateClient();
        var response = await unauthClient.GetAsync("/api/appointments");
        _context.Set(response, "Response");
    }

    [Then("the response contains appointment with name {string}")]
    public void ThenTheResponseContainsAppointmentWithName(string name)
    {
        var body = _context.Get<string>("ResponseBody");
        var doc = JsonDocument.Parse(body);
        Assert.Equal(name, doc.RootElement.GetProperty("name").GetString());
    }

    [Then("the response contains appointment with status {string}")]
    public void ThenTheResponseContainsAppointmentWithStatus(string status)
    {
        var body = _context.Get<string>("ResponseBody");
        var doc = JsonDocument.Parse(body);
        Assert.Equal(status, doc.RootElement.GetProperty("status").GetString());
    }

    [Then("the response contains {int} appointment items")]
    public void ThenTheResponseContainsAppointmentItems(int count)
    {
        var body = _context.Get<string>("ResponseBody");
        var doc = JsonDocument.Parse(body);
        Assert.Equal(count, doc.RootElement.GetProperty("items").GetArrayLength());
    }

    [Then("the response contains total count {int}")]
    public void ThenTheResponseContainsTotalCount(int totalCount)
    {
        var body = _context.Get<string>("ResponseBody");
        var doc = JsonDocument.Parse(body);
        Assert.Equal(totalCount, doc.RootElement.GetProperty("totalCount").GetInt32());
    }
}
