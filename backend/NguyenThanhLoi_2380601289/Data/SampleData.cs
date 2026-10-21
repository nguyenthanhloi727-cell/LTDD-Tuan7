using Microsoft.EntityFrameworkCore;
using NguyenThanhLoi_2380601289.Models;

namespace NguyenThanhLoi_2380601289.Data
{
    // UP10: du lieu mau de demo tren may moi (DB trong). Chi chay khi chua co san pham nao,
    // DB da co du lieu thi khong dung toi. Anh mau nam trong wwwroot/images/samples (co commit).
    public static class SampleData
    {
        public static async Task SeedAsync(ApplicationDbContext context)
        {
            if (await context.Products.AnyAsync()) return;

            var phone = await GetOrCreateCategory(context, "Điện thoại", "Smartphone các hãng");
            var laptop = await GetOrCreateCategory(context, "Laptop", "Máy tính xách tay");
            var accessory = await GetOrCreateCategory(context, "Phụ kiện", "Tai nghe, chuột, sạc...");

            context.Products.AddRange(
                new Product { Name = "iPhone 15", Price = 20990000, Quantity = 12, Category = phone,
                    Description = "Màn hình 6.1 inch, chip A16 Bionic, bộ nhớ 128GB.", ImageUrl = "/images/samples/iphone-15.png" },
                new Product { Name = "Samsung Galaxy S24", Price = 18490000, Quantity = 8, Category = phone,
                    Description = "Màn hình 6.2 inch Dynamic AMOLED, camera 50MP.", ImageUrl = "/images/samples/galaxy-s24.png" },
                new Product { Name = "MacBook Air M3", Price = 27990000, Quantity = 5, Category = laptop,
                    Description = "Chip Apple M3, RAM 8GB, SSD 256GB, màn hình 13.6 inch.", ImageUrl = "/images/samples/macbook-air-m3.png" },
                new Product { Name = "Dell XPS 13", Price = 32990000, Quantity = 0, Category = laptop,
                    Description = "Intel Core Ultra 7, RAM 16GB, SSD 512GB. Tạm hết hàng.", ImageUrl = "/images/samples/dell-xps-13.png" },
                new Product { Name = "Tai nghe Bluetooth", Price = 590000, Quantity = 30, Category = accessory,
                    Description = "Chống ồn, pin 30 giờ, sạc USB-C.", ImageUrl = "/images/samples/tai-nghe.png" },
                new Product { Name = "Chuột không dây", Price = 250000, Quantity = 50, Category = accessory,
                    Description = "Kết nối 2.4GHz, pin AA dùng 12 tháng.", ImageUrl = "/images/samples/chuot.png" }
            );
            await context.SaveChangesAsync();
        }

        private static async Task<Category> GetOrCreateCategory(ApplicationDbContext context, string name, string description)
        {
            return await context.Categories.FirstOrDefaultAsync(c => c.Name == name)
                ?? context.Categories.Add(new Category { Name = name, Description = description }).Entity;
        }
    }
}
