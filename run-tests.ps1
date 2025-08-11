<#
.SYNOPSIS
    Comprehensive test execution and reporting script for SimpleTestsDemo
.DESCRIPTION
    This script runs unit tests, integration tests, and contract tests with comprehensive reporting.
    It generates multiple report formats and can be used in CI/CD pipelines.
#>

param(
    [string]$Configuration = "Release",
    [string]$OutputDir = "TestResults",
    [switch]$SkipBuild,
    [switch]$SkipUnitTests,
    [switch]$SkipIntegrationTests,
    [switch]$SkipContractTests,
    [switch]$GenerateReports = $false,
    [switch]$OpenResults,
    [string]$LogLevel = "Information"
)

# Ensure output directory exists
$outputPath = Join-Path $PSScriptRoot $OutputDir
if (!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

Write-Host "🚀 Starting SimpleTestsDemo Test Suite" -ForegroundColor Green
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Output Directory: $outputPath" -ForegroundColor Yellow
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Build solution
if (!$SkipBuild) {
    Write-Host "🔨 Building solution..." -ForegroundColor Blue
    dotnet build --configuration $Configuration --verbosity minimal
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Build failed"
        exit 1
    }
    Write-Host "✅ Build completed successfully" -ForegroundColor Green
    Write-Host ""
}

# Initialize test results tracking
$testResults = @{
    UnitTests = @{ Passed = 0; Failed = 0; Skipped = 0; Duration = "00:00:00" }
    IntegrationTests = @{ Passed = 0; Failed = 0; Skipped = 0; Duration = "00:00:00" }
    ContractTests = @{ Passed = 0; Failed = 0; Skipped = 0; Duration = "00:00:00" }
}

# Function to extract test results from TRX file
function Get-TestResultsFromTrx {
    param([string]$TrxFile)
    
    if (!(Test-Path $TrxFile)) {
        return @{ Passed = 0; Failed = 0; Skipped = 0; Duration = "00:00:00" }
    }
    
    try {
        [xml]$trx = Get-Content $TrxFile
        $counters = $trx.TestRun.ResultSummary.Counters
        
        return @{
            Passed = [int]$counters.passed
            Failed = [int]$counters.failed
            Skipped = ([int]$counters.inconclusive + [int]$counters.notExecuted)
            Duration = $trx.TestRun.Times.finish.Subtract($trx.TestRun.Times.start).ToString("hh\:mm\:ss")
        }
    }
    catch {
        Write-Warning "Failed to parse TRX file: $TrxFile"
        return @{ Passed = 0; Failed = 0; Skipped = 0; Duration = "00:00:00" }
    }
}

# Run Unit Tests
if (!$SkipUnitTests) {
    Write-Host "🧪 Running Unit Tests..." -ForegroundColor Blue
    $unitTestsOutputPath = Join-Path $outputPath "UnitTests"
    
    dotnet test SimpleTestsDemo.UnitTests/SimpleTestsDemo.UnitTests.csproj `
        --configuration $Configuration `
        --logger "trx;LogFileName=UnitTests.trx" `
        --logger "html;LogFileName=UnitTests.html" `
        --logger "json;LogFileName=UnitTests.json" `
        --results-directory $unitTestsOutputPath `
        --collect:"XPlat Code Coverage" `
        --verbosity $LogLevel `
        -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover
    
    $testResults.UnitTests = Get-TestResultsFromTrx (Join-Path $unitTestsOutputPath "UnitTests.trx")
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Unit tests completed successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Unit tests completed with failures" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Run Integration Tests
if (!$SkipIntegrationTests) {
    Write-Host "🔗 Running Integration Tests..." -ForegroundColor Blue
    $integrationTestsOutputPath = Join-Path $outputPath "IntegrationTests"
    
    dotnet test SimpleTestsDemo.IntegrationTests/SimpleTestsDemo.IntegrationTests.csproj `
        --configuration $Configuration `
        --logger "trx;LogFileName=IntegrationTests.trx" `
        --logger "html;LogFileName=IntegrationTests.html" `
        --logger "json;LogFileName=IntegrationTests.json" `
        --results-directory $integrationTestsOutputPath `
        --collect:"XPlat Code Coverage" `
        --verbosity $LogLevel `
        -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover
    
    $testResults.IntegrationTests = Get-TestResultsFromTrx (Join-Path $integrationTestsOutputPath "IntegrationTests.trx")
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Integration tests completed successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Integration tests completed with failures" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Run Contract Tests
if (!$SkipContractTests) {
    Write-Host "🤝 Running Contract Tests..." -ForegroundColor Blue
    $contractTestsOutputPath = Join-Path $outputPath "ContractTests"
    
    dotnet test SimpleTestsDemo.ContractTests/SimpleTestsDemo.ContractTests.csproj `
        --configuration $Configuration `
        --logger "trx;LogFileName=ContractTests.trx" `
        --logger "html;LogFileName=ContractTests.html" `
        --logger "json;LogFileName=ContractTests.json" `
        --results-directory $contractTestsOutputPath `
        --verbosity $LogLevel
    
    $testResults.ContractTests = Get-TestResultsFromTrx (Join-Path $contractTestsOutputPath "ContractTests.trx")
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Contract tests completed successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Contract tests completed with failures" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Generate Coverage Reports
if ($GenerateReports) {
    Write-Host "📊 Generating Coverage Reports..." -ForegroundColor Blue
    
    # Find all coverage files
    $coverageFiles = Get-ChildItem -Path $outputPath -Recurse -Filter "coverage.cobertura.xml" -ErrorAction SilentlyContinue
    
    if ($coverageFiles.Count -gt 0) {
        $reportOutputPath = Join-Path $outputPath "CoverageReport"
        
        # Check if ReportGenerator is available
        $reportGeneratorExists = $false
        try {
            dotnet tool list --global | Select-String "reportgenerator" | Out-Null
            if ($?) { $reportGeneratorExists = $true }
        }
        catch {
            # Try to install ReportGenerator if not available
            Write-Host "Installing ReportGenerator tool..." -ForegroundColor Yellow
            dotnet tool install --global dotnet-reportgenerator-globaltool --ignore-failed-sources
            if ($LASTEXITCODE -eq 0) { $reportGeneratorExists = $true }
        }
        
        if ($reportGeneratorExists) {
            # Generate HTML coverage report
            $coverageArgs = @()
            foreach ($file in $coverageFiles) {
                $coverageArgs += "-reports:$($file.FullName)"
            }
            
            & dotnet reportgenerator $coverageArgs "-targetdir:$reportOutputPath" "-reporttypes:Html;Cobertura;JsonSummary;Badges;TextSummary"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Coverage reports generated successfully" -ForegroundColor Green
                Write-Host "📁 Coverage report location: $reportOutputPath/index.html" -ForegroundColor Cyan
            }
            else {
                Write-Host "⚠️ Coverage report generation had issues" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "⚠️ ReportGenerator tool not available - skipping coverage reports" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "⚠️ No coverage files found" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Generate Summary Report
Write-Host "📋 Test Results Summary" -ForegroundColor Magenta
Write-Host "========================" -ForegroundColor Magenta

$totalPassed = $testResults.UnitTests.Passed + $testResults.IntegrationTests.Passed + $testResults.ContractTests.Passed
$totalFailed = $testResults.UnitTests.Failed + $testResults.IntegrationTests.Failed + $testResults.ContractTests.Failed
$totalSkipped = $testResults.UnitTests.Skipped + $testResults.IntegrationTests.Skipped + $testResults.ContractTests.Skipped
$totalTests = $totalPassed + $totalFailed + $totalSkipped

Write-Host "📊 Overall Results:"
Write-Host "   Total Tests: $totalTests"
Write-Host "   ✅ Passed: $totalPassed"
Write-Host "   ❌ Failed: $totalFailed"
Write-Host "   ⏭️ Skipped: $totalSkipped"
Write-Host ""

Write-Host "📋 Detailed Results:"
Write-Host "   🧪 Unit Tests: $($testResults.UnitTests.Passed)/$($testResults.UnitTests.Passed + $testResults.UnitTests.Failed + $testResults.UnitTests.Skipped) passed ($($testResults.UnitTests.Duration))"
Write-Host "   🔗 Integration Tests: $($testResults.IntegrationTests.Passed)/$($testResults.IntegrationTests.Passed + $testResults.IntegrationTests.Failed + $testResults.IntegrationTests.Skipped) passed ($($testResults.IntegrationTests.Duration))"
Write-Host "   🤝 Contract Tests: $($testResults.ContractTests.Passed)/$($testResults.ContractTests.Passed + $testResults.ContractTests.Failed + $testResults.ContractTests.Skipped) passed ($($testResults.ContractTests.Duration))"
Write-Host ""

# Generate JSON Summary for CI/CD
$summary = @{
    timestamp = Get-Date -Format "o"
    configuration = $Configuration
    overall = @{
        totalTests = $totalTests
        passed = $totalPassed
        failed = $totalFailed
        skipped = $totalSkipped
        successRate = if ($totalTests -gt 0) { [math]::Round(($totalPassed / $totalTests) * 100, 2) } else { 0 }
    }
    details = $testResults
    artifacts = @{
        outputDirectory = $outputPath
        coverageReport = if (Test-Path (Join-Path $outputPath "CoverageReport/index.html")) { Join-Path $outputPath "CoverageReport/index.html" } else { $null }
    }
}

$summaryJson = $summary | ConvertTo-Json -Depth 4
$summaryPath = Join-Path $outputPath "test-summary.json"
$summaryJson | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Host "💾 Test summary saved to: $summaryPath" -ForegroundColor Cyan

# Open results if requested
if ($OpenResults -and (Test-Path (Join-Path $outputPath "CoverageReport/index.html"))) {
    Write-Host "🌐 Opening coverage report..." -ForegroundColor Blue
    Start-Process (Join-Path $outputPath "CoverageReport/index.html")
}

# Set exit code based on test results
if ($totalFailed -gt 0) {
    Write-Host "❌ Some tests failed. Check the detailed reports for more information." -ForegroundColor Red
    exit 1
} else {
    Write-Host "🎉 All tests passed successfully!" -ForegroundColor Green
    exit 0
}
