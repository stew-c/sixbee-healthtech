using System.Net.Http.Headers;
using System.Text.Json;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Reqnroll;
using SixBee.Appointments;

namespace SixBee.Api.Tests.Steps;

[Binding]
public class MiddlewareSteps : IClassFixture<TestApiFactory>
{
    private readonly ScenarioContext _context;
    private readonly TestApiFactory _factory;

    public MiddlewareSteps(ScenarioContext context, TestApiFactory factory)
    {
        _context = context;
        _factory = factory;
    }

    [When("I request the health endpoint")]
    public async Task WhenIRequestTheHealthEndpoint()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/health");
        _context.Set(response, "Response");
        _context.Set(await response.Content.ReadAsStringAsync(), "ResponseBody");
    }

    [Then("the response contains status {string}")]
    public void ThenTheResponseContainsStatus(string status)
    {
        var body = _context.Get<string>("ResponseBody");
        var doc = JsonDocument.Parse(body);
        Assert.Equal(status, doc.RootElement.GetProperty("status").GetString());
    }

    [When("I request appointments without an authorization header")]
    public async Task WhenIRequestAppointmentsWithoutAnAuthorizationHeader()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/appointments");
        _context.Set(response, "Response");
    }

    [Given("I have an invalid JWT token")]
    public void GivenIHaveAnInvalidJwtToken()
    {
        _context.Set("not.a.valid.token", "Token");
    }

    [When("I request appointments with the invalid token")]
    public async Task WhenIRequestAppointmentsWithTheInvalidToken()
    {
        var token = _context.Get<string>("Token");
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var response = await client.GetAsync("/api/appointments");
        _context.Set(response, "Response");
    }

    [When("I send an OPTIONS request to {string} from origin {string}")]
    public async Task WhenISendAnOptionsRequestFromOrigin(string path, string origin)
    {
        var client = _factory.CreateClient();
        var request = new HttpRequestMessage(HttpMethod.Options, path);
        request.Headers.Add("Origin", origin);
        request.Headers.Add("Access-Control-Request-Method", "GET");
        var response = await client.SendAsync(request);
        _context.Set(response, "Response");
    }

    [Then("the response contains header {string}")]
    public void ThenTheResponseContainsHeader(string headerName)
    {
        var response = _context.Get<HttpResponseMessage>("Response");
        Assert.True(response.Headers.Contains(headerName) || response.Content.Headers.Contains(headerName),
            $"Response does not contain header '{headerName}'");
    }

    [Given("the appointment service is configured to throw an exception")]
    public void GivenTheAppointmentServiceIsConfiguredToThrowAnException()
    {
        _factory.MockAppointmentService.GetAll(Arg.Any<int>(), Arg.Any<int>())
            .Throws(new InvalidOperationException("Database connection failed"));
    }

    [When("I request appointments as admin")]
    public async Task WhenIRequestAppointmentsAsAdmin()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("Authorization", "Bearer test-token");
        var response = await client.GetAsync("/api/appointments");
        _context.Set(response, "Response");
        _context.Set(await response.Content.ReadAsStringAsync(), "ResponseBody");
    }

    [Then("the response does not contain a stack trace")]
    public void ThenTheResponseDoesNotContainAStackTrace()
    {
        var body = _context.Get<string>("ResponseBody");
        Assert.DoesNotContain("at ", body);
        Assert.DoesNotContain("Database connection failed", body);
    }
}
