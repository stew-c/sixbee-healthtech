using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;

namespace SixBee.Migrations;

public static class WebApplicationExtensions
{
    public static WebApplication RunMigrations(this WebApplication app)
    {
        var connectionString = app.Configuration.GetConnectionString("DefaultConnection");
        if (!string.IsNullOrEmpty(connectionString))
            DbMigrator.Run(connectionString);

        return app;
    }
}
