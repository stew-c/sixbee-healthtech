using NSubstitute;
using SixBee.Core;

namespace SixBee.Appointments.Tests;

public class AppointmentServiceTests
{
    private readonly IAppointmentRepository _repo;
    private readonly AppointmentService _service;
    private readonly Guid _knownId = Guid.NewGuid();
    private readonly Appointment _existingAppointment;

    public AppointmentServiceTests()
    {
        _repo = Substitute.For<IAppointmentRepository>();
        _service = new AppointmentService(_repo);

        _existingAppointment = new Appointment
        {
            Id = _knownId,
            Name = "Existing Patient",
            DateTime = DateTimeOffset.UtcNow.AddDays(5),
            Description = "Existing appointment",
            ContactNumber = "07700900000",
            Email = "existing@example.com",
            Status = "pending",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        _repo.GetById(_knownId).Returns(_existingAppointment);
        _repo.GetById(Arg.Is<Guid>(id => id != _knownId)).Returns((Appointment?)null);
        _repo.Create(Arg.Any<Appointment>()).Returns(c => c.Arg<Appointment>());
        _repo.Update(Arg.Any<Appointment>()).Returns(c => c.Arg<Appointment>());
    }

    private static Appointment ValidAppointment() => new()
    {
        Name = "Test Patient",
        DateTime = DateTimeOffset.UtcNow.AddDays(1),
        Description = "Test appointment",
        ContactNumber = "07700900000",
        Email = "test@example.com"
    };

    // Validation tests

    [Fact]
    public async Task Create_WithMissingName_ThrowsValidationException()
    {
        var appt = ValidAppointment();
        appt.Name = "";
        var ex = await Assert.ThrowsAsync<ValidationException>(() => _service.Create(appt));
        Assert.Contains(ex.Errors, e => e.Field == "Name");
    }

    [Fact]
    public async Task Create_WithMissingEmail_ThrowsValidationException()
    {
        var appt = ValidAppointment();
        appt.Email = "";
        var ex = await Assert.ThrowsAsync<ValidationException>(() => _service.Create(appt));
        Assert.Contains(ex.Errors, e => e.Field == "Email");
    }

    [Fact]
    public async Task Create_WithInvalidEmailFormat_ThrowsValidationException()
    {
        var appt = ValidAppointment();
        appt.Email = "not-an-email";
        var ex = await Assert.ThrowsAsync<ValidationException>(() => _service.Create(appt));
        Assert.Contains(ex.Errors, e => e.Field == "Email" && e.Message.Contains("format"));
    }

    [Fact]
    public async Task Create_WithMissingContactNumber_ThrowsValidationException()
    {
        var appt = ValidAppointment();
        appt.ContactNumber = "";
        var ex = await Assert.ThrowsAsync<ValidationException>(() => _service.Create(appt));
        Assert.Contains(ex.Errors, e => e.Field == "ContactNumber");
    }

    [Fact]
    public async Task Create_WithInvalidContactNumberFormat_ThrowsValidationException()
    {
        var appt = ValidAppointment();
        appt.ContactNumber = "12345";
        var ex = await Assert.ThrowsAsync<ValidationException>(() => _service.Create(appt));
        Assert.Contains(ex.Errors, e => e.Field == "ContactNumber" && e.Message.Contains("format"));
    }

    [Fact]
    public async Task Create_WithMissingDescription_ThrowsValidationException()
    {
        var appt = ValidAppointment();
        appt.Description = "";
        var ex = await Assert.ThrowsAsync<ValidationException>(() => _service.Create(appt));
        Assert.Contains(ex.Errors, e => e.Field == "Description");
    }

    // Create tests

    [Fact]
    public async Task Create_WithValidDataAndFutureDate_CallsRepositoryAndReturnsEntity()
    {
        var appt = ValidAppointment();
        var result = await _service.Create(appt);

        Assert.NotNull(result);
        await _repo.Received(1).Create(appt);
    }

    [Fact]
    public async Task Create_WithPastDate_ThrowsValidationException_RepositoryNotCalled()
    {
        var appt = ValidAppointment();
        appt.DateTime = DateTimeOffset.UtcNow.AddDays(-1);

        var ex = await Assert.ThrowsAsync<ValidationException>(() => _service.Create(appt));
        Assert.Contains(ex.Errors, e => e.Field == "DateTime" && e.Message.Contains("future"));
        await _repo.DidNotReceive().Create(Arg.Any<Appointment>());
    }

    [Fact]
    public async Task Create_WithInvalidFields_ThrowsValidationException_RepositoryNotCalled()
    {
        var appt = new Appointment();

        await Assert.ThrowsAsync<ValidationException>(() => _service.Create(appt));
        await _repo.DidNotReceive().Create(Arg.Any<Appointment>());
    }

    // GetById tests

    [Fact]
    public async Task GetById_WhenFound_ReturnsEntity()
    {
        var result = await _service.GetById(_knownId);
        Assert.NotNull(result);
        Assert.Equal(_knownId, result.Id);
    }

    [Fact]
    public async Task GetById_WhenNotFound_ReturnsNull()
    {
        var result = await _service.GetById(Guid.NewGuid());
        Assert.Null(result);
    }

    // GetAll tests

    [Fact]
    public async Task GetAll_PassesPaginationParametersToRepository()
    {
        var expected = (Items: new List<Appointment>().AsEnumerable(), TotalCount: 0);
        _repo.GetAll(2, 15).Returns(expected);

        var result = await _service.GetAll(2, 15);

        await _repo.Received(1).GetAll(2, 15);
        Assert.Equal(0, result.TotalCount);
    }

    // Update tests

    [Fact]
    public async Task Update_WhenFoundWithValidData_UpdatesFieldsPreservesStatus()
    {
        var updated = ValidAppointment();
        updated.Name = "Updated Name";

        var result = await _service.Update(_knownId, updated);

        Assert.NotNull(result);
        Assert.Equal("Updated Name", result!.Name);
        Assert.Equal("pending", result.Status);
        await _repo.Received(1).Update(Arg.Any<Appointment>());
    }

    [Fact]
    public async Task Update_WithInvalidFields_ThrowsValidationException_RepositoryUpdateNotCalled()
    {
        var appt = new Appointment();

        await Assert.ThrowsAsync<ValidationException>(() => _service.Update(_knownId, appt));
        await _repo.DidNotReceive().Update(Arg.Any<Appointment>());
    }

    [Fact]
    public async Task Update_WhenNotFound_ReturnsNull_RepositoryUpdateNotCalled()
    {
        var result = await _service.Update(Guid.NewGuid(), ValidAppointment());

        Assert.Null(result);
        await _repo.DidNotReceive().Update(Arg.Any<Appointment>());
    }

    // Approve tests

    [Fact]
    public async Task Approve_PendingAppointment_CallsUpdateStatusWithApproved()
    {
        var result = await _service.Approve(_knownId);

        Assert.NotNull(result);
        await _repo.Received(1).UpdateStatus(_knownId, "approved");
    }

    [Fact]
    public async Task Approve_AlreadyApproved_ReturnsExistingEntity_UpdateStatusNotCalled()
    {
        _existingAppointment.Status = "approved";

        var result = await _service.Approve(_knownId);

        Assert.NotNull(result);
        Assert.Equal("approved", result!.Status);
        await _repo.DidNotReceive().UpdateStatus(Arg.Any<Guid>(), Arg.Any<string>());
    }

    [Fact]
    public async Task Approve_WhenNotFound_ReturnsNull()
    {
        var result = await _service.Approve(Guid.NewGuid());
        Assert.Null(result);
    }

    // Delete tests

    [Fact]
    public async Task Delete_WhenFound_CallsRepositoryDelete_ReturnsTrue()
    {
        var result = await _service.Delete(_knownId);

        Assert.True(result);
        await _repo.Received(1).Delete(_knownId);
    }

    [Fact]
    public async Task Delete_WhenNotFound_DoesNotCallRepositoryDelete_ReturnsFalse()
    {
        var result = await _service.Delete(Guid.NewGuid());

        Assert.False(result);
        await _repo.DidNotReceive().Delete(Arg.Any<Guid>());
    }
}
