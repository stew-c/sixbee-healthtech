using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using NSubstitute;
using SixBee.Appointments;
using SixBee.Auth;

namespace SixBee.Api.Tests;

public class TestApiFactory : WebApplicationFactory<Program>
{
    public IAuthService MockAuthService { get; } = Substitute.For<IAuthService>();
    public IAppointmentService MockAppointmentService { get; } = Substitute.For<IAppointmentService>();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            var authDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(IAuthService));
            if (authDescriptor != null) services.Remove(authDescriptor);

            var appointmentDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(IAppointmentService));
            if (appointmentDescriptor != null) services.Remove(appointmentDescriptor);

            services.AddScoped(_ => MockAuthService);
            services.AddScoped(_ => MockAppointmentService);

            services.AddAuthentication("Test")
                .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>("Test", null);
            services.AddAuthorization();
        });
    }
}

public class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public TestAuthHandler(IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger, UrlEncoder encoder) : base(options, logger, encoder) { }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.ContainsKey("Authorization"))
            return Task.FromResult(AuthenticateResult.Fail("No Authorization header"));

        var claims = new[] { new Claim(ClaimTypes.Name, "admin@sixbee.co.uk") };
        var identity = new ClaimsIdentity(claims, "Test");
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, "Test");
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
