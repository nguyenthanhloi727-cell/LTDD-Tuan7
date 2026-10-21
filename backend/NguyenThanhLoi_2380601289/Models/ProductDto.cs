namespace NguyenThanhLoi_2380601289.Models
{
    // Du lieu tra ve cho GET san pham: co them ten danh muc, khong co navigation -> khong vong lap JSON.
    public class ProductDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string? Description { get; set; }
        public string? ImageUrl { get; set; }
        public int? CategoryId { get; set; }
        public string? CategoryName { get; set; }
    }
}
