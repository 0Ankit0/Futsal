using System.Data;
using System.Linq.Expressions;

using Dapper;


using FutsalApi.Data.Models;
using FutsalApi.Data.DTO;

using Microsoft.EntityFrameworkCore;

namespace FutsalApi.ApiService.Repositories;

public class ReviewRepository : GenericRepository<Review>, IReviewRepository
{
    private readonly FutsalApi.Data.DTO.AppDbContext _dbContext;
    private readonly IDbConnection _dbConnection;

    public ReviewRepository(FutsalApi.Data.DTO.AppDbContext dbContext, IDbConnection dbConnection) : base(dbContext)
    {
        _dbContext = dbContext;
        _dbConnection = dbConnection;
    }

    public async Task<IEnumerable<ReviewResponse>> GetAllByUserAsync(string userId, int page = 1, int pageSize = 10)
    {
        if (string.IsNullOrEmpty(userId))
            throw new ArgumentNullException(nameof(userId));
        if (page <= 0 || pageSize <= 0)
            throw new ArgumentOutOfRangeException("Page and pageSize must be greater than 0.");

        return await _dbContext.Reviews
            .Include(r => r.Image)
            .Include(r => r.Ground)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new ReviewResponse
            {
                Id = r.Id,
                UserId = r.UserId,
                GroundId = r.GroundId,
                GroundName = r.Ground.Name,
                GroundImageUrl = r.Ground.ImageUrl,
                Rating = r.Rating,
                UserName = r.User.UserName ?? string.Empty,
                UserImageId = r.User.ProfileImageId,
                ReviewImageId = r.ImageId,
                ReviewImageUrl = r.Image != null ? r.Image.FilePath : null,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt
            })
            .ToListAsync();
    }

    public new async Task<ReviewResponse?> GetByIdAsync(Expression<Func<Review, bool>> predicate)
    {
        var review = await _dbContext.Reviews
            .Include(r => r.Image)
            .Include(r => r.Ground)
            .Where(predicate)
            .Select(r => new ReviewResponse
            {
                Id = r.Id,
                UserId = r.UserId,
                GroundId = r.GroundId,
                GroundName = r.Ground.Name,
                GroundImageUrl = r.Ground.ImageUrl,
                Rating = r.Rating,
                UserName = r.User.UserName ?? string.Empty,
                UserImageId = r.User.ProfileImageId,
                ReviewImageId = r.ImageId,
                ReviewImageUrl = r.Image != null ? r.Image.FilePath : null,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt
            })
            .FirstOrDefaultAsync();

        return review;
    }

    public async Task<IEnumerable<ReviewResponse>> GetReviewsByGroundIdAsync(int groundId, int page = 1, int pageSize = 10)
    {
        if (page <= 0 || pageSize <= 0)
        {
            throw new ArgumentOutOfRangeException("Page and pageSize must be greater than 0.");
        }

        return await _dbContext.Reviews
            .Include(r => r.Image)
            .Include(r => r.Ground)
            .Where(r => r.GroundId == groundId)
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new ReviewResponse
            {
                Id = r.Id,
                UserId = r.UserId,
                GroundId = r.GroundId,
                GroundName = r.Ground.Name,
                GroundImageUrl = r.Ground.ImageUrl,
                Rating = r.Rating,
                UserName = r.User.UserName ?? string.Empty,
                UserImageId = r.User.ProfileImageId,
                ReviewImageId = r.ImageId,
                ReviewImageUrl = r.Image != null ? r.Image.FilePath : null,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<bool> DeleteReviewByUserAsync(int reviewId, string userId)
    {
        var parameters = new { p_review_id = reviewId, p_user_id = userId };
        return await _dbConnection.ExecuteScalarAsync<bool>(
            "SELECT delete_review_by_user(@p_review_id, @p_user_id)",
            parameters,
            commandType: CommandType.Text);
    }

    public async Task<int> CreateReviewAsync(Review review)
    {
        var parameters = new
        {
            p_user_id = review.UserId,
            p_ground_id = review.GroundId,
            p_rating = review.Rating,
            p_comment = review.Comment,
            p_image_id = review.ImageId
        };
        return await _dbConnection.ExecuteScalarAsync<int>(
            "SELECT create_review(@p_user_id, @p_ground_id, @p_rating, @p_comment, @p_image_id)",
            parameters,
            commandType: CommandType.Text);
    }

    public async Task UpdateReviewAsync(Review review)
    {
        var parameters = new
        {
            p_review_id = review.Id,
            p_user_id = review.UserId,
            p_rating = review.Rating,
            p_comment = review.Comment,
            p_image_id = review.ImageId
        };

        await _dbConnection.ExecuteAsync("update_review", parameters, commandType: CommandType.StoredProcedure);
    }
}
