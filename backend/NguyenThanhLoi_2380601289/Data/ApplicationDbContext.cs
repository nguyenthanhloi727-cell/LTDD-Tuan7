using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using NguyenThanhLoi_2380601289.Models;

namespace NguyenThanhLoi_2380601289.Data
{
    public class ApplicationDbContext : IdentityDbContext<User>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Product> Products { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            // Phai goi base de Identity tao cac bang AspNetUsers, AspNetRoles...
            base.OnModelCreating(builder);
            builder.HasDefaultSchema("identity");
        }
    }
}
