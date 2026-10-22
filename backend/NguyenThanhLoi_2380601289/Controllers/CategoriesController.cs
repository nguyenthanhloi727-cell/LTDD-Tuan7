using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenThanhLoi_2380601289.Data;
using NguyenThanhLoi_2380601289.Models;

namespace NguyenThanhLoi_2380601289.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize] // GET: chi can dang nhap (moi role)
    public class CategoriesController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public CategoriesController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/Categories
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories()
        {
            return await _context.Categories.OrderBy(c => c.Name).ToListAsync();
        }

        // GET: api/Categories/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Category>> GetCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
            {
                return NotFound();
            }
            return category;
        }

        // POST: api/Categories
        [HttpPost]
        [Authorize(Roles = AppRoles.ManageProducts)]
        public async Task<ActionResult<Category>> PostCategory(Category category)
        {
            category.Id = 0; // de SQL Server tu sinh Id
            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, category);
        }

        // PUT: api/Categories/5
        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.ManageProducts)]
        public async Task<IActionResult> PutCategory(int id, Category category)
        {
            if (id != category.Id)
            {
                return BadRequest();
            }

            var existing = await _context.Categories.FindAsync(id);
            if (existing == null)
            {
                return NotFound();
            }

            existing.Name = category.Name;
            existing.Description = category.Description;
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/Categories/5
        // Khong xoa san pham: FK cau hinh OnDelete(SetNull) nen CategoryId cua san pham thanh NULL.
        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.ManageProducts)]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
            {
                return NotFound();
            }

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
