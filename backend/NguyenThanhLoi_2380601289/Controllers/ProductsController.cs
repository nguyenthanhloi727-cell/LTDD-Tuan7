using System.Linq.Expressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenThanhLoi_2380601289.Data;
using NguyenThanhLoi_2380601289.Models;

namespace NguyenThanhLoi_2380601289.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize] // GET: chi can dang nhap (User hoac Admin)
    public class ProductsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ProductsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // Product -> ProductDto (EF dich thanh LEFT JOIN, khong co danh muc thi CategoryName = null).
        private static readonly Expression<Func<Product, ProductDto>> ToDto = p => new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            Price = p.Price,
            Description = p.Description,
            ImageUrl = p.ImageUrl,
            Quantity = p.Quantity,
            CategoryId = p.CategoryId,
            CategoryName = p.Category != null ? p.Category.Name : null
        };

        // categoryId null = chua phan loai (hop le); co gia tri thi phai co trong bang Categories.
        // Khong kiem truoc thi SQL loi khoa ngoai -> 500.
        private async Task<bool> CategoryExists(int? categoryId)
        {
            return categoryId == null || await _context.Categories.AnyAsync(c => c.Id == categoryId);
        }

        // GET: api/Products
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ProductDto>>> GetProducts()
        {
            return await _context.Products.Select(ToDto).ToListAsync();
        }

        // GET: api/Products/5
        [HttpGet("{id}")]
        public async Task<ActionResult<ProductDto>> GetProduct(int id)
        {
            var product = await _context.Products
                .Where(p => p.Id == id)
                .Select(ToDto)
                .FirstOrDefaultAsync();
            if (product == null)
            {
                return NotFound();
            }
            return product;
        }

        // POST: api/Products
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<Product>> PostProduct(Product product)
        {
            if (!await CategoryExists(product.CategoryId))
            {
                return BadRequest(new { message = "Danh mục không tồn tại" });
            }

            _context.Products.Add(product);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
        }

        // PUT: api/Products/5
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> PutProduct(int id, Product product)
        {
            if (id != product.Id)
            {
                return BadRequest();
            }
            if (!await CategoryExists(product.CategoryId))
            {
                return BadRequest(new { message = "Danh mục không tồn tại" });
            }

            _context.Entry(product).State = EntityState.Modified;
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await _context.Products.AnyAsync(p => p.Id == id))
                {
                    return NotFound();
                }
                throw;
            }
            return NoContent();
        }

        // POST: api/Products/upload-image  (form-data, key "file")
        // UP10: luu anh vao wwwroot/uploads/products, tra ve duong dan de gan vao Product.ImageUrl.
        // Backend phuc vu file tinh qua app.UseStaticFiles() (Program.cs).
        [HttpPost("upload-image")]
        [Authorize(Roles = "Admin")]
        [RequestSizeLimit(MaxImageBytes + 1024 * 1024)]
        public async Task<IActionResult> UploadImage(IFormFile file, [FromServices] IWebHostEnvironment env)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Chưa chọn file ảnh" });
            if (file.Length > MaxImageBytes)
                return BadRequest(new { message = "Ảnh tối đa 5 MB" });

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!AllowedImageExtensions.Contains(ext))
                return BadRequest(new { message = "Chỉ nhận ảnh .jpg, .jpeg, .png, .webp, .gif" });

            // Ten file moi = Guid: khong trung, khong de nguoi dung dat ten file/duong dan
            var webRoot = env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot");
            var folder = Path.Combine(webRoot, "uploads", "products");
            Directory.CreateDirectory(folder);
            var fileName = $"{Guid.NewGuid():N}{ext}";

            await using (var stream = System.IO.File.Create(Path.Combine(folder, fileName)))
            {
                await file.CopyToAsync(stream);
            }

            return Ok(new { url = $"/uploads/products/{fileName}" });
        }

        private const long MaxImageBytes = 5 * 1024 * 1024;
        private static readonly string[] AllowedImageExtensions = { ".jpg", ".jpeg", ".png", ".webp", ".gif" };

        // DELETE: api/Products/5
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null)
            {
                return NotFound();
            }

            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
