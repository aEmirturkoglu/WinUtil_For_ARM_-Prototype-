# 🎯 WinUtil ARM64 Elite-X Converter v2026.4.25

## Quick Start

```powershell
# Full conversion (recommended)
pwsh -File .\arm-converter\main-arm64.ps1

# TPM Blind Only (lightweight, fast boot)
pwsh -File .\arm-converter\main-arm64.ps1 -Mode TPM_BLIND
```

## Compatibility Matrix

| Device | Core | RAM | TPM | Status |
|--------|------|-----|-----|--------|
| Elite X | v8.2 AArch64 | 16GB | Yes | ✅ Native |
| Elite X Pro | v8.5+ | 32GB | Pluton | ✅ Blind Mode |
| Elite X Ultra | v9.0 | 64GB | Secure Encl | ✅ Full Integration |

## What It Does

- **x86 → ARM64 Binary Conversion**: Converts winutil packages for native ARM execution
- **Pluton/TPM Blind Injection**: Injects fake data to satisfy Pluton security checks  
- **X86 Fallback Disable**: Forces native ARM execution path
- **LPAE Memory Optimization**: Enables Large Page Address Extension
- **Telemetry Stripper**: Removes Bing, Weather, and other telemetry modules

## GitHub Repository Structure

```
WinUtil_For_ARM/
├── arm-converter/          ← Main conversion scripts
│   ├── main-arm64.ps1     ← Primary script (8KB)
│   ├── postinstall.txt    ← Boot-time auto-run
│   ├── binaries/          ← Stub loaders
│   └── QUICK-START.md     ← Reference card
├── README.md              ← This file
└── LICENSE                ← MIT License
```

## Usage Examples

### 1. Full Conversion
```powershell
pwsh -File .\arm-converter\main-arm64.ps1
```

### 2. TPM Blind Only (Fast Boot)
```powershell
pwsh -File .\arm-converter\main-arm64.ps1 -Mode TPM_BLIND
```

### 3. Create Boot-Time Interceptor
```powershell
if (Test-Path "arm-converter/binaries") {
    mkdir "$env:System32\WinUtil" 2>$null
    Copy-Item arm-converter/binaries/*.cs \
             "$env:System32\WinUtil\" -Force 2>$null
}
```

## Expected Registry Changes

After first run:
- `HKLM:\SYSTEM\CurrentControlSet\Services\FtdiSerialService\Parameters`
  → `MockTPMData = "EliteX-Arm64-Mock v2.0.8315.7901"`

- `HKLM:\SYSTEM\CurrentControlSet\Environment`  
  → `PROCESSOR_ARCHITECTURE = "ARM64"`

## Boot-Time Persistence

After first run, stub loaders auto-copy to:
```powershell
$env:System32\WinUtil\
$env:SystemRoot\StartUp\
Registry persistence enabled
```

## License

MIT License - See LICENSE file for details.

---
**v2026.4.25 • Built for Elite X ARM64 Devices**
