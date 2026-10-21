using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using NguyenThanhLoi_2380601289.Data;
using NguyenThanhLoi_2380601289.Models;

var builder = WebApplication.CreateBuilder(args);

// May nao co SQLEXPRESS thi dung, khong co thi chuyen sang LocalDB (di kem Visual Studio)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")!;
if (!CanConnectToServer(connectionString))
{
    connectionString = builder.Configuration.GetConnectionString("LocalDbConnection")!;
    Console.WriteLine("Khong ket noi duoc SQLEXPRESS, chuyen sang LocalDB");
}

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// Identity: quan ly User va Role
builder.Services.AddIdentity<User, IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

// JWT: kiem tra token gui len trong header Authorization: Bearer <token>
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.SaveToken = true;
    options.RequireHttpsMetadata = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["JWT:ValidIssuer"],
        ValidAudience = builder.Configuration["JWT:ValidAudience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["JWT:Secret"]!))
    };
    // Token dung chu ky van bi tu choi (401) neu: user khong con, dang bi khoa,
    // hoac claim "stamp" khac SecurityStamp trong DB (Admin da thu hoi / khoa).
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var userManager = context.HttpContext.RequestServices
                .GetRequiredService<UserManager<User>>();
            var username = context.Principal?.Identity?.Name;
            var user = username == null ? null : await userManager.FindByNameAsync(username);
            if (user == null)
            {
                context.Fail("Tài khoản không tồn tại");
                return;
            }
            if (await userManager.IsLockedOutAsync(user))
            {
                context.Fail("Tài khoản đã bị khóa");
                return;
            }
            var stamp = context.Principal!.FindFirst("stamp")?.Value;
            if (stamp != await userManager.GetSecurityStampAsync(user))
                context.Fail("Token đã bị thu hồi");
        }
    };
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Swagger co nut Authorize de nhap Bearer token
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Dán token (không cần gõ chữ Bearer)"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

// Cho phep app Flutter goi API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

// Tu tao/cap nhat database theo migration + seed 2 role Admin va User neu chua co
using (var scope = app.Services.CreateScope())
{
    scope.ServiceProvider.GetRequiredService<ApplicationDbContext>().Database.Migrate();

    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
    foreach (var role in new[] { "Admin", "User" })
    {
        if (!await roleManager.RoleExistsAsync(role))
            await roleManager.CreateAsync(new IdentityRole(role));
    }

    // Chua co ai la Admin thi tao 1 tai khoan Admin tu muc AdminAccount trong appsettings.json
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
    if ((await userManager.GetUsersInRoleAsync("Admin")).Count == 0)
    {
        var adminConfig = app.Configuration.GetSection("AdminAccount");
        var admin = new User
        {
            UserName = adminConfig["Username"],
            Email = adminConfig["Email"],
            Initials = "AD",
            SecurityStamp = Guid.NewGuid().ToString()
        };
        var result = await userManager.CreateAsync(admin, adminConfig["Password"]!);
        if (result.Succeeded)
            await userManager.AddToRoleAsync(admin, "Admin");
        else
            Console.WriteLine("Khong tao duoc tai khoan Admin: " +
                string.Join("; ", result.Errors.Select(e => e.Description)));
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

// Thu mo ket noi toi SQL Server (vao DB master) trong 3 giay
static bool CanConnectToServer(string connectionString)
{
    var csb = new SqlConnectionStringBuilder(connectionString)
    {
        InitialCatalog = "master",
        ConnectTimeout = 3
    };
    try
    {
        using var conn = new SqlConnection(csb.ConnectionString);
        conn.Open();
        return true;
    }
    catch
    {
        return false;
    }
}
