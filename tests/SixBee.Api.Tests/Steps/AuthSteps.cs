using System.Net.Http.Json;
using System.Text.Json;
using NSubstitute;
using Reqnroll;
using SixBee.Auth;
using SixBee.Core;

namespace SixBee.Api.Tests.Steps;

[Binding]
public class AuthSteps : IClassFixture<TestApiFactory>
{
    private readonly ScenarioContext _context;
    private readonly TestApiFactory _factory;
    private readonly HttpClient _client;

    public AuthSteps(ScenarioContext context, TestApiFactory factory)
    {
        _context = context;
        _factory = factory;
        _client = factory.CreateClient();

        // Configure mock auth service
        _factory.MockAuthService.Login("admin@sixbee.co.uk", "password123")
            .Returns(new AuthResult(true, Token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test", ExpiresAt: DateTimeOffset.UtcNow.AddHours(2)));

        _factory.MockAuthService.Login("admin@sixbee.co.uk", "wrongpassword")
            .Returns(new AuthResult(false, Error: "Invalid credentials"));

        _factory.MockAuthService.Login("nobody@example.com", "password123")
            .Returns(new AuthResult(false, Error: "Invalid credentials"));

        _factory.MockAuthService.Login("", "password123")
            .Returns<AuthResult>(_ => throw new ValidationException([new ValidationError("Email", "Email is required")]));

        _factory.MockAuthService.Login("admin@sixbee.co.uk", "")
            .Returns<AuthResult>(_ => throw new ValidationException([new ValidationError("Password", "Password is required")]));
    }

    [When("I log in with email {string} and password {string}")]
    public async Task WhenILogInWithEmailAndPassword(string email, string password)
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login", new { email, password });
        _context.Set(response, "Response");

        var body = await response.Content.ReadAsStringAsync();
        _context.Set(body, "ResponseBody");
    }

    [Then("the response contains a JWT token")]
    public void ThenTheResponseContainsAJwtToken()
    {
        var body = _context.Get<string>("ResponseBody");
        var doc = JsonDocument.Parse(body);
        Assert.True(doc.RootElement.TryGetProperty("token", out var token));
        Assert.False(string.IsNullOrEmpty(token.GetString()));
    }

    [Then("the response contains an expiry time")]
    public void ThenTheResponseContainsAnExpiryTime()
    {
        var body = _context.Get<string>("ResponseBody");
        var doc = JsonDocument.Parse(body);
        Assert.True(doc.RootElement.TryGetProperty("expiresAt", out var expiresAt));
        Assert.True(DateTimeOffset.TryParse(expiresAt.GetString(), out _));
    }

    [Then("the response contains error {string}")]
    public void ThenTheResponseContainsError(string expectedError)
    {
        var body = _context.Get<string>("ResponseBody");
        var doc = JsonDocument.Parse(body);
        Assert.True(doc.RootElement.TryGetProperty("error", out var error));
        Assert.Equal(expectedError, error.GetString());
    }

    [Then("the request did not require an authorization header")]
    public void ThenTheRequestDidNotRequireAnAuthorizationHeader()
    {
        Assert.False(_client.DefaultRequestHeaders.Contains("Authorization"));
        var response = _context.Get<HttpResponseMessage>("Response");
        Assert.NotEqual(System.Net.HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
