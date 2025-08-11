# Copilot Instructions

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

This is a C# .NET 8 project demonstrating comprehensive testing strategies including:
- Unit tests using xUnit and FluentAssertions
- Integration tests using ASP.NET Core Test Host and Testcontainers
- Contract tests using Pact.NET for consumer-driven contract testing
- Comprehensive test reporting with multiple output formats

## Project Structure
- `SimpleTestsDemo.Api`: Web API project serving as the main application
- `SimpleTestsDemo.Core`: Business logic and domain models
- `SimpleTestsDemo.UnitTests`: Fast, isolated unit tests
- `SimpleTestsDemo.IntegrationTests`: End-to-end integration tests with real dependencies
- `SimpleTestsDemo.ContractTests`: Consumer-driven contract tests using Pact

## Testing Guidelines
- Write descriptive test names that clearly indicate what is being tested
- Use the AAA pattern (Arrange, Act, Assert) for test structure
- Prefer FluentAssertions for more readable assertions
- Mock external dependencies in unit tests
- Use real dependencies in integration tests when possible
- Generate comprehensive test reports in multiple formats (HTML, XML, JSON)
- Include test coverage metrics and trend analysis
