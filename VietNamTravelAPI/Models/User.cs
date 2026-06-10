namespace VietNamTravelAPI.Models
{
    public class User
    {
        public string UserId { get; set; } 
        public string Email { get; set; }
        public string FullName { get; set; }
        public string Role { get; set; }
        public bool IsBanned { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
