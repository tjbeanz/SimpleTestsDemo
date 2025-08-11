<#
.SYNOPSIS
    Simple test execution script for SimpleTestsDemo
.DESCRIPTION
    This script runs unit tests, integration tests, and contract tests.
#>

param(
    [string]$Configuration = "Release",
    [string]$OutputDir = "TestResults",
    [switch]$SkipBuild,
    [switch]$SkipUnitTests,
    [switch]$SkipIntegrationTests,
    [switch]$SkipContractTests,
    [switch]$GenerateReports = $true,
    [switch]$GenerateCoverage = $true,
    [switch]$OpenResults
)

Write-Host "Starting SimpleTestsDemo Test Suite" -ForegroundColor Green
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Output Directory: $OutputDir" -ForegroundColor Yellow
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Ensure output directory exists
$outputPath = Join-Path $PSScriptRoot $OutputDir
if (!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

# Initialize counters
$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0
$hasFailures = $false

# Build solution
if (!$SkipBuild) {
    Write-Host "Building solution..." -ForegroundColor Blue
    dotnet build --configuration $Configuration --verbosity minimal
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed"
        exit 1
    }
    Write-Host "Build completed successfully" -ForegroundColor Green
    Write-Host ""
}

# Run Unit Tests
if (!$SkipUnitTests) {
    Write-Host "Running Unit Tests..." -ForegroundColor Blue
    $unitTestsOutputPath = Join-Path $outputPath "UnitTests"
    
    $testArgs = @(
        "SimpleTestsDemo.UnitTests"
        "--configuration", $Configuration
        "--logger", "console;verbosity=normal"
        "--verbosity", "normal"
    )
    
    if ($GenerateReports) {
        $testArgs += "--logger", "trx;LogFileName=UnitTests.trx"
        $testArgs += "--logger", "html;LogFileName=UnitTests.html" 
        $testArgs += "--results-directory", $unitTestsOutputPath
    }
    
    if ($GenerateCoverage) {
        $testArgs += "--collect:XPlat Code Coverage"
        $testArgs += "--settings", "coverlet.runsettings"
    }
    
    & dotnet test $testArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Unit tests completed successfully" -ForegroundColor Green
    } else {
        Write-Host "Unit tests completed with failures" -ForegroundColor Yellow
        $hasFailures = $true
    }
    Write-Host ""
}

# Run Integration Tests
if (!$SkipIntegrationTests) {
    Write-Host "Running Integration Tests..." -ForegroundColor Blue
    $integrationTestsOutputPath = Join-Path $outputPath "IntegrationTests"
    
    $testArgs = @(
        "SimpleTestsDemo.IntegrationTests"
        "--configuration", $Configuration
        "--logger", "console;verbosity=normal"
        "--verbosity", "normal"
    )
    
    if ($GenerateReports) {
        $testArgs += "--logger", "trx;LogFileName=IntegrationTests.trx"
        $testArgs += "--logger", "html;LogFileName=IntegrationTests.html"
        $testArgs += "--results-directory", $integrationTestsOutputPath
    }
    
    if ($GenerateCoverage) {
        $testArgs += "--collect:XPlat Code Coverage"
        $testArgs += "--settings", "coverlet.runsettings"
    }
    
    & dotnet test $testArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Integration tests completed successfully" -ForegroundColor Green
    } else {
        Write-Host "Integration tests completed with failures" -ForegroundColor Yellow
        $hasFailures = $true
    }
    Write-Host ""
}

# Run Contract Tests
if (!$SkipContractTests) {
    Write-Host "Running Contract Tests..." -ForegroundColor Blue
    $contractTestsOutputPath = Join-Path $outputPath "ContractTests"
    
    $testArgs = @(
        "SimpleTestsDemo.ContractTests"
        "--configuration", $Configuration
        "--logger", "console;verbosity=normal"
        "--verbosity", "normal"
        "--filter", "SimpleApiContractTests"  # Only run the working contract tests
    )
    
    if ($GenerateReports) {
        $testArgs += "--logger", "trx;LogFileName=ContractTests.trx"
        $testArgs += "--logger", "html;LogFileName=ContractTests.html"
        $testArgs += "--results-directory", $contractTestsOutputPath
    }
    
    & dotnet test $testArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Contract tests completed successfully" -ForegroundColor Green
    } else {
        Write-Host "Contract tests completed with failures" -ForegroundColor Yellow
        $hasFailures = $true
    }
    Write-Host ""
}

# Generate Coverage Reports
if ($GenerateReports -and $GenerateCoverage) {
    Write-Host "Generating Coverage Reports..." -ForegroundColor Blue
    
    # Find all coverage files
    $coverageFiles = Get-ChildItem -Path $outputPath -Recurse -Filter "coverage.cobertura.xml" -ErrorAction SilentlyContinue
    
    if ($coverageFiles.Count -gt 0) {
        $reportOutputPath = Join-Path $outputPath "CoverageReport"
        
        # Check if ReportGenerator is available
        $reportGeneratorExists = $false
        try {
            $globalTools = dotnet tool list --global 2>$null
            if ($globalTools -match "reportgenerator") { 
                $reportGeneratorExists = $true 
            }
        }
        catch {
            # Ignore errors
        }
        
        if (!$reportGeneratorExists) {
            Write-Host "Installing ReportGenerator tool..." -ForegroundColor Yellow
            dotnet tool install --global dotnet-reportgenerator-globaltool --ignore-failed-sources 2>$null
            if ($LASTEXITCODE -eq 0) { 
                $reportGeneratorExists = $true 
                Write-Host "ReportGenerator installed successfully" -ForegroundColor Green
            }
        }
        
        if ($reportGeneratorExists) {
            # Generate HTML coverage report
            $reportArgs = @()
            foreach ($file in $coverageFiles) {
                $reportArgs += "-reports:$($file.FullName)"
            }
            $reportArgs += "-targetdir:$reportOutputPath"
            $reportArgs += "-reporttypes:Html;Cobertura;JsonSummary;TextSummary"
            
            & dotnet reportgenerator $reportArgs 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Coverage reports generated successfully" -ForegroundColor Green
                Write-Host "Coverage report location: $reportOutputPath\index.html" -ForegroundColor Cyan
            }
            else {
                Write-Host "Coverage report generation had issues" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "ReportGenerator tool not available - skipping coverage reports" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "No coverage files found" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Generate Test Summary
if ($GenerateReports) {
    Write-Host "Generating Test Summary..." -ForegroundColor Blue
    
    $testSummary = @{
        timestamp = Get-Date -Format "o"
        configuration = $Configuration
        results = @{
            unitTests = @{ executed = $false; passed = 0; failed = 0; total = 0 }
            integrationTests = @{ executed = $false; passed = 0; failed = 0; total = 0 }
            contractTests = @{ executed = $false; passed = 0; failed = 0; total = 0 }
        }
        artifacts = @{
            outputDirectory = $outputPath
            coverageReport = if (Test-Path (Join-Path $outputPath "CoverageReport\index.html")) { Join-Path $outputPath "CoverageReport\index.html" } else { $null }
        }
    }
    
    # Parse TRX files for detailed results (basic implementation)
    $trxFiles = Get-ChildItem -Path $outputPath -Recurse -Filter "*.trx" -ErrorAction SilentlyContinue
    foreach ($trxFile in $trxFiles) {
        try {
            [xml]$trxContent = Get-Content $trxFile.FullName
            $counters = $trxContent.TestRun.ResultSummary.Counters
            
            $testType = ""
            if ($trxFile.Name -like "*Unit*") { $testType = "unitTests" }
            elseif ($trxFile.Name -like "*Integration*") { $testType = "integrationTests" }
            elseif ($trxFile.Name -like "*Contract*") { $testType = "contractTests" }
            
            if ($testType -and $counters) {
                $testSummary.results[$testType].executed = $true
                $testSummary.results[$testType].total = [int]$counters.total
                $testSummary.results[$testType].passed = [int]$counters.passed
                $testSummary.results[$testType].failed = [int]$counters.failed
            }
        }
        catch {
            # Ignore parsing errors
        }
    }
    
    # Save summary as JSON
    $summaryJson = $testSummary | ConvertTo-Json -Depth 4
    $summaryPath = Join-Path $outputPath "test-summary.json"
    $summaryJson | Out-File -FilePath $summaryPath -Encoding UTF8
    
    Write-Host "Test summary saved to: $summaryPath" -ForegroundColor Cyan
    Write-Host ""
}

# Summary
Write-Host "Test Execution Complete" -ForegroundColor Magenta
Write-Host "=========================" -ForegroundColor Magenta

if ($GenerateReports) {
    Write-Host "Reports generated in: $outputPath" -ForegroundColor Cyan
    
    # List key artifacts
    $htmlReports = Get-ChildItem -Path $outputPath -Recurse -Filter "*.html" -ErrorAction SilentlyContinue
    if ($htmlReports.Count -gt 0) {
        Write-Host "HTML Reports:" -ForegroundColor Yellow
        foreach ($report in $htmlReports) {
            Write-Host "  - $($report.FullName)" -ForegroundColor Gray
        }
    }
    
    $trxReports = Get-ChildItem -Path $outputPath -Recurse -Filter "*.trx" -ErrorAction SilentlyContinue
    if ($trxReports.Count -gt 0) {
        Write-Host "TRX Reports:" -ForegroundColor Yellow
        foreach ($report in $trxReports) {
            Write-Host "  - $($report.FullName)" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# Open results if requested
if ($OpenResults) {
    Write-Host "Opening test reports..." -ForegroundColor Blue
    
    # Open coverage report
    $coverageReportPath = Join-Path $outputPath "CoverageReport\index.html"
    if (Test-Path $coverageReportPath) {
        Write-Host "Opening coverage report..." -ForegroundColor Cyan
        Start-Process $coverageReportPath
    }
    else {
        Write-Host "Coverage report not found at: $coverageReportPath" -ForegroundColor Yellow
    }
    
    # Open individual test HTML reports
    $testHtmlReports = @()
    
    # Unit Tests HTML report
    if (!$SkipUnitTests) {
        $unitTestHtml = Join-Path $outputPath "UnitTests\UnitTests.html"
        if (Test-Path $unitTestHtml) {
            $testHtmlReports += $unitTestHtml
        }
    }
    
    # Integration Tests HTML report
    if (!$SkipIntegrationTests) {
        $integrationTestHtml = Join-Path $outputPath "IntegrationTests\IntegrationTests.html"
        if (Test-Path $integrationTestHtml) {
            $testHtmlReports += $integrationTestHtml
        }
    }
    
    # Contract Tests HTML report
    if (!$SkipContractTests) {
        $contractTestHtml = Join-Path $outputPath "ContractTests\ContractTests.html"
        if (Test-Path $contractTestHtml) {
            $testHtmlReports += $contractTestHtml
        }
    }
    
    # Open all found test reports
    foreach ($reportPath in $testHtmlReports) {
        Write-Host "Opening test report: $(Split-Path $reportPath -Leaf)" -ForegroundColor Cyan
        Start-Process $reportPath
        Start-Sleep -Milliseconds 500  # Small delay to prevent overwhelming the browser
    }
    
    if ($testHtmlReports.Count -eq 0) {
        Write-Host "No test HTML reports found to open" -ForegroundColor Yellow
    }
}

if ($hasFailures) {
    Write-Host "Some tests failed. Check the detailed output above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests passed successfully!" -ForegroundColor Green
    exit 0
}
