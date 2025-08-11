using Moq;
using SimpleTestsDemo.Core.Interfaces;
using SimpleTestsDemo.Core.Models;
using SimpleTestsDemo.Core.Services;

namespace SimpleTestsDemo.UnitTests;

public class ProductServiceTests
{
    private readonly Mock<IProductRepository> _mockRepository;
    private readonly ProductService _productService;

    public ProductServiceTests()
    {
        _mockRepository = new Mock<IProductRepository>();
        _productService = new ProductService(_mockRepository.Object);
    }

    [Fact]
    public async Task GetAllProductsAsync_ShouldReturnAllProducts()
    {
        // Arrange
        var expectedProducts = new[]
        {
            new Product { Id = 1, Name = "Product 1", Price = 10.99m, IsActive = true },
            new Product { Id = 2, Name = "Product 2", Price = 20.99m, IsActive = true }
        };

        _mockRepository.Setup(r => r.GetAllAsync())
                       .ReturnsAsync(expectedProducts);

        // Act
        var result = await _productService.GetAllProductsAsync();

        // Assert
        Assert.NotNull(result);
        Assert.Equal(expectedProducts.Length, result.Count());
        Assert.Equal(expectedProducts[0].Id, result.First().Id);
        Assert.Equal(expectedProducts[0].Name, result.First().Name);
        _mockRepository.Verify(r => r.GetAllAsync(), Times.Once);
    }

    [Fact]
    public async Task GetProductByIdAsync_WithValidId_ShouldReturnProduct()
    {
        // Arrange
        var productId = 1;
        var expectedProduct = new Product { Id = productId, Name = "Test Product", Price = 15.99m };

        _mockRepository.Setup(r => r.GetByIdAsync(productId))
                       .ReturnsAsync(expectedProduct);

        // Act
        var result = await _productService.GetProductByIdAsync(productId);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(expectedProduct.Id, result.Id);
        Assert.Equal(expectedProduct.Name, result.Name);
        Assert.Equal(expectedProduct.Price, result.Price);
        _mockRepository.Verify(r => r.GetByIdAsync(productId), Times.Once);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(-100)]
    public async Task GetProductByIdAsync_WithInvalidId_ShouldThrowArgumentException(int invalidId)
    {
        // Act & Assert
        var exception = await Assert.ThrowsAsync<ArgumentException>(
            () => _productService.GetProductByIdAsync(invalidId));

        Assert.Contains("Product ID must be positive", exception.Message);
        Assert.Equal("id", exception.ParamName);
    }

    [Fact]
    public async Task CreateProductAsync_WithValidProduct_ShouldCreateAndReturnProduct()
    {
        // Arrange
        var newProduct = new Product
        {
            Name = "New Product",
            Price = 25.99m,
            Description = "A great product"
        };

        var expectedProduct = new Product
        {
            Id = 1,
            Name = newProduct.Name,
            Price = newProduct.Price,
            Description = newProduct.Description,
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };

        _mockRepository.Setup(r => r.CreateAsync(It.IsAny<Product>()))
                       .ReturnsAsync(expectedProduct);

        // Act
        var result = await _productService.CreateProductAsync(newProduct);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(expectedProduct.Id, result.Id);
        Assert.Equal(expectedProduct.Name, result.Name);
        Assert.Equal(expectedProduct.Price, result.Price);
        Assert.True((DateTime.UtcNow - result.CreatedAt).TotalSeconds < 1);
        Assert.True(result.IsActive);

        _mockRepository.Verify(r => r.CreateAsync(It.Is<Product>(p => 
            p.Name == newProduct.Name && 
            p.Price == newProduct.Price &&
            p.IsActive == true &&
            p.CreatedAt != default(DateTime))), Times.Once);
    }

    [Fact]
    public async Task CreateProductAsync_WithNullProduct_ShouldThrowArgumentNullException()
    {
        // Act & Assert
        await Assert.ThrowsAsync<ArgumentNullException>(
            () => _productService.CreateProductAsync(null!));
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public async Task CreateProductAsync_WithInvalidName_ShouldThrowArgumentException(string invalidName)
    {
        // Arrange
        var product = new Product
        {
            Name = invalidName,
            Price = 10.99m
        };

        // Act & Assert
        var exception = await Assert.ThrowsAsync<ArgumentException>(
            () => _productService.CreateProductAsync(product));

        Assert.Contains("Product name is required", exception.Message);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(-0.01)]
    public async Task CreateProductAsync_WithInvalidPrice_ShouldThrowArgumentException(decimal invalidPrice)
    {
        // Arrange
        var product = new Product
        {
            Name = "Valid Name",
            Price = invalidPrice
        };

        // Act & Assert
        var exception = await Assert.ThrowsAsync<ArgumentException>(
            () => _productService.CreateProductAsync(product));

        Assert.Contains("Product price must be positive", exception.Message);
    }

    [Fact]
    public async Task CalculateTotalValueAsync_ShouldReturnSumOfActivePrices()
    {
        // Arrange
        var products = new[]
        {
            new Product { Id = 1, Price = 10.00m, IsActive = true },
            new Product { Id = 2, Price = 20.00m, IsActive = true },
            new Product { Id = 3, Price = 15.00m, IsActive = false }, // Should be excluded
            new Product { Id = 4, Price = 5.00m, IsActive = true }
        };

        _mockRepository.Setup(r => r.GetAllAsync())
                       .ReturnsAsync(products);

        // Act
        var result = await _productService.CalculateTotalValueAsync();

        // Assert
        Assert.Equal(35.00m, result); // 10 + 20 + 5 (excluding inactive product)
    }

    [Fact]
    public async Task GetActiveProductsAsync_ShouldReturnOnlyActiveProducts()
    {
        // Arrange
        var allProducts = new[]
        {
            new Product { Id = 1, Name = "Active 1", IsActive = true },
            new Product { Id = 2, Name = "Inactive 1", IsActive = false },
            new Product { Id = 3, Name = "Active 2", IsActive = true }
        };

        var expectedActiveProducts = new[]
        {
            new Product { Id = 1, Name = "Active 1", IsActive = true },
            new Product { Id = 3, Name = "Active 2", IsActive = true }
        };

        _mockRepository.Setup(r => r.GetAllAsync())
                       .ReturnsAsync(allProducts);

        // Act
        var result = await _productService.GetActiveProductsAsync();

        // Assert
        Assert.NotNull(result);
        var resultList = result.ToList();
        Assert.Equal(2, resultList.Count);
        Assert.All(resultList, p => Assert.True(p.IsActive));
        Assert.Equal(expectedActiveProducts[0].Id, resultList[0].Id);
        Assert.Equal(expectedActiveProducts[1].Id, resultList[1].Id);
    }

    [Fact]
    public async Task SearchProductsAsync_WithValidSearchTerm_ShouldCallRepository()
    {
        // Arrange
        var searchTerm = "laptop";
        var expectedResults = new[]
        {
            new Product { Id = 1, Name = "Gaming Laptop", Price = 999.99m }
        };

        _mockRepository.Setup(r => r.SearchAsync(searchTerm))
                       .ReturnsAsync(expectedResults);

        // Act
        var result = await _productService.SearchProductsAsync(searchTerm);

        // Assert
        Assert.NotNull(result);
        var resultList = result.ToList();
        Assert.Equal(expectedResults.Length, resultList.Count);
        Assert.Equal(expectedResults[0].Id, resultList[0].Id);
        Assert.Equal(expectedResults[0].Name, resultList[0].Name);
        _mockRepository.Verify(r => r.SearchAsync(searchTerm), Times.Once);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public async Task SearchProductsAsync_WithEmptySearchTerm_ShouldReturnAllProducts(string emptySearchTerm)
    {
        // Arrange
        var allProducts = new[]
        {
            new Product { Id = 1, Name = "Product 1" },
            new Product { Id = 2, Name = "Product 2" }
        };

        _mockRepository.Setup(r => r.GetAllAsync())
                       .ReturnsAsync(allProducts);

        // Act
        var result = await _productService.SearchProductsAsync(emptySearchTerm);

        // Assert
        Assert.NotNull(result);
        var resultList = result.ToList();
        Assert.Equal(allProducts.Length, resultList.Count);
        Assert.Equal(allProducts[0].Id, resultList[0].Id);
        Assert.Equal(allProducts[1].Id, resultList[1].Id);
        _mockRepository.Verify(r => r.GetAllAsync(), Times.Once);
        _mockRepository.Verify(r => r.SearchAsync(It.IsAny<string>()), Times.Never);
    }
}