# SimpleTestsDemo - Comprehensive Testing Demonstration

[![CI/CD Pipeline](https://github.com/yourusername/SimpleTestsDemo/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/yourusername/SimpleTestsDemo/actions/workflows/ci-cd.yml)
[![Coverage](https://img.shields.io/badge/Coverage-Check%20Actions-blue)](https://github.com/yourusername/SimpleTestsDemo/actions)

A comprehensive C# .NET 8 demonstration project showcasing **Unit Tests**, **Integration Tests**, and **Contract Tests** with advanced reporting capabilities designed for multi-repository environments.

## 🎯 Project Overview

This project demonstrates modern testing strategies in .NET with:

- **Unit Tests**: Fast, isolated tests using xUnit, Moq, and FluentAssertions
- **Integration Tests**: End-to-end API testing with ASP.NET Core Test Host
- **Contract Tests**: Consumer-driven contract testing using Pact.NET
- **Comprehensive Reporting**: Multi-format test reports with coverage analysis
- **CI/CD Integration**: GitHub Actions workflow with cross-repository reporting capabilities

## 🏗️ Architecture

```
SimpleTestsDemo/
├── SimpleTestsDemo.Api/              # Web API project
├── SimpleTestsDemo.Core/             # Business logic and domain models
├── SimpleTestsDemo.UnitTests/        # Unit tests with mocks
├── SimpleTestsDemo.IntegrationTests/ # API integration tests
├── SimpleTestsDemo.ContractTests/    # Consumer contract tests
├── .github/workflows/               # CI/CD pipeline
└── run-tests.ps1                   # Comprehensive test runner script
```

### Key Components

- **Products API**: RESTful API for managing products with full CRUD operations
- **Business Layer**: Domain services with validation and business rules
- **Repository Pattern**: Abstracted data access with in-memory implementation
- **Dependency Injection**: Proper IoC container configuration

## 🧪 Testing Strategy

### Unit Tests (`SimpleTestsDemo.UnitTests`)

Fast, isolated tests focusing on individual components:

- **Service Layer Testing**: Business logic validation with mocked dependencies
- **Behavior Verification**: Mock interaction verification using Moq
- **Data-Driven Tests**: Parameterized tests using `[Theory]` and `[InlineData]`
- **Edge Case Coverage**: Negative scenarios and boundary conditions

**Example Test:**
```csharp
[Fact]
public async Task CreateProductAsync_WithValidProduct_ShouldCreateAndReturnProduct()
{
    // Arrange
    var newProduct = new Product { Name = "Test Product", Price = 25.99m };
    _mockRepository.Setup(r => r.CreateAsync(It.IsAny<Product>()))
                   .ReturnsAsync(expectedProduct);

    // Act
    var result = await _productService.CreateProductAsync(newProduct);

    // Assert
    result.Should().BeEquivalentTo(expectedProduct);
    result.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
}
```

### Integration Tests (`SimpleTestsDemo.IntegrationTests`)

End-to-end API testing with real HTTP requests:

- **WebApplicationFactory**: In-memory test server setup
- **HTTP Client Testing**: Real API endpoint validation
- **Database Integration**: Tests with actual data persistence (when configured)
- **Workflow Testing**: Complete user scenarios from request to response

**Example Test:**
```csharp
[Fact]
public async Task CreateProduct_WithValidProduct_ShouldReturnCreated()
{
    // Arrange
    var newProduct = new Product { Name = "Test Product", Price = 19.99m };

    // Act
    var response = await _client.PostAsJsonAsync("/api/products", newProduct);

    // Assert
    response.StatusCode.Should().Be(HttpStatusCode.Created);
    var createdProduct = await response.Content.ReadFromJsonAsync<Product>();
    createdProduct.Should().NotBeNull();
}
```

### Contract Tests (`SimpleTestsDemo.ContractTests`)

Consumer-driven contract testing using Pact.NET:

- **API Contract Verification**: Ensures API contracts are maintained
- **Consumer-Provider Contracts**: Documents expected API interactions
- **Pact File Generation**: Creates shareable contract specifications
- **Contract Evolution**: Supports API versioning and backward compatibility

**Example Test:**
```csharp
[Fact]
public async Task GetAllProducts_ShouldReturnProductList()
{
    // Arrange
    _pactBuilder
        .UponReceiving("a request to get all products")
        .Given("products exist")
        .WithRequest(HttpMethod.Get, "/api/products")
        .WillRespond()
        .WithStatus(HttpStatusCode.OK)
        .WithJsonBody(Match.MinType(new[] { /* expected structure */ }, 1));

    await _pactBuilder.VerifyAsync(async ctx =>
    {
        // Act & Assert
        var response = await _httpClient.GetAsync("/api/products");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    });
}
```

## 📊 Test Reporting

### Comprehensive Reports

The project generates multiple report formats suitable for different audiences:

1. **HTML Reports**: Visual, interactive coverage reports
2. **JSON Reports**: Machine-readable for CI/CD integration
3. **XML Reports**: Compatible with most CI/CD tools (Cobertura, TRX)
4. **Markdown Reports**: Documentation-friendly summaries
5. **Badge Generation**: Coverage and test status badges

### Cross-Repository Reporting

Perfect for organizations with multiple repositories:

- **Centralized Reporting**: Aggregates results from multiple projects
- **Historical Tracking**: Trend analysis across releases
- **Team Dashboards**: Executive summaries and developer metrics
- **Integration Ready**: Works with popular tools (Codecov, SonarQube, etc.)

## 🚀 Getting Started

### Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [PowerShell Core](https://github.com/PowerShell/PowerShell) (for advanced test runner)
- [Git](https://git-scm.com/) (for version control)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/SimpleTestsDemo.git
   cd SimpleTestsDemo
   ```

2. **Restore dependencies:**
   ```bash
   dotnet restore
   ```

3. **Build the solution:**
   ```bash
   dotnet build
   ```

4. **Run all tests:**
   ```bash
   ./run-tests.ps1
   ```

### Running Individual Test Suites

```bash
# Unit Tests only
dotnet test SimpleTestsDemo.UnitTests

# Integration Tests only  
dotnet test SimpleTestsDemo.IntegrationTests

# Contract Tests only
dotnet test SimpleTestsDemo.ContractTests
```

### Advanced Test Execution

The `run-tests.ps1` script provides advanced options:

```powershell
# Run with coverage report generation
./run-tests.ps1 -GenerateReports -OpenResults

# Skip specific test types
./run-tests.ps1 -SkipIntegrationTests -SkipContractTests

# Custom output directory
./run-tests.ps1 -OutputDir "MyTestResults"

# Debug mode with detailed logging
./run-tests.ps1 -Configuration Debug -LogLevel Detailed
```

## 🔧 Configuration

### Test Settings

Key configuration files:
- `.runsettings`: Test execution configuration
- `xunit.runner.json`: xUnit-specific settings  
- `appsettings.Test.json`: Test environment configuration

### CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) provides:

- **Automated Testing**: Runs on every push and PR
- **Multi-Environment Support**: Staging and production deployments
- **Artifact Management**: Stores test results and reports
- **PR Comments**: Automatic test result summaries
- **Coverage Tracking**: Integration with coverage services

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CONFIGURATION` | Build configuration | `Release` |
| `DOTNET_VERSION` | .NET version | `8.0.x` |
| `TEST_OUTPUT_DIR` | Test results directory | `TestResults` |

## 📈 Reporting Features

### Coverage Reports

Generated reports include:

- **Line Coverage**: Percentage of code lines executed
- **Branch Coverage**: Conditional logic coverage analysis  
- **Method Coverage**: Function-level coverage metrics
- **Class Coverage**: Type-level coverage summary

### Test Result Analysis

- **Execution Time**: Performance tracking for test suites
- **Failure Analysis**: Detailed error reporting and trends
- **Flaky Test Detection**: Identifies unstable tests
- **Historical Comparison**: Tracks improvements over time

### Cross-Repository Integration

For multi-repository environments:

1. **Shared Reporting**: Aggregate results from multiple projects
2. **Team Metrics**: Organization-wide testing insights  
3. **Quality Gates**: Enforce testing standards across repositories
4. **Compliance Reporting**: Generate audit-friendly reports

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add or update tests as needed
5. Run the full test suite (`./run-tests.ps1`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Testing Guidelines

- Maintain high test coverage (>90%)
- Write descriptive test names
- Follow the AAA pattern (Arrange, Act, Assert)
- Use FluentAssertions for readable assertions
- Mock external dependencies in unit tests
- Test both happy path and edge cases

## 📚 Resources

### Testing Best Practices

- [Unit Testing Best Practices](https://docs.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices)
- [Integration Testing in ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/test/integration-tests)
- [Consumer-Driven Contract Testing](https://martinfowler.com/articles/consumerDrivenContracts.html)

### Tools and Libraries

- [xUnit](https://xunit.net/) - Testing framework
- [FluentAssertions](https://fluentassertions.com/) - Assertion library
- [Moq](https://github.com/moq/moq) - Mocking framework
- [Pact.NET](https://github.com/pact-foundation/pact-net) - Contract testing
- [Testcontainers](https://www.testcontainers.org/) - Integration testing with containers

### Reporting Tools

- [ReportGenerator](https://github.com/danielpalme/ReportGenerator) - Coverage reports
- [Codecov](https://about.codecov.io/) - Coverage tracking service
- [SonarQube](https://www.sonarqube.org/) - Code quality analysis

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♀️ Support

For questions, issues, or contributions:

- Create an [Issue](https://github.com/yourusername/SimpleTestsDemo/issues)
- Start a [Discussion](https://github.com/yourusername/SimpleTestsDemo/discussions)
- Contact the maintainers

---

## 📊 Project Status

- ✅ Unit Tests Implementation
- ✅ Integration Tests Implementation  
- ✅ Contract Tests Implementation
- ✅ Comprehensive Reporting
- ✅ CI/CD Pipeline
- ✅ Cross-Repository Support
- ✅ Documentation

**Ready for production use and customization!** 🚀
