# 🪟 Windows Scripts

Windows-specific utility scripts for homelab management.

## 📋 Available Scripts

### Update-AllApps.ps1

**PowerShell script to update all installed applications.**

---

### zero_drive.py

**Securely wipe a physical disk by writing zeros to every sector with real-time progress reporting.**

This script performs a full disk wipe by writing zeros to every sector of a selected physical disk. It auto-detects all connected disks, lets you choose which one to wipe, and provides real-time progress including percentage, write speed, and estimated time remaining.

**Features:**
- ✅ Auto-detects all physical disks and displays them in a table
- ✅ User selects which disk to zero (no hardcoded disk numbers)
- ✅ Real-time progress bar with percentage complete
- ✅ Write speed monitoring (MB/s)
- ✅ Estimated time remaining (ETA)
- ✅ Multiple confirmation prompts before wiping
- ✅ Handles end-of-disk edge cases gracefully
- ✅ Uses direct Windows API calls for raw disk access
- ✅ Write-through mode (no caching) for reliable writes

**Requirements:**
- Windows OS
- Python 3.6+
- Administrator privileges

**Usage:**
```powershell
# 1. Open Command Prompt or PowerShell as Administrator
# 2. Run the script:
python zero_drive.py
```

**Example Output:**
```
============================================================
  DISK ZERO UTILITY
  Securely wipe a disk by writing zeros to every sector
============================================================

Running with Administrator privileges.

Detected Physical Disks:
--------------------------------------------------------------------------------
  Disk #   Name                                  Size      Bus    Partition
--------------------------------------------------------------------------------
  0        Samsung SSD 990 PRO 4TB             3.7 TB     NVMe          GPT
  1        USB Storage Device                931.5 GB      USB          RAW
--------------------------------------------------------------------------------

Enter the disk number to zero (or 'q' to quit): 1

Selected: Disk 1 - USB Storage Device

Opening \\.\PhysicalDrive1...
Disk size: 931.51 GB (1,000,204,886,016 bytes)
Block size: 1.00 MB
Total blocks: 954,037

============================================================
  WARNING: About to ZERO PhysicalDrive1
  Size: 931.51 GB
  ALL DATA WILL BE PERMANENTLY DESTROYED!
============================================================

Type 'YES' to confirm: YES

Zeroing drive...

  [########----------------------]  27.43%    255.42 GB /  931.51 GB  Speed:  102.17 MB/s  ETA:  1h 50m 12s
```

**Estimated Duration:**
| Connection | Speed       | ~1TB Drive |
|-----------|-------------|------------|
| USB 3.0   | ~100 MB/s   | ~2.5 hours |
| USB 3.1   | ~200 MB/s   | ~1.3 hours |
| USB 2.0   | ~30 MB/s    | ~8+ hours  |

**⚠️ Warning:**
- This tool **permanently and irreversibly destroys ALL data** on the selected disk
- Double-check you have selected the correct disk before confirming
- **Do not disconnect the drive** while the operation is running
- There is no way to recover data after this operation

**How it works:**
1. Uses PowerShell `Get-Disk` to enumerate all physical disks
2. Opens the selected disk using the Windows `CreateFileW` API for raw access
3. Writes 1MB blocks of zeros using `WriteFile` with `FILE_FLAG_NO_BUFFERING` and `FILE_FLAG_WRITE_THROUGH` flags
4. Reports progress every 0.5 seconds until the entire disk is zeroed
