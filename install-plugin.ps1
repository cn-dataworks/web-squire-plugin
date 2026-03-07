<#
.SYNOPSIS
    Installs or updates the Web Squire plugin for Claude Code.

.DESCRIPTION
    This script clones (or pulls) the web-squire-plugin repository
    and registers it with Claude Code using the /plugin install command.

.NOTES
    Requirements:
    - Git installed and in PATH
    - Claude Code installed
    - GitHub access (for cloning)

.EXAMPLE
    .\install-plugin.ps1

    Installs or updates the plugin to the default location.
#>

[CmdletBinding()]
param(
    [string]$TargetDir = "$HOME\.claude\plugins\custom\web-squire"
)

$ErrorActionPreference = "Stop"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "   [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "   [!] $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "       $Message" -ForegroundColor Gray
}

function Show-CapabilitySummary {
    param([bool]$PlaywrightAvailable)

    Write-Host ""
    Write-Host "   Capabilities:" -ForegroundColor White
    Write-Host "       [OK] Headless browser automation (playwright-cli)" -ForegroundColor $(if ($PlaywrightAvailable) { "Green" } else { "Yellow" })
    Write-Host "       [OK] Chrome MCP integration (when configured)" -ForegroundColor Green
    Write-Host "       [OK] Parallel QA agent fan-out" -ForegroundColor Green
    Write-Host "       [OK] Dashboard visual testing" -ForegroundColor Green
    Write-Host "       [OK] Data gathering with pagination" -ForegroundColor Green

    if (-not $PlaywrightAvailable) {
        Write-Host ""
        Write-Host "   To enable headless automation, install playwright-cli:" -ForegroundColor White
        Write-Host "       npm install -g @playwright/cli@latest" -ForegroundColor Gray
    }
}

# Banner
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Web Squire Plugin Installer" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Step 1: Check prerequisites
Write-Step "Checking prerequisites..."

# Check Git
try {
    $gitVersion = git --version 2>&1
    Write-Success "Git found: $gitVersion"
} catch {
    Write-Host "   ERROR: Git not found. Install from https://git-scm.com/" -ForegroundColor Red
    exit 1
}

# Check Claude Code
try {
    $claudeVersion = claude --version 2>&1
    Write-Success "Claude Code found: $claudeVersion"
} catch {
    Write-Host "   ERROR: Claude Code not found. Install from https://claude.ai/code" -ForegroundColor Red
    exit 1
}

# Step 2: Clone or update repository
Write-Step "Setting up plugin directory..."

$repoUrl = "https://github.com/cn-dataworks/web-squire-plugin.git"

if (!(Test-Path $TargetDir)) {
    Write-Host "   Cloning repository to: $TargetDir" -ForegroundColor White

    # Create parent directory if needed
    $parentDir = Split-Path $TargetDir -Parent
    if (!(Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Clone
    git clone $repoUrl $TargetDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ERROR: Git clone failed. Check your GitHub access." -ForegroundColor Red
        Write-Host "   TIP: Run 'gh auth login' if using GitHub CLI" -ForegroundColor Yellow
        exit 1
    }
    Write-Success "Repository cloned successfully"
} else {
    Write-Host "   Plugin already exists, pulling latest..." -ForegroundColor White
    Push-Location $TargetDir
    try {
        git pull
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Git pull had issues, but continuing..."
        } else {
            Write-Success "Repository updated successfully"
        }
    } finally {
        Pop-Location
    }
}

# Step 3: Register with Claude Code
Write-Step "Registering plugin with Claude Code..."

# A. Add as Local Marketplace
Write-Info "Adding local marketplace..."
$mkCommand = "/plugin marketplace add `"$TargetDir`""
$mkResult = claude -c $mkCommand 2>&1

if ($LASTEXITCODE -ne 0) {
    if ($mkResult -match "already exists" -or $mkResult -match "Duplicate") {
        Write-Info "Marketplace already registered."
    } else {
        Write-Warn "Marketplace registration warning: $mkResult"
    }
} else {
    Write-Success "Local marketplace added."
}

# B. Install Plugin
Write-Info "Installing plugin..."
$installCommand = "/plugin install web-squire"
$installResult = claude -c $installCommand 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Success "Plugin installed successfully."
} elseif ($installResult -match "already installed") {
    Write-Info "Plugin is already installed. Attempting update..."
    claude -c "/plugin update web-squire" | Out-Null
    Write-Success "Plugin updated."
} else {
    Write-Warn "Plugin installation returned non-zero exit code"
    Write-Host "   Output: $installResult" -ForegroundColor Gray
}

# Step 4: Check for playwright-cli
Write-Step "Checking for playwright-cli..."

$playwrightAvailable = $null -ne (Get-Command "playwright-cli" -ErrorAction SilentlyContinue)

if ($playwrightAvailable) {
    Write-Success "playwright-cli found"
} else {
    Write-Warn "playwright-cli not found"
    Write-Info "Install with: npm install -g @playwright/cli@latest"
}

# Step 5: Verification
Write-Step "Verifying installation..."

Write-Host "   Plugin location: $TargetDir" -ForegroundColor White

# Done
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Show-CapabilitySummary -PlaywrightAvailable $playwrightAvailable

Write-Host ""
Write-Host "   Next steps:" -ForegroundColor White
Write-Host "       1. Open Claude Code in your project folder" -ForegroundColor Gray
Write-Host "       2. Run: /plugin list  (to verify)" -ForegroundColor Gray
Write-Host "       3. Create story files in ai_user_stories/" -ForegroundColor Gray
Write-Host "       4. Try: /web-squire:ui-review" -ForegroundColor Gray
Write-Host ""
