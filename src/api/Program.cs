using SixBee.Migrations;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.RunMigrations();

app.MapGet("/api/health", () => Results.Ok("healthy"));

app.Run();

public partial class Program;
