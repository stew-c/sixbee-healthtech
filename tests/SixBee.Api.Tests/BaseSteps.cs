using Reqnroll;

namespace SixBee.Api.Tests;

[Binding]
public class BaseSteps
{
    private readonly ScenarioContext _context;

    public BaseSteps(ScenarioContext context)
    {
        _context = context;
    }

    [Then("the response status is {int}")]
    public void ThenTheResponseStatusIs(int statusCode)
    {
        var response = _context.Get<HttpResponseMessage>("Response");
        Assert.Equal(statusCode, (int)response.StatusCode);
    }
}
