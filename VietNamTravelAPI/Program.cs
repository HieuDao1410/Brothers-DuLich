using Microsoft.EntityFrameworkCore;
using VietNamTravelAPI.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// 2. ��ng k? AppDbContext v�o h? th?ng v?i c?u h?nh Pomelo MySQL
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySql(
        connectionString,
        ServerVersion.AutoDetect(connectionString)
    )
);

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Phục vụ tệp tĩnh trong wwwroot (ảnh địa danh tại /images/...)
app.UseStaticFiles();

app.UseAuthorization();

app.MapControllers();

app.Run();
