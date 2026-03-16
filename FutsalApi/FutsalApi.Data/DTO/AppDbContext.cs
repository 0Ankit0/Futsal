using System;

using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace FutsalApi.Data.DTO;

public class AppDbContext : IdentityDbContext<User, Role, string, IdentityUserClaim<string>, UserRole, IdentityUserLogin<string>, IdentityRoleClaim<string>, IdentityUserToken<string>>
{
    public AppDbContext()
    {
    }

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<GeneralSetting> GeneralSettings { get; set; }
    public DbSet<FutsalGround>? FutsalGrounds { get; set; }
    public DbSet<Booking>? Bookings { get; set; }
    public DbSet<Payment>? Payments { get; set; }
    public DbSet<Notification>? Notifications { get; set; }
    public DbSet<DeviceToken>? DeviceTokens { get; set; }
    public DbSet<Review>? Reviews { get; set; }
    public DbSet<Image>? Images { get; set; }
    public DbSet<GroundClosure>? GroundClosures { get; set; }
    public DbSet<FavouriteFutsalGround> FavouriteFutsalGrounds { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<DeviceToken>()
            .HasIndex(dt => new { dt.UserId, dt.Platform })
            .IsUnique();
    }
}
