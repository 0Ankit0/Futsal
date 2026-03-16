using System.ComponentModel.DataAnnotations;

namespace FutsalApi.UI.Web.Configuration;

public class ApiEndpointOptions
{
    public const string SectionName = "ApiEndpoints";

    [Required]
    [Url]
    public string ApiBaseUrl { get; set; } = string.Empty;
}

