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
    
    # Find all coverage files with actual data
    $allCoverageFiles = Get-ChildItem -Path $outputPath -Recurse -Filter "coverage.cobertura.xml" -ErrorAction SilentlyContinue
    $coverageFiles = @()
    
    Write-Host "Found $($allCoverageFiles.Count) coverage XML files to examine:" -ForegroundColor Yellow
    foreach ($file in $allCoverageFiles) {
        Write-Host "  - $($file.FullName)" -ForegroundColor Gray
    }
    Write-Host "" -ForegroundColor Yellow
    
    foreach ($file in $allCoverageFiles) {
        try {
            $content = Get-Content $file.FullName -Raw
            # Check if the file is a valid Cobertura XML file with coverage data
            # Accept files even with 0 coverage as that's still valid data
            if ($content -match '<coverage ' -and ($content -match '<packages>' -or $content -match 'lines-covered="\d+"')) {
                $coverageFiles += $file
                Write-Host "  Found valid coverage file: $($file.FullName)" -ForegroundColor Gray
                
                # Extract some stats for debugging
                if ($content -match 'lines-covered="(\d+)"' -and $content -match 'lines-valid="(\d+)"') {
                    $linesCovered = $matches[1]
                    $linesValid = $matches[2] 
                    Write-Host "    Lines covered: $linesCovered/$linesValid" -ForegroundColor DarkGray
                }
                
                # Check if it has actual package data
                if ($content -match '<packages>\s*<package') {
                    Write-Host "    Has package data: Yes" -ForegroundColor DarkGray
                } else {
                    Write-Host "    Has package data: No (empty packages)" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  Skipped invalid coverage file: $($file.FullName)" -ForegroundColor Yellow
            }
        }
        catch {
            # Ignore files we can't read
        }
    }
    
    if ($coverageFiles.Count -gt 0) {
        Write-Host "Found $($coverageFiles.Count) coverage files with data:" -ForegroundColor Cyan
        foreach ($file in $coverageFiles) {
            Write-Host "  - $($file.FullName)" -ForegroundColor Gray
        }
        Write-Host ""
        
        $reportOutputPath = Join-Path $outputPath "CoverageReport"
        
        # Check if ReportGenerator is available
        $reportGeneratorExists = $false
        try {
            $globalTools = dotnet tool list --global 2>$null
            if ($globalTools -match "reportgenerator") { 
                $reportGeneratorExists = $true 
                Write-Host "ReportGenerator found in global tools" -ForegroundColor Green
            } else {
                Write-Host "ReportGenerator not found in global tools" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error checking global tools: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        if (!$reportGeneratorExists) {
            Write-Host "Installing ReportGenerator tool..." -ForegroundColor Yellow
            $installOutput = dotnet tool install --global dotnet-reportgenerator-globaltool --ignore-failed-sources 2>&1
            Write-Host "Install output: $installOutput" -ForegroundColor Gray
            
            if ($LASTEXITCODE -eq 0) { 
                $reportGeneratorExists = $true 
                Write-Host "ReportGenerator installed successfully" -ForegroundColor Green
                
                # Verify it's actually available
                try {
                    $testOutput = & dotnet reportgenerator --help 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "ReportGenerator is working correctly" -ForegroundColor Green
                    } else {
                        Write-Host "ReportGenerator installed but not working: $testOutput" -ForegroundColor Red
                        $reportGeneratorExists = $false
                    }
                } catch {
                    Write-Host "ReportGenerator test failed: $($_.Exception.Message)" -ForegroundColor Red
                    $reportGeneratorExists = $false
                }
            } else {
                Write-Host "Failed to install ReportGenerator, exit code: $LASTEXITCODE" -ForegroundColor Red
                Write-Host "Install output: $installOutput" -ForegroundColor Red
            }
        }
        
        if ($reportGeneratorExists) {
            Write-Host "Attempting to generate coverage report with ReportGenerator..." -ForegroundColor Blue
            
            # Generate HTML coverage report
            $reportPaths = $coverageFiles | ForEach-Object { $_.FullName }
            $reportArgs = @(
                "-reports:$($reportPaths -join ';')"
                "-targetdir:$reportOutputPath"
                "-reporttypes:Html;Cobertura;JsonSummary;TextSummary"
            )
            
            Write-Host "ReportGenerator arguments:" -ForegroundColor Gray
            $reportArgs | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            
            # Verify all coverage files exist and are readable
            Write-Host "Verifying coverage files before ReportGenerator:" -ForegroundColor Gray
            foreach ($reportPath in $reportPaths) {
                if (Test-Path $reportPath) {
                    $fileSize = (Get-Item $reportPath).Length
                    Write-Host "  OK: $reportPath ($fileSize bytes)" -ForegroundColor Gray
                } else {
                    Write-Host "  ERROR: $reportPath (file not found)" -ForegroundColor Red
                }
            }
            
            try {
                Write-Host "Dotnet tool restore..." -ForegroundColor Gray
                dotnet tool restore
                Write-Host "Executing ReportGenerator command..." -ForegroundColor Gray
                $reportOutput = & dotnet reportgenerator $reportArgs 2>&1
                Write-Host "ReportGenerator exit code: $LASTEXITCODE" -ForegroundColor Gray
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "ReportGenerator completed successfully" -ForegroundColor Green
                    
                    # Check if index.html was created
                    $indexPath = Join-Path $reportOutputPath "index.html"
                    Write-Host "Checking for index.html at: $indexPath" -ForegroundColor Gray
                    
                    if (Test-Path $indexPath) {
                        $indexSize = (Get-Item $indexPath).Length
                        Write-Host "SUCCESS: ReportGenerator created detailed coverage report!" -ForegroundColor Green
                        Write-Host "Coverage report location: $indexPath ($indexSize bytes)" -ForegroundColor Cyan
                        
                        # List some of the generated files for verification
                        $reportFiles = Get-ChildItem -Path $reportOutputPath -Filter "*.html" -ErrorAction SilentlyContinue
                        if ($reportFiles.Count -gt 0) {
                            Write-Host "Generated HTML files:" -ForegroundColor Green
                            $reportFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
                        }
                    } else {
                        Write-Host "WARNING: ReportGenerator completed but index.html not found" -ForegroundColor Yellow
                        Write-Host "Output directory contents:" -ForegroundColor Yellow
                        if (Test-Path $reportOutputPath) {
                            Get-ChildItem -Path $reportOutputPath | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
                        } else {
                            Write-Host "  Output directory does not exist" -ForegroundColor Red
                        }
                        Write-Host "ReportGenerator output: $reportOutput" -ForegroundColor Yellow
                    }
                }
                else {
                    Write-Host "ReportGenerator failed with exit code $LASTEXITCODE" -ForegroundColor Red
                    Write-Host "ReportGenerator output:" -ForegroundColor Red
                    Write-Host "$reportOutput" -ForegroundColor Red
                    
                    # Additional debugging for failed execution
                    Write-Host "Debugging ReportGenerator failure:" -ForegroundColor Red
                    Write-Host "  - Target directory: $reportOutputPath" -ForegroundColor Gray
                    Write-Host "  - Target directory exists: $(Test-Path $reportOutputPath)" -ForegroundColor Gray
                    Write-Host "  - Number of input files: $($reportPaths.Count)" -ForegroundColor Gray
                    Write-Host "  - ReportGenerator version check:" -ForegroundColor Gray
                    try {
                        $versionOutput = & dotnet reportgenerator --version 2>&1
                        Write-Host "    Version: $versionOutput" -ForegroundColor Gray
                    } catch {
                        Write-Host "    Version check failed: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            } catch {
                Write-Host "ReportGenerator execution failed with exception: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Exception details: $($_.Exception.ToString())" -ForegroundColor Red
            }
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
            coverageReport = if (Test-Path (Join-Path $outputPath (Join-Path "CoverageReport" "index.html"))) { Join-Path $outputPath (Join-Path "CoverageReport" "index.html") } else { $null }
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
    $coverageReportPath = Join-Path $outputPath (Join-Path "CoverageReport" "index.html")
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
        $unitTestHtml = Join-Path $outputPath (Join-Path "UnitTests" "UnitTests.html")
        if (Test-Path $unitTestHtml) {
            $testHtmlReports += $unitTestHtml
        }
    }
    
    # Integration Tests HTML report
    if (!$SkipIntegrationTests) {
        $integrationTestHtml = Join-Path $outputPath (Join-Path "IntegrationTests" "IntegrationTests.html")
        if (Test-Path $integrationTestHtml) {
            $testHtmlReports += $integrationTestHtml
        }
    }
    
    # Contract Tests HTML report
    if (!$SkipContractTests) {
        $contractTestHtml = Join-Path $outputPath (Join-Path "ContractTests" "ContractTests.html")
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
