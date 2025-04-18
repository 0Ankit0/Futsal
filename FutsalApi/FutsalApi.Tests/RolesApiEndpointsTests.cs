﻿using System.Security.Claims;
using FutsalApi.ApiService.Data;
using FutsalApi.ApiService.Routes;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Moq;
using Xunit;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace FutsalApi.Tests;

public class RolesApiEndpointsTests
{
    private readonly Mock<RoleManager<Role>> _roleManagerMock;
    private readonly RolesApiEndpoints _endpoints;

    public RolesApiEndpointsTests()
    {
        _roleManagerMock = MockRoleManager();
        _endpoints = new RolesApiEndpoints();
    }

    [Fact]
    public async Task GetAllRoles_ReturnsOk_WhenRolesExist()
    {
        // Arrange
        var roles = new List<Role>
        {
            new Role { Id = "1", Name = "Admin" },
            new Role { Id = "2", Name = "User" }
        }.AsQueryable();

        _roleManagerMock.Setup(r => r.Roles).Returns(roles);

        // Act
        var result = await _endpoints.GetAllRoles(_roleManagerMock.Object);

        // Assert
        result.Should().BeOfType<Results<Ok<List<Role>>, ProblemHttpResult>>();
        if (result is Results<Ok<List<Role>>, ProblemHttpResult> { Result: Ok<List<Role>> okResult })
        {
            okResult.Value.Should().BeEquivalentTo(roles.ToList());
        }
    }

    [Fact]
    public async Task GetRoleById_ReturnsOk_WhenRoleExists()
    {
        // Arrange
        var role = new Role { Id = "1", Name = "Admin" };
        _roleManagerMock.Setup(r => r.FindByIdAsync("1")).ReturnsAsync(role);

        // Act
        var result = await _endpoints.GetRoleById(_roleManagerMock.Object, "1");

        // Assert
        result.Should().BeOfType<Results<Ok<Role>, ProblemHttpResult>>();
        if (result is Results<Ok<Role>, ProblemHttpResult> { Result: Ok<Role> okResult })
        {
            okResult.Value.Should().BeEquivalentTo(role);
        }
    }

    [Fact]
    public async Task GetRoleById_ReturnsProblem_WhenRoleDoesNotExist()
    {
        // Arrange
        _roleManagerMock.Setup(r => r.FindByIdAsync("1")).ReturnsAsync((Role?)null);

        // Act
        var result = await _endpoints.GetRoleById(_roleManagerMock.Object, "1");

        // Assert
        result.Should().BeOfType<Results<Ok<Role>, ProblemHttpResult>>();
        if (result is Results<Ok<Role>, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("Role with ID 1 not found.");
        }
    }

    [Fact]
    public async Task CreateRole_ReturnsOk_WhenRoleIsCreated()
    {
        // Arrange
        var role = new Role { Name = "Admin" };
        _roleManagerMock.Setup(r => r.CreateAsync(role)).ReturnsAsync(IdentityResult.Success);

        // Act
        var result = await _endpoints.CreateRole(_roleManagerMock.Object, role);

        // Assert
        result.Should().BeOfType<Results<Ok<Role>, ProblemHttpResult>>();
        if (result is Results<Ok<Role>, ProblemHttpResult> { Result: Ok<Role> okResult })
        {
            okResult.Value.Should().BeEquivalentTo(role);
        }
    }

    [Fact]
    public async Task CreateRole_ReturnsProblem_WhenCreationFails()
    {
        // Arrange
        var role = new Role { Name = "Admin" };
        _roleManagerMock.Setup(r => r.CreateAsync(role)).ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Error creating role" }));

        // Act
        var result = await _endpoints.CreateRole(_roleManagerMock.Object, role);

        // Assert
        result.Should().BeOfType<Results<Ok<Role>, ProblemHttpResult>>();
        if (result is Results<Ok<Role>, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("Failed to create role: Error creating role");
        }
    }

    [Fact]
    public async Task UpdateRole_ReturnsOk_WhenRoleIsUpdated()
    {
        // Arrange
        var existingRole = new Role { Id = "1", Name = "Admin" };
        var updatedRole = new Role { Name = "SuperAdmin" };

        _roleManagerMock.Setup(r => r.FindByIdAsync("1")).ReturnsAsync(existingRole);
        _roleManagerMock.Setup(r => r.UpdateAsync(existingRole)).ReturnsAsync(IdentityResult.Success);

        // Act
        var result = await _endpoints.UpdateRole(_roleManagerMock.Object, "1", updatedRole);

        // Assert
        result.Should().BeOfType<Results<Ok<Role>, ProblemHttpResult>>();
        if (result is Results<Ok<Role>, ProblemHttpResult> { Result: Ok<Role> okResult })
        {
            okResult.Value.Name.Should().Be("SuperAdmin");
        }
    }

    [Fact]
    public async Task UpdateRole_ReturnsProblem_WhenRoleDoesNotExist()
    {
        // Arrange
        _roleManagerMock.Setup(r => r.FindByIdAsync("1")).ReturnsAsync((Role?)null);

        // Act
        var result = await _endpoints.UpdateRole(_roleManagerMock.Object, "1", new Role { Name = "Admin" });

        // Assert
        result.Should().BeOfType<Results<Ok<Role>, ProblemHttpResult>>();
        if (result is Results<Ok<Role>, ProblemHttpResult> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("Role with ID 1 not found.");
        }
    }

    [Fact]
    public async Task DeleteRole_ReturnsOk_WhenRoleIsDeleted()
    {
        // Arrange
        var role = new Role { Id = "1", Name = "Admin" };
        _roleManagerMock.Setup(r => r.FindByIdAsync("1")).ReturnsAsync(role);
        _roleManagerMock.Setup(r => r.DeleteAsync(role)).ReturnsAsync(IdentityResult.Success);

        // Act
        var result = await _endpoints.DeleteRole(_roleManagerMock.Object, "1");

        // Assert
        result.Should().BeOfType<Results<Ok, ProblemHttpResult, NotFound>>();
        if (result is Results<Ok, ProblemHttpResult, NotFound> { Result: Ok })
        {
            result.Result.Should().BeOfType<Ok>();
        }
    }

    [Fact]
    public async Task DeleteRole_ReturnsProblem_WhenRoleDoesNotExist()
    {
        // Arrange
        _roleManagerMock.Setup(r => r.FindByIdAsync("1")).ReturnsAsync((Role?)null);

        // Act
        var result = await _endpoints.DeleteRole(_roleManagerMock.Object, "1");

        // Assert
        result.Should().BeOfType<Results<Ok, ProblemHttpResult, NotFound>>();
        if (result is Results<Ok, ProblemHttpResult, NotFound> { Result: ProblemHttpResult problemResult })
        {
            problemResult.ProblemDetails.Detail.Should().Be("Role with ID 1 not found.");
        }
    }

    private static Mock<RoleManager<Role>> MockRoleManager()
    {
        var roleStoreMock = new Mock<IRoleStore<Role>>();
        var roleValidators = new List<IRoleValidator<Role>>(); // Empty list of role validators
        var lookupNormalizerMock = new Mock<ILookupNormalizer>();
        var identityErrorDescriber = new IdentityErrorDescriber();
        var loggerMock = new Mock<ILogger<RoleManager<Role>>>();

        return new Mock<RoleManager<Role>>(
            roleStoreMock.Object,
            roleValidators,
            lookupNormalizerMock.Object,
            identityErrorDescriber,
            loggerMock.Object
        );
    }
}
