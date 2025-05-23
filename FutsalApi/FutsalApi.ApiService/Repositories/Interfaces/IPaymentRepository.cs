﻿using System;
using System.Linq.Expressions;

using FutsalApi.Data.DTO;
using FutsalApi.ApiService.Models;

namespace FutsalApi.ApiService.Repositories;

public interface IPaymentRepository : IGenericRepository<Payment>
{
    Task<IEnumerable<PaymentResponse>> GetPaymentsByUserIdAsync(string bookingId, int page, int pageSize);
    Task<PaymentResponse?> GetPaymentByBookingIdAsync(Expression<Func<Payment, bool>> predicate);
    Task<decimal> GetPaidAmount(int id);
}
