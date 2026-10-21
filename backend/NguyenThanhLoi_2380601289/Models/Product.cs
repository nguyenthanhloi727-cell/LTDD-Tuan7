using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace NguyenThanhLoi_2380601289.Models
{
    public class Product
    {
        public int Id { get; set; }

        [Required, StringLength(200)]
        public string Name { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        public string? Description { get; set; }

        public string? ImageUrl { get; set; }

        // Cho phep NULL: san pham chua phan loai, hoac danh muc da bi xoa.
        public int? CategoryId { get; set; }

        [JsonIgnore]
        public Category? Category { get; set; }
    }
}
