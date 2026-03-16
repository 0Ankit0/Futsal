using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using FutsalApi.UI.Shared.Models;
using FutsalApi.UI.Shared;

namespace FutsalApi.UI.Shared.Services
{
    public class AuthService
    {
        private readonly HttpClient _httpClient;

        public AuthService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task<bool> Login(LoginRequest loginRequest)
        {
            var response = await _httpClient.PostAsJsonAsync("User/login", loginRequest);
            return response.IsSuccessStatusCode;
        }

        public async Task<bool> Register(RegisterRequest registerRequest)
        {
            var response = await _httpClient.PostAsJsonAsync("User/register", registerRequest);
            return response.IsSuccessStatusCode;
        }
    }
}
