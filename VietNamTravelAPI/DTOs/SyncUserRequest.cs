using Microsoft.AspNetCore.Mvc;

namespace VietNamTravelAPI.DTOs
{
    public class SyncUserRequest
    {
        public string UserId { get; set; }
        public string Email { get; set; }
        public string FullName { get; set; }
    }
}