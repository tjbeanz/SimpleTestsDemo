using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using SimpleTestsDemo.Core.Interfaces;
using SimpleTestsDemo.Core.Models;
using SimpleTestsDemo.Core.Repositories;
using System.Net;
using System.Net.Http.Json;

namespace SimpleTestsDemo.IntegrationTests;

public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    private static readonly InMemoryProductRepository SharedRepository = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Remove the existing repository registration
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(IProductRepository));

            if (descriptor != null)
            {
                services.Remove(descriptor);
            }

            // Add the shared repository
            services.AddSingleton<IProductRepository>(SharedRepository);
        });

        builder.UseEnvironment("Testing");
    }
}

public class ProductsControllerIntegrationTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public ProductsControllerIntegrationTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task GetAllProducts_ShouldReturnOkWithProducts()
    {
        // Act
        var response = await _client.GetAsync("/api/products");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var products = await response.Content.ReadFromJsonAsync<Product[]>();
        Assert.NotNull(products);
        Assert.NotEmpty(products);
        Assert.True(products.Length > 0); // Should have seed data
    }

    [Fact]
    public async Task GetProductById_WithValidId_ShouldReturnProduct()
    {
        // Arrange - First, get all products to find a valid ID
        var allProductsResponse = await _client.GetAsync("/api/products");
        var allProducts = await allProductsResponse.Content.ReadFromJsonAsync<Product[]>();
        var firstProduct = allProducts!.First();

        // Act
        var response = await _client.GetAsync($"/api/products/{firstProduct.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var product = await response.Content.ReadFromJsonAsync<Product>();
        Assert.NotNull(product);
        Assert.Equal(firstProduct.Id, product.Id);
        Assert.Equal(firstProduct.Name, product.Name);
    }

    [Fact]
    public async Task GetProductById_WithInvalidId_ShouldReturnNotFound()
    {
        // Arrange
        var invalidId = 99999;

        // Act
        var response = await _client.GetAsync($"/api/products/{invalidId}");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetProductById_WithZeroId_ShouldReturnBadRequest()
    {
        // Act
        var response = await _client.GetAsync("/api/products/0");

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateProduct_WithValidProduct_ShouldReturnCreated()
    {
        // Arrange
        var newProduct = new Product
        {
            Name = "Test Product",
            Price = 19.99m,
            Description = "A test product for integration testing"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/products", newProduct);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var createdProduct = await response.Content.ReadFromJsonAsync<Product>();
        Assert.NotNull(createdProduct);
        Assert.True(createdProduct.Id > 0);
        Assert.Equal(newProduct.Name, createdProduct.Name);
        Assert.Equal(newProduct.Price, createdProduct.Price);
        Assert.Equal(newProduct.Description, createdProduct.Description);
        Assert.True((DateTime.UtcNow - createdProduct.CreatedAt).TotalMinutes < 1);
        Assert.True(createdProduct.IsActive);

        // Verify Location header
        Assert.NotNull(response.Headers.Location);
        Assert.Contains($"/api/Products/{createdProduct.Id}", response.Headers.Location!.PathAndQuery); // Note: ASP.NET Core uses Pascal case in URLs
    }

    [Fact]
    public async Task CreateProduct_WithInvalidProduct_ShouldReturnBadRequest()
    {
        // Arrange
        var invalidProduct = new Product
        {
            Name = "", // Invalid: empty name
            Price = -10.00m, // Invalid: negative price
            Description = "Invalid product"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/products", invalidProduct);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateProduct_WithValidData_ShouldReturnOk()
    {
        // Arrange - Create a product first
        var newProduct = new Product
        {
            Name = "Original Product",
            Price = 25.00m,
            Description = "Original description"
        };

        var createResponse = await _client.PostAsJsonAsync("/api/products", newProduct);
        var createdProduct = await createResponse.Content.ReadFromJsonAsync<Product>();

        var updatedProduct = new Product
        {
            Name = "Updated Product",
            Price = 30.00m,
            Description = "Updated description",
            IsActive = true
        };

        // Act
        var response = await _client.PutAsJsonAsync($"/api/products/{createdProduct!.Id}", updatedProduct);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var result = await response.Content.ReadFromJsonAsync<Product>();
        Assert.NotNull(result);
        Assert.Equal(createdProduct.Id, result.Id);
        Assert.Equal(updatedProduct.Name, result.Name);
        Assert.Equal(updatedProduct.Price, result.Price);
        Assert.Equal(updatedProduct.Description, result.Description);
        Assert.Equal(createdProduct.CreatedAt, result.CreatedAt); // Should preserve original creation time
    }

    [Fact]
    public async Task DeleteProduct_WithValidId_ShouldReturnNoContent()
    {
        // Arrange - Create a product first
        var newProduct = new Product
        {
            Name = "Product To Delete",
            Price = 15.00m,
            Description = "This product will be deleted"
        };

        var createResponse = await _client.PostAsJsonAsync("/api/products", newProduct);
        var createdProduct = await createResponse.Content.ReadFromJsonAsync<Product>();

        // Act
        var response = await _client.DeleteAsync($"/api/products/{createdProduct!.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify the product is deleted
        var getResponse = await _client.GetAsync($"/api/products/{createdProduct.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);
    }

    [Fact]
    public async Task SearchProducts_WithValidTerm_ShouldReturnMatchingProducts()
    {
        // Arrange
        var searchTerm = "laptop";

        // Act
        var response = await _client.GetAsync($"/api/products/search?searchTerm={searchTerm}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var products = await response.Content.ReadFromJsonAsync<Product[]>();
        Assert.NotNull(products);
        
        // Should contain products with "laptop" in name or description (case-insensitive)
        if (products!.Any())
        {
            Assert.All(products, p => 
                Assert.True(p.Name.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) ||
                           p.Description.Contains(searchTerm, StringComparison.OrdinalIgnoreCase)));
        }
    }

    [Fact]
    public async Task GetTotalValue_ShouldReturnCorrectCalculation()
    {
        // Act
        var response = await _client.GetAsync("/api/products/total-value");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var result = await response.Content.ReadAsStringAsync();
        Assert.False(string.IsNullOrEmpty(result));
        Assert.Contains("totalValue", result);
        
        // Parse JSON to verify structure
        var jsonResult = System.Text.Json.JsonDocument.Parse(result);
        Assert.True(jsonResult.RootElement.TryGetProperty("totalValue", out var totalValueElement));
        Assert.True(totalValueElement.GetDecimal() > 0);
    }

    [Fact]
    public async Task GetActiveProducts_ShouldReturnOnlyActiveProducts()
    {
        // Act
        var response = await _client.GetAsync("/api/products/active");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var products = await response.Content.ReadFromJsonAsync<Product[]>();
        Assert.NotNull(products);
        
        if (products!.Any())
        {
            Assert.All(products, p => Assert.True(p.IsActive));
        }
    }

    [Fact]
    public async Task FullWorkflow_CreateUpdateSearchDelete_ShouldWorkCorrectly()
    {
        // Create
        var newProduct = new Product
        {
            Name = "Workflow Test Product",
            Price = 99.99m,
            Description = "Product for testing complete workflow"
        };

        var createResponse = await _client.PostAsJsonAsync("/api/products", newProduct);
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        
        var createdProduct = await createResponse.Content.ReadFromJsonAsync<Product>();
        Assert.NotNull(createdProduct);

        // Search
        var searchResponse = await _client.GetAsync("/api/products/search?searchTerm=Workflow");
        Assert.Equal(HttpStatusCode.OK, searchResponse.StatusCode);
        
        var searchResults = await searchResponse.Content.ReadFromJsonAsync<Product[]>();
        Assert.Contains(searchResults!, p => p.Id == createdProduct!.Id);

        // Update
        var updatedProduct = new Product
        {
            Name = "Updated Workflow Product",
            Price = 149.99m,
            Description = "Updated product description",
            IsActive = true
        };

        var updateResponse = await _client.PutAsJsonAsync($"/api/products/{createdProduct!.Id}", updatedProduct);
        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);

        // Get updated product
        var getResponse = await _client.GetAsync($"/api/products/{createdProduct.Id}");
        var retrievedProduct = await getResponse.Content.ReadFromJsonAsync<Product>();
        Assert.Equal(updatedProduct.Name, retrievedProduct!.Name);
        Assert.Equal(updatedProduct.Price, retrievedProduct.Price);

        // Delete
        var deleteResponse = await _client.DeleteAsync($"/api/products/{createdProduct.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        // Verify deletion
        var getDeletedResponse = await _client.GetAsync($"/api/products/{createdProduct.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getDeletedResponse.StatusCode);
    }
}