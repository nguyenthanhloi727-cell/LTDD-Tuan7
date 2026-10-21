using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace NguyenThanhLoi_2380601289.Models
{
    public class Category
    {
        public int Id { get; set; }

        [Required, StringLength(100)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        // 1 danh muc co nhieu san pham. JsonIgnore de tranh vong lap JSON.
        [JsonIgnore]
        public ICollection<Product> Products { get; set; } = new List<Product>();
    }
}
