# GitHub Actions Setup for Test Reports

This repository includes two GitHub Actions workflows for building, testing, and publishing reports:

## 🚀 Quick Setup

### Option 1: Simple Artifacts (Recommended for start)
Use `simple-ci.yml` - uploads test reports as downloadable artifacts.

### Option 2: GitHub Pages (Advanced)
Use `ci.yml` - publishes reports to GitHub Pages with a web interface.

## 📋 Setup Instructions

### For Both Options:
1. Copy one of the workflow files to `.github/workflows/` in your repository
2. Push to GitHub - the workflow will run automatically on pushes and PRs

### For GitHub Pages (ci.yml):
1. Go to your GitHub repository
2. Click **Settings** → **Pages**
3. Under "Source", select **GitHub Actions**
4. Push code to main branch
5. View reports at: `https://[username].github.io/[repository-name]/`

## 📊 What You Get

### 1. **Artifact Downloads** (Both workflows)
- Navigate to **Actions** tab → Click a workflow run
- Download ZIP files containing all reports
- Extract and open HTML files locally

### 2. **Inline Test Results** (Both workflows)
- Test results appear directly in the GitHub Actions summary
- Failed tests are highlighted with details
- Trend analysis across runs

### 3. **Pull Request Comments** (Both workflows)
- Code coverage summary posted as PR comment
- Coverage changes highlighted
- Automatic updates on new commits

### 4. **GitHub Pages Website** (ci.yml only)
- Professional dashboard at your GitHub Pages URL
- Direct links to all report types
- Always shows latest results from main branch

## 🎯 Report Types Available

| Report Type | Description | File Location |
|------------|-------------|---------------|
| **Unit Tests** | HTML report with test details | `TestResults/UnitTests/UnitTests.html` |
| **Integration Tests** | End-to-end test results | `TestResults/IntegrationTests/IntegrationTests.html` |
| **Contract Tests** | API contract validation | `TestResults/ContractTests/ContractTests.html` |
| **Coverage Report** | Interactive coverage analysis | `TestResults/CoverageReport/index.html` |
| **TRX Files** | Raw test data for CI systems | `TestResults/**/*.trx` |

## 🔧 Customization

### Modify Test Thresholds
Edit the workflow file to change coverage thresholds:
```yaml
thresholds: '60 80'  # Minimum 60%, target 80%
```

### Change Report Retention
Adjust how long artifacts are kept:
```yaml
retention-days: 30  # Keep for 30 days
```

### Filter Tests
Modify test execution to run specific test categories:
```yaml
--filter "Category=Unit|Category=Integration"
```

## 🐛 Troubleshooting

### Common Issues:

1. **"No test results found"**
   - Ensure your test projects build successfully
   - Check that TRX files are being generated

2. **"Pages deployment failed"**
   - Verify GitHub Pages is enabled in repository settings
   - Ensure you're pushing to the main branch

3. **"Coverage report empty"**
   - Check that coverlet.runsettings is in repository root
   - Verify test projects have coverage collection enabled

### Getting Help:
- Check the **Actions** tab for detailed logs
- View the workflow run to see which step failed
- Test reports are uploaded even if other steps fail

## 💡 Pro Tips

1. **Use Simple CI First**: Start with `simple-ci.yml` to verify everything works
2. **Review PR Comments**: Coverage changes are highlighted in PR comments
3. **Download Artifacts**: Even with Pages, artifacts provide backup access
4. **Monitor Trends**: GitHub Actions shows test result trends over time
5. **Branch Protection**: Consider requiring tests to pass before merging
