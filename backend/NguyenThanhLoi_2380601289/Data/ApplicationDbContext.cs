using Microsoft.EntityFrameworkCore;
using NguyenThanhLoi_2380601289.Models;

namespace NguyenThanhLoi_2380601289.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Product> Products { get; set; }
    }
}
