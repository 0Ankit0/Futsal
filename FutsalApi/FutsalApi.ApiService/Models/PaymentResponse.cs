using System;

using FutsalApi.ApiService.Data;

namespace FutsalApi.ApiService.Models;

public class PaymentResponse
{
    public int Id { get; set; }
    public int BookingId { get; set; }
    public PaymentMethod Method { get; set; }
    public string? TransactionId { get; set; }
    public decimal AmountPaid { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime PaymentDate { get; set; } = DateTime.UtcNow;
}
