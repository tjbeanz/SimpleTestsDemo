using PactNet;
using PactNet.Matchers;
using SimpleTestsDemo.Core.Models;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace SimpleTestsDemo.ContractTests;

public class ProductApiConsumerTests : IDisposable
{
    private readonly IPactBuilderV3 _pactBuilder;
    private readonly HttpClient _httpClient;
    
    public ProductApiConsumerTests()
    {
        // Configure Pact with more explicit settings
        var pact = Pact.V3("Product Consumer", "Product API", new PactConfig
        {
            PactDir = Path.Combine(Environment.CurrentDirectory, "pacts"),
            DefaultJsonSettings = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                PropertyNameCaseInsensitive = true
            }
        });
        
        _pactBuilder = pact.WithHttpInteractions();
        _httpClient = new HttpClient();
    }

    [Fact]
    public async Task GetAllProducts_ShouldReturnProductList()
    {
        // Arrange - Define expected API contract
        _pactBuilder
            .UponReceiving("a request to get all products")
            .Given("products exist")
            .WithRequest(HttpMethod.Get, "/api/products")
            .WillRespond()
            .WithStatus(HttpStatusCode.OK)
            .WithHeader("Content-Type", "application/json; charset=utf-8")
            .WithJsonBody(new[]
            {
                new
                {
                    id = 1,
                    name = "Sample Product",
                    price = 29.99,
                    description = "Sample description",
                    createdAt = "2023-01-01T00:00:00Z",
                    isActive = true
                }
            });

        // Act & Assert - Verify the contract works
        // Act & Assert - Verify the contract works
        await _pactBuilder.VerifyAsync(async ctx =>
        {
            // Configure HttpClient to use the mock server
            _httpClient.BaseAddress = ctx.MockServerUri;
            
            // Make the request to the mock server
            var response = await _httpClient.GetAsync("/api/products");

            // Verify the response matches our expectations
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            
            // Test that we can deserialize the JSON to our model
            var content = await response.Content.ReadAsStringAsync();
            Assert.False(string.IsNullOrEmpty(content));
            
            // Basic JSON structure validation
            var products = await response.Content.ReadFromJsonAsync<Product[]>();
            Assert.NotNull(products);
            Assert.NotEmpty(products);
            Assert.True(products[0].Id > 0);
            Assert.False(string.IsNullOrEmpty(products[0].Name));
            Assert.True(products[0].Price > 0);
        });
    }

    [Fact]
    public async Task GetProductById_WithValidId_ShouldReturnProduct()
    {
        // Arrange
        var productId = 1;
        _pactBuilder
            .UponReceiving("a request to get a product by ID")
            .Given($"product with id {productId} exists")
            .WithRequest(HttpMethod.Get, $"/api/products/{productId}")
            .WillRespond()
            .WithStatus(HttpStatusCode.OK)
            .WithHeader("Content-Type", "application/json; charset=utf-8")
            .WithJsonBody(new
            {
                Id = Match.Integer(productId),
                Name = Match.Type("Gaming Laptop"),
                Price = Match.Decimal(999.99m),
                Description = Match.Type("High-performance gaming laptop"),
                CreatedAt = Match.Type(DateTime.UtcNow.ToString("O")),
                IsActive = Match.Type(true)
            });

        await _pactBuilder.VerifyAsync(async ctx =>
        {
            // Act
            _httpClient.BaseAddress = ctx.MockServerUri;
            var response = await _httpClient.GetAsync($"/api/products/{productId}");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            
            var product = await response.Content.ReadFromJsonAsync<Product>();
            Assert.NotNull(product);
            Assert.Equal(productId, product.Id);
            Assert.False(string.IsNullOrEmpty(product.Name));
            Assert.True(product.Price > 0);
        });
    }

    [Fact]
    public async Task GetProductById_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = 99999;
        _pactBuilder
            .UponReceiving("a request to get a non-existent product")
            .Given($"product with id {nonExistentId} does not exist")
            .WithRequest(HttpMethod.Get, $"/api/products/{nonExistentId}")
            .WillRespond()
            .WithStatus(HttpStatusCode.NotFound);

        await _pactBuilder.VerifyAsync(async ctx =>
        {
            // Act
            _httpClient.BaseAddress = ctx.MockServerUri;
            var response = await _httpClient.GetAsync($"/api/products/{nonExistentId}");

            // Assert
            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        });
    }

    [Fact]
    public async Task CreateProduct_WithValidProduct_ShouldReturnCreated()
    {
        // Arrange
        var newProduct = new
        {
            Name = "New Test Product",
            Price = 149.99m,
            Description = "A new product created via contract test",
            IsActive = true
        };

        _pactBuilder
            .UponReceiving("a request to create a new product")
            .Given("the API is available")
            .WithRequest(HttpMethod.Post, "/api/products")
            .WithHeader("Content-Type", "application/json")
            .WithJsonBody(newProduct)
            .WillRespond()
            .WithStatus(HttpStatusCode.Created)
            .WithHeader("Content-Type", "application/json; charset=utf-8")
            .WithHeader("Location", Match.Regex(@"\/api\/products\/\d+", "/api/products/123"))
            .WithJsonBody(new
            {
                Id = Match.Integer(123),
                Name = Match.Type(newProduct.Name),
                Price = Match.Decimal(newProduct.Price),
                Description = Match.Type(newProduct.Description),
                CreatedAt = Match.Type(DateTime.UtcNow.ToString("O")),
                IsActive = Match.Type(true)
            });

        await _pactBuilder.VerifyAsync(async ctx =>
        {
            // Act
            _httpClient.BaseAddress = ctx.MockServerUri;
            var response = await _httpClient.PostAsJsonAsync("/api/products", newProduct);

            // Assert
            Assert.Equal(HttpStatusCode.Created, response.StatusCode);
            Assert.NotNull(response.Headers.Location);
            Assert.Matches(@"\/api\/products\/\d+", response.Headers.Location!.PathAndQuery);
            
            var createdProduct = await response.Content.ReadFromJsonAsync<Product>();
            Assert.NotNull(createdProduct);
            Assert.True(createdProduct.Id > 0);
            Assert.Equal(newProduct.Name, createdProduct.Name);
            Assert.Equal(newProduct.Price, createdProduct.Price);
            Assert.True(createdProduct.IsActive);
        });
    }

    [Fact]
    public async Task CreateProduct_WithInvalidProduct_ShouldReturnBadRequest()
    {
        // Arrange
        var invalidProduct = new
        {
            Name = "", // Invalid: empty name
            Price = -10.0m, // Invalid: negative price
            Description = "Invalid product"
        };

        _pactBuilder
            .UponReceiving("a request to create an invalid product")
            .Given("the API is available")
            .WithRequest(HttpMethod.Post, "/api/products")
            .WithHeader("Content-Type", "application/json")
            .WithJsonBody(invalidProduct)
            .WillRespond()
            .WithStatus(HttpStatusCode.BadRequest);

        await _pactBuilder.VerifyAsync(async ctx =>
        {
            // Act
            _httpClient.BaseAddress = ctx.MockServerUri;
            var response = await _httpClient.PostAsJsonAsync("/api/products", invalidProduct);

            // Assert
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        });
    }

    [Fact]
    public async Task UpdateProduct_WithValidData_ShouldReturnOk()
    {
        // Arrange
        var productId = 1;
        var updatedProduct = new
        {
            Name = "Updated Product Name",
            Price = 199.99m,
            Description = "Updated product description",
            IsActive = true
        };

        _pactBuilder
            .UponReceiving("a request to update an existing product")
            .Given($"product with id {productId} exists")
            .WithRequest(HttpMethod.Put, $"/api/products/{productId}")
            .WithHeader("Content-Type", "application/json")
            .WithJsonBody(updatedProduct)
            .WillRespond()
            .WithStatus(HttpStatusCode.OK)
            .WithHeader("Content-Type", "application/json; charset=utf-8")
            .WithJsonBody(new
            {
                Id = Match.Integer(productId),
                Name = Match.Type(updatedProduct.Name),
                Price = Match.Decimal(updatedProduct.Price),
                Description = Match.Type(updatedProduct.Description),
                CreatedAt = Match.Type(DateTime.UtcNow.AddDays(-1).ToString("O")),
                IsActive = Match.Type(true)
            });

        await _pactBuilder.VerifyAsync(async ctx =>
        {
            // Act
            _httpClient.BaseAddress = ctx.MockServerUri;
            var response = await _httpClient.PutAsJsonAsync($"/api/products/{productId}", updatedProduct);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            
            var result = await response.Content.ReadFromJsonAsync<Product>();
            Assert.NotNull(result);
            Assert.Equal(productId, result.Id);
            Assert.Equal(updatedProduct.Name, result.Name);
            Assert.Equal(updatedProduct.Price, result.Price);
        });
    }

    [Fact]
    public async Task DeleteProduct_WithValidId_ShouldReturnNoContent()
    {
        // Arrange
        var productId = 1;
        _pactBuilder
            .UponReceiving("a request to delete an existing product")
            .Given($"product with id {productId} exists")
            .WithRequest(HttpMethod.Delete, $"/api/products/{productId}")
            .WillRespond()
            .WithStatus(HttpStatusCode.NoContent);

        await _pactBuilder.VerifyAsync(async ctx =>
        {
            // Act
            _httpClient.BaseAddress = ctx.MockServerUri;
            var response = await _httpClient.DeleteAsync($"/api/products/{productId}");

            // Assert
            Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        });
    }

    [Fact]
    public async Task SearchProducts_ShouldReturnMatchingProducts()
    {
        // Arrange
        var searchTerm = "laptop";
        _pactBuilder
            .UponReceiving("a request to search products")
            .Given("products matching search term exist")
            .WithRequest(HttpMethod.Get, "/api/products/search")
            .WithQuery("searchTerm", searchTerm)
            .WillRespond()
            .WithStatus(HttpStatusCode.OK)
            .WithHeader("Content-Type", "application/json; charset=utf-8")
            .WithJsonBody(new[]
            {
                new
                {
                    Id = Match.Integer(1),
                    Name = Match.Type("Gaming Laptop"),
                    Price = Match.Decimal(999.99m),
                    Description = Match.Type("High-performance gaming laptop"),
                    CreatedAt = Match.Type(DateTime.UtcNow.ToString("O")),
                    IsActive = Match.Type(true)
                }
            }); // Changed from MinType with 0 to just an array

        await _pactBuilder.VerifyAsync(async ctx =>
        {
            // Act
            _httpClient.BaseAddress = ctx.MockServerUri;
            var response = await _httpClient.GetAsync($"/api/products/search?searchTerm={searchTerm}");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            
            var products = await response.Content.ReadFromJsonAsync<Product[]>();
            Assert.NotNull(products);
        });
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}