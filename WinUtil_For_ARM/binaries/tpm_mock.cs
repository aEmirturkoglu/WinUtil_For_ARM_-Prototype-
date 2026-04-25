// ── TPM_Mock.dll - Fake TPM2.0+ Response Handler for Elite X ARM64 ─────────
using System;

class TPMMockResponse {
    private static byte[] _fakeTpmOwnerInfo = Encoding.UTF8.GetBytes("EliteX-ARM64-Mock v2.0.8315.7901");
    
    public static byte[] GetOwnerInfo() => _fakeTpmOwnerInfo;
}

public class PlutonBlinder {
    [DllImport("tpm.dll", SetLastError=true)]
    private static extern uint Tpm_Init(IntPtr tpmContext, IntPtr buffer, int bufferSize);
    
    public static byte[] Mock_TPM2_StartAuthSession() => new byte[32];
}
