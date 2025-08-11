using SimpleTestsDemo.Core.Interfaces;
using SimpleTestsDemo.Core.Models;
using System.Collections.Concurrent;

namespace SimpleTestsDemo.Core.Repositories;

public class InMemoryProductRepository : IProductRepository
{
    private readonly ConcurrentDictionary<int, Product> _products = new();
    private int _nextId = 1;

    public InMemoryProductRepository()
    {
        // Seed with sample data
        SeedData();
    }

    public Task<IEnumerable<Product>> GetAllAsync()
    {
        return Task.FromResult(_products.Values.AsEnumerable());
    }

    public Task<Product?> GetByIdAsync(int id)
    {
        _products.TryGetValue(id, out var product);
        return Task.FromResult(product);
    }

    public Task<Product> CreateAsync(Product product)
    {
        product.Id = _nextId++;
        _products[product.Id] = product;
        return Task.FromResult(product);
    }

    public Task<Product> UpdateAsync(Product product)
    {
        _products[product.Id] = product;
        return Task.FromResult(product);
    }

    public Task<bool> DeleteAsync(int id)
    {
        return Task.FromResult(_products.TryRemove(id, out _));
    }

    public Task<IEnumerable<Product>> SearchAsync(string searchTerm)
    {
        var results = _products.Values
            .Where(p => p.Name.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) ||
                       p.Description.Contains(searchTerm, StringComparison.OrdinalIgnoreCase))
            .AsEnumerable();
        
        return Task.FromResult(results);
    }

    private void SeedData()
    {
        var products = new[]
        {
            new Product { Name = "Laptop", Price = 999.99m, Description = "High-performance laptop", CreatedAt = DateTime.UtcNow.AddDays(-30) },
            new Product { Name = "Mouse", Price = 29.99m, Description = "Wireless mouse", CreatedAt = DateTime.UtcNow.AddDays(-20) },
            new Product { Name = "Keyboard", Price = 79.99m, Description = "Mechanical keyboard", CreatedAt = DateTime.UtcNow.AddDays(-15) },
            new Product { Name = "Monitor", Price = 299.99m, Description = "24-inch display", CreatedAt = DateTime.UtcNow.AddDays(-10) },
            new Product { Name = "Headphones", Price = 149.99m, Description = "Noise-cancelling headphones", CreatedAt = DateTime.UtcNow.AddDays(-5) }
        };

        foreach (var product in products)
        {
            CreateAsync(product);
        }
    }
}
