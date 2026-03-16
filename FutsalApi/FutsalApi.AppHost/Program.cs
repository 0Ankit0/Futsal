var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");

var db = builder.AddPostgres("db")
    .WithPgAdmin(pgAdmin => pgAdmin.WithHostPort(5050))
    .WithVolume("./pgdata", "/var/lib/postgresql/data")
    .WithEnvironment("POSTGRES_DB", "futsaldb");

var futsaldb = db.AddDatabase("futsaldb");

var apiService = builder.AddProject<Projects.FutsalApi_ApiService>("apiservice")
   .WithExternalHttpEndpoints()
    .WithReference(futsaldb)
    .WaitFor(futsaldb)
    .WithReference(cache)
    .WaitFor(cache);

var web = builder.AddProject<Projects.FutsalApi_UI_Web>("web")
    .WithExternalHttpEndpoints()
    .WithReference(apiService)
    .WaitFor(apiService)
    .WithReference(cache)
    .WaitFor(cache);

builder.Build().Run();
