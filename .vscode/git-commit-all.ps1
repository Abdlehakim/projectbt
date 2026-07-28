Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$CommitMessage = "Auto commit - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$Submodules = @(
    "apps/customer",
    "services/api"
)

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & git -C $WorkingDirectory @Arguments

    if ($LASTEXITCODE -ne 0) {
        $commandText = "git -C `"$WorkingDirectory`" $($Arguments -join ' ')"
        throw "Git command failed: $commandText"
    }
}

function Assert-GitRepository {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    if (-not (Test-Path -LiteralPath $WorkingDirectory)) {
        throw "Repository directory does not exist: $WorkingDirectory"
    }

    $insideRepository = & git -C $WorkingDirectory rev-parse --is-inside-work-tree 2>$null

    if ($LASTEXITCODE -ne 0 -or $insideRepository.Trim() -ne "true") {
        throw "Directory is not a valid Git repository: $WorkingDirectory"
    }
}

function Get-WorkingTreeChanges {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $changes = @(
        & git -C $WorkingDirectory status --porcelain
    )

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect repository status: $WorkingDirectory"
    }

    return $changes
}

function Test-StagedChanges {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    & git -C $WorkingDirectory diff --cached --quiet
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        return $false
    }

    if ($exitCode -eq 1) {
        return $true
    }

    throw "Unable to inspect staged changes in '$WorkingDirectory'."
}

function Assert-NoSensitiveFilesStaged {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    # Inspect only files whose content will exist in the new commit.
    # Deleted files are excluded intentionally.
    $stagedFiles = @(
        & git -C $WorkingDirectory diff `
            --cached `
            --name-only `
            --diff-filter=ACMRT
    )

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect staged files in '$WorkingDirectory'."
    }

    $sensitiveFiles = @(
        $stagedFiles | Where-Object {
            $normalizedPath = ($_ -replace "\\", "/").Trim()
            $fileName = [System.IO.Path]::GetFileName($normalizedPath)

            $isEnvironmentFile =
                $fileName -eq ".env" -or
                $fileName -like ".env.*"

            # Allow environment templates such as:
            # .env.example
            # .env.production.example
            # .env.local.sample
            # .env.development.template
            $isEnvironmentTemplate =
                $fileName -match "\.(example|sample|template)$"

            $isPrivateKeyExtension =
                $fileName -match "\.(pem|key|p12|pfx)$"

            $isPrivateSshKey =
                $fileName -match "^id_(rsa|dsa|ecdsa|ed25519)$"

            $isCredentialFile =
                $fileName -match "^(credentials|service-account|service_account)\.json$"

            (
                ($isEnvironmentFile -and -not $isEnvironmentTemplate) -or
                $isPrivateKeyExtension -or
                $isPrivateSshKey -or
                $isCredentialFile
            )
        }
    )

    if ($sensitiveFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Sensitive files are staged and will not be committed:" -ForegroundColor Red

        foreach ($file in $sensitiveFiles) {
            Write-Host " - $file" -ForegroundColor Red
        }

        throw "Remove sensitive files from Git staging before continuing."
    }
}

function Switch-ToMainBranch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $currentBranch = (
        & git -C $WorkingDirectory rev-parse --abbrev-ref HEAD
    ).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine current branch in '$WorkingDirectory'."
    }

    if ($currentBranch -ne "main") {
        Invoke-Git `
            -WorkingDirectory $WorkingDirectory `
            -Arguments @("checkout", "main")
    }
    else {
        Write-Host "Already on 'main'"
    }
}

function Pull-WhenClean {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $changes = @(Get-WorkingTreeChanges -WorkingDirectory $WorkingDirectory)

    if ($changes.Count -eq 0) {
        Invoke-Git `
            -WorkingDirectory $WorkingDirectory `
            -Arguments @("pull", "--ff-only", "origin", "main")
    }
    else {
        Write-Host "Local changes detected; skipping pull before commit." -ForegroundColor Yellow
    }
}

function Commit-And-PushRepository {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )

    Write-Host ""
    Write-Host "=== Repository: $DisplayName ===" -ForegroundColor Cyan

    Assert-GitRepository -WorkingDirectory $WorkingDirectory
    Switch-ToMainBranch -WorkingDirectory $WorkingDirectory
    Pull-WhenClean -WorkingDirectory $WorkingDirectory

    Invoke-Git `
        -WorkingDirectory $WorkingDirectory `
        -Arguments @("add", "-A", "--", ".")

    Assert-NoSensitiveFilesStaged -WorkingDirectory $WorkingDirectory

    $hasStagedChanges = Test-StagedChanges -WorkingDirectory $WorkingDirectory

    if ($hasStagedChanges) {
        Invoke-Git `
            -WorkingDirectory $WorkingDirectory `
            -Arguments @("commit", "-m", $CommitMessage)

        Write-Host "Committed: $DisplayName" -ForegroundColor Green
    }
    else {
        Write-Host "No file changes to commit in $DisplayName."
    }

    Invoke-Git `
        -WorkingDirectory $WorkingDirectory `
        -Arguments @("push", "origin", "main")

    Write-Host "Pushed: $DisplayName" -ForegroundColor Green
}

Write-Host ""
Write-Host "Repository: $WorkspaceRoot"
Write-Host "Message:    $CommitMessage"

foreach ($relativePath in $Submodules) {
    $repositoryPath = Join-Path $WorkspaceRoot $relativePath
    $displayName = $relativePath -replace "\\", "/"

    Commit-And-PushRepository `
        -WorkingDirectory $repositoryPath `
        -DisplayName $displayName
}

Write-Host ""
Write-Host "=== Parent repository: projectbt ===" -ForegroundColor Cyan

Assert-GitRepository -WorkingDirectory $WorkspaceRoot
Switch-ToMainBranch -WorkingDirectory $WorkspaceRoot
Pull-WhenClean -WorkingDirectory $WorkspaceRoot

# Stage parent changes after submodule commits so their updated pointers
# are included in the parent repository commit.
Invoke-Git `
    -WorkingDirectory $WorkspaceRoot `
    -Arguments @("add", "-A", "--", ".")

Assert-NoSensitiveFilesStaged -WorkingDirectory $WorkspaceRoot

$parentHasStagedChanges = Test-StagedChanges -WorkingDirectory $WorkspaceRoot

if ($parentHasStagedChanges) {
    Invoke-Git `
        -WorkingDirectory $WorkspaceRoot `
        -Arguments @("commit", "-m", $CommitMessage)

    Write-Host "Committed: projectbt" -ForegroundColor Green
}
else {
    Write-Host "No file changes to commit in projectbt."
}

Invoke-Git `
    -WorkingDirectory $WorkspaceRoot `
    -Arguments @("push", "origin", "main")

Write-Host "Pushed: projectbt" -ForegroundColor Green

Write-Host ""
Write-Host "All repositories were processed successfully." -ForegroundColor Green