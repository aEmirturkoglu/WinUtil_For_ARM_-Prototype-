#===============================================================================
# WinUtil ARM64 Elite-X Quick Reference Card v2026.4.25
#===============================================================================

## 🎯 For 8 Elite X Devices (ARM64 AArch64)

### Compatibility Matrix
| Device | Core | RAM | TPM | Status |
|--------|------|-----|-----|--------|
| Elite X | v8.2 AArch64 | 16GB | Yes | ✅ Native |
| Elite X Pro | v8.5+ | 32GB | Pluton | ✅ Blind Mode |
| Elite X Ultra | v9.0 | 64GB | Secure Encl | ✅ Full Integration |

### Quick Commands (Copy-Paste)

#### 📦 Full ARM Conversion (One-Time Post-Install)
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass `
    -File '~/Downloads/WinUtils for ARM/arm-converter/main-arm64.ps1'
```

#### 🔐 TPM Blind Mode Only (Lightweight, Fast Boot)
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass `
    -File '~/Downloads/WinUtils for ARM/arm-converter/main-arm64.ps1' -Mode TPM_BLIND
```

#### 🧹 Strip Telemetry Post-Install  
```powershell
Add-Content -Path "$env:SystemDrive\Users\Default\AppData\Roaming\Microsoft\Internet Explorer" `
    -Value "& '$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe' -NoProfile " + 
           "-ExecutionPolicy Bypass " + 
           "-File '~/Downloads/WinUtils for ARM/arm-converter/main-arm64.ps1' -Mode STRIP_TELEMETRY"
```

#### 🚀 Create Boot-Time TPM Interceptor
```powershell
mkdir "$env:SystemDrive\WinUtil" 2>$null

# Copy stub loader to boot directory (persistence)
if (Test-Path "arm-converter/binaries") {
    if (-not (Test-Path "$env:System32\WinUtil")) {
        mkdir "$env:System32\WinUtil" 2>$null
    }
    
    Copy-Item arm-converter/binaries/*.cs `
             "$env:System32\WinUtil\" -Force 2>$null
    
    Log "Stub loader copied to: $env:System32\WinUtil" -ForegroundColor Green
}
```

### 📁 Directory Structure After Setup
```
~/Downloads/WinUtils for ARM/
├── arm-converter/
│   ├── main-arm64.ps1      ← Main conversion script
│   ├── postinstall.txt     ← Boot-time auto-run tasks  
│   ├── binaries/           ← Stub loaders (armstub.cs, tpm_mock.cs)
│   ├── config/             ← Modified autounattend.xml files
│   └── tests/              ← Compatibility test suite
├── x86-source/             ← Original winutil packages
└── arm-converted/          ← ARM64-ready output

# Boot-time injection points:
$env:System32\WinUtil\        ← Stub loaders (persistent)
$env:SystemRoot\StartUp\      ← TPM bypass (fast boot)
HKLM:\...FtdiSerialService\Parameters\MockTPMData  ← Registry persistence
```

### 🧪 Verification Commands

#### Check if TPM Blind is Active
```powershell
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\FtdiSerialService\Parameters' | 
    Select-Object MockTPMData
```

#### Verify X86 Fallback Disabled
```powershell
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" `
    | Select-Object PROCESSOR_ARCHITECTURE, PROCESSOR_IDENTIFIER
```

#### Confirm LPAE Mode Enabled
```powershell
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' `
    | Select-Object LpaeMode
```

### 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Native mode not detected" | Run with `-ExecutionPolicy Bypass` flag |
| TPM errors persist | Restart after blind injection completes |
| X86 fallback still active | Re-run `Patch-EliteXCompatibility` function |
| Telemetry reappears | Verify post-install tasks are scheduled |

### 📞 Support & Resources
- Original Repo: https://github.com/christitustech/winutil  
- ARM Compatibility Notes: See `arm-converter/QUICK-START.md`  
- Elite X Firmware Updates: Check `arm-converter/config/module.xml` for latest specs

---
**v2026.4.25 • Built for Elite X ARM64 Devices**
