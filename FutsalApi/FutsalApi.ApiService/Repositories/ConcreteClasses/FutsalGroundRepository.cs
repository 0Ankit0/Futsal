using System;
using System.Linq.Expressions;

using FutsalApi.ApiService.Data;
using FutsalApi.ApiService.Models;

using Microsoft.EntityFrameworkCore;

namespace FutsalApi.ApiService.Repositories;

public class FutsalGroundRepository : GenericRepository<FutsalGround>, IFutsalGroundRepository
{
    private readonly AppDbContext _dbContext;
    public FutsalGroundRepository(AppDbContext dbContext) : base(dbContext)
    {
        _dbContext = dbContext;
    }
    public async new Task<IEnumerable<FutsalGroundResponse>> GetAllAsync(int page = 1, int pageSize = 10)
    {
        if (page <= 0 || pageSize <= 0)
        {
            throw new ArgumentOutOfRangeException("Page and pageSize must be greater than 0.");
        }

        return await _dbContext.FutsalGrounds
            .OrderByDescending(g => g.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(g => new FutsalGroundResponse
            {
                Id = g.Id,
                Name = g.Name,
                Location = g.Location,
                OwnerId = g.OwnerId,
                PricePerHour = g.PricePerHour,
                OpenTime = g.OpenTime,
                CloseTime = g.CloseTime,
                CreatedAt = g.CreatedAt,
                OwnerName = g.Owner.UserName!
            })
            .ToListAsync();
    }
    public async new Task<FutsalGroundResponse?> GetByIdAsync(Expression<Func<FutsalGround, bool>> predicate)
    {
        return await _dbContext.FutsalGrounds
            .Where(predicate)
            .Select(g => new FutsalGroundResponse
            {
                Id = g.Id,
                Name = g.Name,
                Location = g.Location,
                OwnerId = g.OwnerId,
                PricePerHour = g.PricePerHour,
                OpenTime = g.OpenTime,
                CloseTime = g.CloseTime,
                CreatedAt = g.CreatedAt,
                OwnerName = g.Owner.UserName!
            })
            .FirstOrDefaultAsync();
    }

}
