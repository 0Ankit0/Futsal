using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using FutsalApi.UI.Shared.Models;
using FutsalApi.UI.Shared;

namespace FutsalApi.UI.Shared.Services
{
    public class BookingService
    {
        private readonly HttpClient _httpClient;

        public BookingService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task BookFutsal(BookingRequest bookingRequest)
        {
            await _httpClient.PostAsJsonAsync("Booking", bookingRequest);
        }
    }
}
