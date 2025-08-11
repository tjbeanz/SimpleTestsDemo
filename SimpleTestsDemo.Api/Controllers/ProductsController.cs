using Microsoft.AspNetCore.Mvc;
using SimpleTestsDemo.Core.Interfaces;
using SimpleTestsDemo.Core.Models;

namespace SimpleTestsDemo.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(IProductService productService, ILogger<ProductsController> logger)
    {
        _productService = productService;
        _logger = logger;
    }

    /// <summary>
    /// Gets all products
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetAllProducts()
    {
        try
        {
            var products = await _productService.GetAllProductsAsync();
            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving all products");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Gets a product by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<Product>> GetProduct(int id)
    {
        try
        {
            var product = await _productService.GetProductByIdAsync(id);
            if (product == null)
                return NotFound();

            return Ok(product);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving product {ProductId}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Creates a new product
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<Product>> CreateProduct(Product product)
    {
        try
        {
            var createdProduct = await _productService.CreateProductAsync(product);
            return CreatedAtAction(nameof(GetProduct), new { id = createdProduct.Id }, createdProduct);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Updates an existing product
    /// </summary>
    [HttpPut("{id}")]
    public async Task<ActionResult<Product>> UpdateProduct(int id, Product product)
    {
        try
        {
            var updatedProduct = await _productService.UpdateProductAsync(id, product);
            return Ok(updatedProduct);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (InvalidOperationException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating product {ProductId}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Deletes a product
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteProduct(int id)
    {
        try
        {
            var deleted = await _productService.DeleteProductAsync(id);
            if (!deleted)
                return NotFound();

            return NoContent();
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting product {ProductId}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Searches products by name or description
    /// </summary>
    [HttpGet("search")]
    public async Task<ActionResult<IEnumerable<Product>>> SearchProducts([FromQuery] string searchTerm)
    {
        try
        {
            var products = await _productService.SearchProductsAsync(searchTerm);
            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error searching products with term {SearchTerm}", searchTerm);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Gets the total value of all active products
    /// </summary>
    [HttpGet("total-value")]
    public async Task<ActionResult<decimal>> GetTotalValue()
    {
        try
        {
            var totalValue = await _productService.CalculateTotalValueAsync();
            return Ok(new { TotalValue = totalValue });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calculating total value");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Gets only active products
    /// </summary>
    [HttpGet("active")]
    public async Task<ActionResult<IEnumerable<Product>>> GetActiveProducts()
    {
        try
        {
            var products = await _productService.GetActiveProductsAsync();
            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving active products");
            return StatusCode(500, "Internal server error");
        }
    }
}
