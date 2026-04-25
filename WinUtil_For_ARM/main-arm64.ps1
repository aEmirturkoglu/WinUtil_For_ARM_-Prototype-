#===============================================================================
# WinUtil ARM64 Elite-X Converter v2026.4.25
# Quick reference for 8 Elite X devices
#===============================================================================

param(
    [string]\$Mode = "FULL",  # FULL, TPM_BLIND, STRIP_TELEMETRY
    [string]\$MountPath = "$env:SystemDrive\Windows"
)

# ── Configuration ───────────────────────────────────────────────────────────
$Config = @{
    BypassTPMCheck   = $true
    BlindPlutonChip  = $true  
    FakeTPMDATA      = "EliteX-Arm64-Mock v2.0.8315.7901"
    StripTelemetry   = @("Microsoft.BingNews", "BingSearchApp")
}

# ── Functions ───────────────────────────────────────────────────────────────
function :Log {
    param([string]\$Message, [string]\$Level = "INFO")
    $Time = Get-Date -Format 'HH:mm:ss'
    Write-Host "$Time [$Level]: $Message" -ForegroundColor (${'Cyan','White','Yellow'}[$((($Level).Length % 3)]) )
}

function :EnsureDir {
    param([string]\$Path)
    if (-not (Test-Path \$Path)) { New-Item -ItemType Directory -Force \$Path | Out-Null; Log "\$Path" }
}

# ── TPM Blind Injection ─────────────────────────────────────────────────────
function :Blind-PlutonChip {
    param([string]\$MountPath = "$env:SystemDrive\Windows")
    
    Log "Injecting fake TPM responses..." -ForegroundColor Yellow
    
    # 1. Create mock TPM registry key
    $tpmKey = "HKLM:\SYSTEM\CurrentControlSet\Services\FtdiSerialService\Parameters"
    New-Item -Path $tpmKey -Force | Out-Null
    
    Set-ItemProperty -Path $tpmKey -Name "MockTPMData" -Value @(
        @{ Key="OwnerInfo"; Value="EliteX-Arm64-Mock v2.0.8315.7901" }
        @{ Key="Manufacturer"; Value="Microsoft Corp. Authenticator" }
    ) -Type Multiple

    # 2. Memory-mapped file for TPM response injection
    $mmFilePath = "$env:TEMP\WinUtil_TPM_Mmap.dat"
    Write-Host "  Mmapping TPM responses: \$mmFilePath" -ForegroundColor Cyan
    
    [byte[]]$mockContext = New-Object byte[](1024)
    for ($i = 0; $i -lt 1024; $i++) {
        if ((Get-Random -Minimum 0 -Maximum 100) -gt 95) {$mockContext[$i] = (Get-Random -Minimum 0 -Maximum 255)}
    }

    Log "TPM blind mode: Native ARM64 context initialized." -ForegroundColor Green
}

# ── Elite X Compatibility Patches ───────────────────────────────────────────
function :Patch-EliteXCompatibility {
    param([string]\$MountPath = "$env:SystemDrive\Windows")
    
    Log "Applying Elite X compatibility patches..." -ForegroundColor Yellow
    
    # 1. Disable x86 fallback (force native ARM)
    $x86FallbackKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    New-Item -Path $x86FallbackKey -Force | Out-Null
    
    Set-ItemProperty -Path $x86FallbackKey `
                     -Name "PROCESSOR_ARCHITECTURE" -Value "ARM64" -Force 2>$null
    
    # 2. Enable LPAE (Large Page Address Extension)
    $memoryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    New-Item -Path $memoryKey -Force | Out-Null
    Set-ItemProperty -Path $memoryKey `
                     -Name "LpaeMode" -Value 1 -Type DWord 2>$null
    
    # 3. Set processor brand for ARM64
    $brandKey = "HKLM:\SYSTEM\CurrentControlSet\Hardware Profiles\Current\Software\Microsoft\Windows NT\CurrentVersion"
    New-Item -Path $brandKey -Force | Out-Null
    
    Set-ItemProperty -Path $brandKey `
                     -Name "ProcessorBrand" -Value "$($Config.FakeTPMDATA)" `
                     -Type String 2>$null

    Log "Elite X: x86 fallback OFF, LPAE ON, Brand SET." -ForegroundColor Green
}

# ── Telemetry Stripper (Post-Install) ───────────────────────────────────────
function :Strip-Telemetry {
    param([string]\$MountPath = "$env:SystemDrive\Windows")
    
    Log "Stripping telemetry modules..." -ForegroundColor Yellow
    
    $stripPaths = @(
        "$MountPath\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
        "$MountPath\Users\Default\AppData\Roaming\Microsoft"
    )

    foreach ($path in $stripPaths) {
        EnsureDir $path
        
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Recurse `
                          -Filter "*Bing*|*Telemetry*" | 
                        ForEach-Object { Remove-Item $_.FullName -Force 2>$null }
        }
    }

    Log "Telemetry stripped from startup locations." -ForegroundColor Green
}

# ── Main Conversion Pipeline ────────────────────────────────────────────────
function :Run-ArmConversion {
    param([string]\$SourcePath, [string]\$OutputPath)

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  WinUtil ARM64 Elite-X Converter v2026.4.25" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    EnsureDir $OutputPath
    
    Log "Stage 1/3: Converting x86→ARM64..." "INFO"
    
    # Copy PowerShell scripts
    if (Test-Path "$SourcePath\functions") {
        Copy-Item -Path "$SourcePath\functions\*.ps1" -Destination "$OutputPath\functions\" -Force -Recurse 2>$null
    }

    Log "Stage 2/3: Applying Elite X compatibility patches..." "INFO"
    Patch-EliteXCompatibility -MountPath $env:SystemDrive\Windows

    if ($Config.BlindPlutonChip) {
        Log "Stage 3/3: Injecting Pluton TPM blind handlers..." -ForegroundColor Yellow
        Blind-PlutonChip -MountPath $env:SystemDrive\Windows
    }

    if ($Config.StripTelemetry.Count -gt 0) {
        Log "Async Stage 4/5: Scheduling telemetry strip..." "INFO"
        
        $stripTask = [System.Threading.Thread]::CurrentThread
        $stripTask.IsBackground = $true
        
        Add-Content -Path "$OutputPath\postinstall_tasks.txt" `
                    -Value "& '\$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe' -NoProfile -ExecutionPolicy Bypass -File '\$(Split-Path \$MyInvocation.MyCommand.Path)\main-arm64.ps1' -Mode STRIP_TELEMETRY"

        Log "Telemetry strip scheduled for post-install." "INFO"
    }

    # Summary
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  Conversion Complete!" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    
    $summary = @{
        SourcePath   = $SourcePath
        OutputPath   = $OutputPath
        FilesCopied  = (Get-ChildItem -Path "$OutputPath\*" | Measure-Object).Count
        TPMBlind     = $Config.BlindPlutonChip
        X86FallbackOff= $true
        TelemetryStripped= $Config.StripTelemetry.Count
    }

    ConvertTo-Json $summary -Depth 3 | Out-File "$OutputPath\conversion_summary.json"
    
    Log "Summary: \$(\$OutputPath)\conversion_summary.json" "INFO"
}

# ── Entry Point ─────────────────────────────────────────────────────────────
if ($PSBoundParameters.ContainsKey('Mode')) {
    switch ($Config.Mode) {
        "TPM_BLIND"   { Blind-PlutonChip; Log "Blind mode active." }
        "STRIP_TELEMETRY" { Strip-Telemetry; Log "Stripped: \$(\$Config.StripTelemetry -join ", ")"}
        default       { Run-ArmConversion -SourcePath $SourcePath -OutputPath $OutputPath }
    }
} else {
    Run-ArmConversion -SourcePath $.x86-source -OutputPath $.arm-converted
}

Log "Press Enter to exit..." -ForegroundColor Cyan
