import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


class TestAuthenticationSecurity:
    """Test authentication security features."""
    
    @pytest.mark.asyncio
    async def test_password_validation(self, client: AsyncClient):
        """Test password strength validation."""
        # Test weak passwords
        weak_passwords = [
            ("short", "Password too short"),
            ("nouppercase123", "Password must contain uppercase"),
            ("NOLOWERCASE123", "Password must contain lowercase"),
            ("NoDigits!", "Password must contain digit"),
        ]
        
        for password, _ in weak_passwords:
            response = await client.post(
                "/api/v1/auth/signup/?set_cookie=false",
                json={
                    "username": "testuser",
                    "email": "test@example.com",
                    "password": password,
                    "confirm_password": password
                }
            )
            assert response.status_code == 422  # Validation error
    
    @pytest.mark.asyncio
    async def test_duplicate_username_prevention(self, client: AsyncClient, db_session: AsyncSession):
        """Test that duplicate usernames are prevented."""
        user_data = {
            "username": "duplicate_test",
            "email": "user1@example.com",
            "password": "SecurePass123",
            "confirm_password": "SecurePass123"
        }
        
        # First signup should succeed
        response1 = await client.post(
            "/api/v1/auth/signup/?set_cookie=false",
            json=user_data
        )
        assert response1.status_code == 200
        
        # Second signup with same username should fail
        user_data["email"] = "user2@example.com"
        response2 = await client.post(
            "/api/v1/auth/signup/?set_cookie=false",
            json=user_data
        )
        assert response2.status_code == 400
        assert "already registered" in response2.json()["detail"].lower()
    
    @pytest.mark.asyncio
    async def test_invalid_token_rejection(self, client: AsyncClient):
        """Test that invalid tokens are rejected."""
        invalid_token = "invalid.token.value"
        headers = {"Authorization": f"Bearer {invalid_token}"}
        
        response = await client.post("/api/v1/auth/logout/", headers=headers)
        assert response.status_code in [401, 403]
