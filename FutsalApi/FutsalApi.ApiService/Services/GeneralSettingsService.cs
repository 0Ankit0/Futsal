﻿using System.Threading.Tasks;

using FutsalApi.Data.DTO;

using Microsoft.EntityFrameworkCore;

namespace FutsalApi.ApiService.Services;

public interface IGeneralSettingsService
{
    Task<string> GetValueAsync(string key);
}

public class GeneralSettingsService : IGeneralSettingsService
{
    private readonly AppDbContext _context;

    public GeneralSettingsService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<string> GetValueAsync(string key)
    {
        var setting = await _context.GeneralSettings.FirstOrDefaultAsync(s => s.Key == key);
        if (setting == null)
        {
            throw new InvalidOperationException($"Setting with key '{key}' not found.");
        }

        return setting.Value;
    }
}

