using System.ComponentModel.DataAnnotations;

namespace SimpleTestsDemo.Core.Models;

public class Product
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }
    
    public string Description { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
}
