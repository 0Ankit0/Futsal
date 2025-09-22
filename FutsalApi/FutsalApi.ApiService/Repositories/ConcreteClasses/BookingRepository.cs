﻿using System;
using System.Data;
using System.Linq.Expressions;
using Dapper;
using FutsalApi.Data.DTO;
using FutsalApi.Data.Models;
using FutsalApi.ApiService.Repositories;
using Microsoft.EntityFrameworkCore;

namespace FutsalApi.ApiService.Repositories;

public class BookingRepository : GenericRepository<Booking>, IBookingRepository
{
    private readonly AppDbContext _dbContext;
    private readonly IDbConnection _dbConnection;

    public BookingRepository(AppDbContext dbContext, IDbConnection dbConnection) : base(dbContext)
    {
        _dbContext = dbContext;
        _dbConnection = dbConnection;
    }

    public async Task<List<BookingResponse>> GetAllAsync(Expression<Func<Booking, bool>> predicate, int page, int pageSize)
    {
        if (page <= 0 || pageSize <= 0)
        {
            throw new ArgumentOutOfRangeException("Page and pageSize must be greater than 0.");
        }

        return await _dbContext.Bookings
            .Where(predicate)
            .OrderByDescending(r => r.BookingDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(e => new BookingResponse
            {
                Id = e.Id,
                BookingDate = e.BookingDate,
                StartTime = e.StartTime,
                EndTime = e.EndTime,
                Status = e.Status,
                TotalAmount = e.TotalAmount,
                CreatedAt = e.CreatedAt,
                GroundName = e.Ground.Name
            })
            .ToListAsync();
    }

    public async Task<IEnumerable<BookingResponse>> GetBookingsByUserIdAsync(string userId, int page, int pageSize)
    {
        if (page <= 0 || pageSize <= 0)
        {
            throw new ArgumentOutOfRangeException("Page and pageSize must be greater than 0.");
        }

        return await _dbContext.Bookings
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.BookingDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(e => new BookingResponse
            {
                Id = e.Id,
                BookingDate = e.BookingDate,
                StartTime = e.StartTime,
                EndTime = e.EndTime,
                Status = e.Status,
                TotalAmount = e.TotalAmount,
                CreatedAt = e.CreatedAt,
                GroundName = e.Ground.Name
            })
            .ToListAsync();
    }

    public async Task<int> CreateBookingAsync(Booking booking)
{
    if (booking == null)
        throw new ArgumentNullException(nameof(booking), "Booking cannot be null.");

    var parameters = new DynamicParameters();
    parameters.Add("p_user_id", booking.UserId);
    parameters.Add("p_ground_id", booking.GroundId);
    parameters.Add("p_booking_date", DateOnly.FromDateTime(booking.BookingDate)); 
    parameters.Add("p_start_time", TimeOnly.FromTimeSpan(booking.StartTime)); 
    parameters.Add("p_end_time", TimeOnly.FromTimeSpan(booking.EndTime)); 
    parameters.Add("p_total_amount", booking.TotalAmount);

    return await _dbConnection.ExecuteScalarAsync<int>(
        "SELECT * FROM create_booking(@p_user_id, @p_ground_id, @p_booking_date, @p_start_time, @p_end_time, @p_total_amount)", 
        parameters, 
        commandType: CommandType.Text);
}


    public async Task<bool> CancelBookingAsync(int bookingId, string userId)
    {
        var parameters = new { p_booking_id = bookingId, p_user_id = userId };
        return await _dbConnection.ExecuteScalarAsync<bool>("cancel_booking", parameters, commandType: CommandType.StoredProcedure);
    }
}
