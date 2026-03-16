using FutsalApi.UI.Shared.Services;
using FutsalApi.UI.Web.Configuration;
using FutsalApi.UI.Web.Components;
using FutsalApi.UI.Web.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.AddServiceDefaults();

builder.AddRedisOutputCache("cache");

builder.Services
    .AddOptions<ApiEndpointOptions>()
    .Bind(builder.Configuration.GetSection(ApiEndpointOptions.SectionName))
    .ValidateDataAnnotations()
    .Validate(options => Uri.TryCreate(options.ApiBaseUrl, UriKind.Absolute, out _), "ApiEndpoints:ApiBaseUrl must be a valid absolute URI.")
    .ValidateOnStart();

var apiEndpointOptions = builder.Configuration
    .GetSection(ApiEndpointOptions.SectionName)
    .Get<ApiEndpointOptions>() ?? throw new InvalidOperationException("Missing ApiEndpoints configuration.");

var apiBaseUri = new Uri(apiEndpointOptions.ApiBaseUrl);

// Add device-specific services used by the FutsalApi.UI.Shared project
builder.Services.AddSingleton<IFormFactor, FormFactor>();

builder.Services.AddHttpClient<FutsalService>(client =>
{
    client.BaseAddress = apiBaseUri;
});

builder.Services.AddHttpClient<BookingService>(client =>
{
    client.BaseAddress = apiBaseUri;
});

builder.Services.AddHttpClient<AuthService>(client =>
{
    client.BaseAddress = apiBaseUri;
});

var app = builder.Build();

app.Logger.LogInformation("Startup API endpoint selected for Web client -> {ApiBaseUrl}", apiBaseUri);

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseOutputCache();

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode()
    .AddAdditionalAssemblies(typeof(FutsalApi.UI.Shared._Imports).Assembly);

app.Run();
