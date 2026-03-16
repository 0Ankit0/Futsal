using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using FutsalApi.UI.Shared.Models;
using FutsalApi.UI.Shared;

namespace FutsalApi.UI.Shared.Services
{
    public class FutsalService
    {
        private readonly HttpClient _httpClient;

        public FutsalService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task<IEnumerable<FutsalGroundResponse>> SearchFutsalGrounds(
            string? name = null, 
            double? latitude = null, 
            double? longitude = null, 
            double? minRating = null, 
            double? maxRating = null)
        {
            var queryParams = new List<string>();
            
            if (!string.IsNullOrEmpty(name))
                queryParams.Add($"name={Uri.EscapeDataString(name)}");
            
            if (latitude.HasValue)
                queryParams.Add($"latitude={latitude.Value}");
            
            if (longitude.HasValue)
                queryParams.Add($"longitude={longitude.Value}");
            
            if (minRating.HasValue)
                queryParams.Add($"minRating={minRating.Value}");
            
            if (maxRating.HasValue)
                queryParams.Add($"maxRating={maxRating.Value}");
            
            var queryString = queryParams.Count > 0 ? "?" + string.Join("&", queryParams) : "";
            
            return await _httpClient.GetFromJsonAsync<IEnumerable<FutsalGroundResponse>>($"{ApiRoutes.FutsalGround.Search}{queryString}") ?? new List<FutsalGroundResponse>();
        }

        public async Task<FutsalGroundResponse> GetFutsalGroundById(int id)
        {
            return await _httpClient.GetFromJsonAsync<FutsalGroundResponse>(ApiRoutes.FutsalGround.ById(id));
        }
    }
}
