using SimpleTestsDemo.Core.Interfaces;
using SimpleTestsDemo.Core.Models;

namespace SimpleTestsDemo.Core.Services;

public class ProductService : IProductService
{
    private readonly IProductRepository _productRepository;

    public ProductService(IProductRepository productRepository)
    {
        _productRepository = productRepository;
    }

    public async Task<IEnumerable<Product>> GetAllProductsAsync()
    {
        return await _productRepository.GetAllAsync();
    }

    public async Task<Product?> GetProductByIdAsync(int id)
    {
        if (id <= 0)
            throw new ArgumentException("Product ID must be positive", nameof(id));

        return await _productRepository.GetByIdAsync(id);
    }

    public async Task<Product> CreateProductAsync(Product product)
    {
        ArgumentNullException.ThrowIfNull(product);
        
        if (string.IsNullOrWhiteSpace(product.Name))
            throw new ArgumentException("Product name is required", nameof(product));

        if (product.Price <= 0)
            throw new ArgumentException("Product price must be positive", nameof(product));

        product.CreatedAt = DateTime.UtcNow;
        product.IsActive = true;

        return await _productRepository.CreateAsync(product);
    }

    public async Task<Product> UpdateProductAsync(int id, Product product)
    {
        ArgumentNullException.ThrowIfNull(product);

        if (id <= 0)
            throw new ArgumentException("Product ID must be positive", nameof(id));

        var existingProduct = await _productRepository.GetByIdAsync(id);
        if (existingProduct == null)
            throw new InvalidOperationException($"Product with ID {id} not found");

        product.Id = id;
        product.CreatedAt = existingProduct.CreatedAt; // Preserve original creation time

        return await _productRepository.UpdateAsync(product);
    }

    public async Task<bool> DeleteProductAsync(int id)
    {
        if (id <= 0)
            throw new ArgumentException("Product ID must be positive", nameof(id));

        return await _productRepository.DeleteAsync(id);
    }

    public async Task<IEnumerable<Product>> SearchProductsAsync(string searchTerm)
    {
        if (string.IsNullOrWhiteSpace(searchTerm))
            return await GetAllProductsAsync();

        return await _productRepository.SearchAsync(searchTerm);
    }

    public async Task<decimal> CalculateTotalValueAsync()
    {
        var products = await _productRepository.GetAllAsync();
        return products.Where(p => p.IsActive).Sum(p => p.Price);
    }

    public async Task<IEnumerable<Product>> GetActiveProductsAsync()
    {
        var allProducts = await _productRepository.GetAllAsync();
        return allProducts.Where(p => p.IsActive);
    }
}
