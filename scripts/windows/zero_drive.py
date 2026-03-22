"""
Zero Drive Utility - Securely wipe a physical disk by writing zeros to every sector.

This script writes zeros to every sector of a selected physical disk, effectively
performing a full disk wipe. It provides real-time progress reporting including
percentage complete, write speed, and estimated time remaining.

Requirements:
    - Windows OS
    - Python 3.6+
    - Administrator privileges (required for raw disk access)

Usage:
    1. Open Command Prompt as Administrator
    2. Run: python zero_drive.py
    3. Select the disk number from the list of detected disks
    4. Type 'YES' to confirm and begin zeroing

WARNING:
    This tool PERMANENTLY and IRREVERSIBLY destroys ALL data on the selected disk.
    Double-check you have selected the correct disk before confirming.
    There is no way to recover data after this operation.

Author: https://github.com/Joshwaamein
"""

import sys
import time
import ctypes
import struct
import subprocess
import json


def is_admin():
    """Check if running with administrator privileges."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except Exception:
        return False


def list_disks():
    """List all physical disks using PowerShell and return disk info."""
    try:
        result = subprocess.run(
            [
                "powershell", "-Command",
                "Get-Disk | Select-Object Number, FriendlyName, "
                "@{Name='SizeBytes';Expression={$_.Size}}, "
                "@{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}}, "
                "BusType, PartitionStyle | ConvertTo-Json"
            ],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            print(f"Error listing disks: {result.stderr}")
            return []

        data = json.loads(result.stdout)
        # Ensure it's always a list (single disk returns a dict)
        if isinstance(data, dict):
            data = [data]
        return data
    except Exception as e:
        print(f"Error listing disks: {e}")
        return []


def get_disk_size(handle):
    """Get the size of a physical disk using DeviceIoControl."""
    IOCTL_DISK_GET_LENGTH_INFO = 0x0007405C

    kernel32 = ctypes.windll.kernel32

    out_buf = ctypes.create_string_buffer(8)
    bytes_returned = ctypes.c_ulong(0)

    result = kernel32.DeviceIoControl(
        handle,
        IOCTL_DISK_GET_LENGTH_INFO,
        None, 0,
        out_buf, 8,
        ctypes.byref(bytes_returned),
        None
    )

    if not result:
        return None

    size = struct.unpack('<Q', out_buf.raw)[0]
    return size


def format_bytes(b):
    """Format bytes into human-readable string."""
    if b >= 1e12:
        return f"{b / 1e12:.2f} TB"
    elif b >= 1e9:
        return f"{b / 1e9:.2f} GB"
    elif b >= 1e6:
        return f"{b / 1e6:.2f} MB"
    elif b >= 1e3:
        return f"{b / 1e3:.2f} KB"
    return f"{b} B"


def format_time(seconds):
    """Format seconds into human-readable time string."""
    if seconds < 0:
        return "calculating..."
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    if hours > 0:
        return f"{hours}h {minutes:02d}m {secs:02d}s"
    elif minutes > 0:
        return f"{minutes}m {secs:02d}s"
    return f"{secs}s"


def select_disk(disks):
    """Display available disks and let the user select one."""
    print("\nDetected Physical Disks:")
    print("-" * 80)
    print(f"  {'Disk #':<8} {'Name':<35} {'Size':>10} {'Bus':>8} {'Partition':>12}")
    print("-" * 80)

    for disk in disks:
        num = disk.get("Number", "?")
        name = disk.get("FriendlyName", "Unknown")[:33]
        size_gb = disk.get("SizeGB", 0)
        bus = disk.get("BusType", "Unknown")
        partition = disk.get("PartitionStyle", "Unknown")

        # Format size nicely
        if size_gb >= 1000:
            size_str = f"{size_gb / 1000:.1f} TB"
        else:
            size_str = f"{size_gb:.1f} GB"

        print(f"  {num:<8} {name:<35} {size_str:>10} {bus:>8} {partition:>12}")

    print("-" * 80)
    print()

    while True:
        try:
            choice = input("Enter the disk number to zero (or 'q' to quit): ").strip()
            if choice.lower() == 'q':
                return None

            disk_number = int(choice)

            # Verify the disk number exists
            valid_numbers = [d.get("Number") for d in disks]
            if disk_number not in valid_numbers:
                print(f"  Invalid disk number. Valid options: {valid_numbers}")
                continue

            # Find the selected disk info
            selected = next(d for d in disks if d.get("Number") == disk_number)
            return selected

        except ValueError:
            print("  Please enter a valid number or 'q' to quit.")


def zero_drive(disk_number):
    """Zero the specified physical drive with progress reporting."""

    disk_path = f"\\\\.\\PhysicalDrive{disk_number}"
    block_size = 1024 * 1024  # 1 MB blocks
    zero_block = b'\x00' * block_size

    print(f"\nOpening {disk_path}...")

    # Open the physical drive using Windows API for raw access
    GENERIC_WRITE = 0x40000000
    GENERIC_READ = 0x80000000
    FILE_SHARE_READ = 0x00000001
    FILE_SHARE_WRITE = 0x00000002
    OPEN_EXISTING = 3
    FILE_FLAG_NO_BUFFERING = 0x20000000
    FILE_FLAG_WRITE_THROUGH = 0x80000000
    INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value

    kernel32 = ctypes.windll.kernel32
    kernel32.CreateFileW.restype = ctypes.c_void_p

    handle = kernel32.CreateFileW(
        disk_path,
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        None,
        OPEN_EXISTING,
        FILE_FLAG_NO_BUFFERING | FILE_FLAG_WRITE_THROUGH,
        None
    )

    if handle == INVALID_HANDLE_VALUE:
        error = ctypes.GetLastError()
        print(f"Error: Could not open {disk_path} (error code: {error})")
        if error == 5:
            print("Access denied. Please run this script as Administrator.")
        return False

    try:
        # Get disk size
        disk_size = get_disk_size(handle)
        if disk_size is None or disk_size == 0:
            print("Error: Could not determine disk size.")
            return False

        print(f"Disk size: {format_bytes(disk_size)} ({disk_size:,} bytes)")
        print(f"Block size: {format_bytes(block_size)}")
        print(f"Total blocks: {disk_size // block_size:,}")
        print()

        # Final confirmation
        print("=" * 60)
        print(f"  WARNING: About to ZERO PhysicalDrive{disk_number}")
        print(f"  Size: {format_bytes(disk_size)}")
        print(f"  ALL DATA WILL BE PERMANENTLY DESTROYED!")
        print("=" * 60)

        response = input("\nType 'YES' to confirm: ").strip()
        if response != 'YES':
            print("Aborted.")
            return False

        print("\nZeroing drive...\n")

        bytes_written_total = 0
        start_time = time.time()
        last_print_time = start_time

        # Write zeros
        bytes_to_write = ctypes.c_ulong(block_size)
        bytes_actually_written = ctypes.c_ulong(0)

        while bytes_written_total < disk_size:
            # Adjust last block size if needed
            remaining = disk_size - bytes_written_total
            if remaining < block_size:
                # Round down to sector size (512 bytes) for alignment
                current_block_size = (remaining // 512) * 512
                if current_block_size == 0:
                    break
                current_block = b'\x00' * current_block_size
                bytes_to_write = ctypes.c_ulong(current_block_size)
            else:
                current_block = zero_block
                bytes_to_write = ctypes.c_ulong(block_size)

            buf = ctypes.create_string_buffer(current_block)

            success = kernel32.WriteFile(
                handle,
                buf,
                bytes_to_write,
                ctypes.byref(bytes_actually_written),
                None
            )

            if not success:
                error = ctypes.GetLastError()
                if bytes_written_total > disk_size * 0.99:
                    print(f"\nReached near end of disk. Written: {format_bytes(bytes_written_total)}")
                    break
                print(f"\nWrite error at offset {bytes_written_total:,} (error code: {error})")
                break

            bytes_written_total += bytes_actually_written.value

            # Update progress every 0.5 seconds
            current_time = time.time()
            if current_time - last_print_time >= 0.5:
                elapsed = current_time - start_time
                percent = (bytes_written_total / disk_size) * 100
                speed = bytes_written_total / elapsed if elapsed > 0 else 0

                if speed > 0:
                    eta = (disk_size - bytes_written_total) / speed
                else:
                    eta = -1

                # Progress bar
                bar_width = 30
                filled = int(bar_width * bytes_written_total // disk_size)
                bar = '#' * filled + '-' * (bar_width - filled)

                print(
                    f"\r  [{bar}] {percent:6.2f}%  "
                    f"{format_bytes(bytes_written_total):>10} / {format_bytes(disk_size):>10}  "
                    f"Speed: {format_bytes(speed):>10}/s  "
                    f"ETA: {format_time(eta):>12}",
                    end='', flush=True
                )
                last_print_time = current_time

        # Final stats
        elapsed = time.time() - start_time
        avg_speed = bytes_written_total / elapsed if elapsed > 0 else 0

        print(f"\n\n{'=' * 60}")
        print(f"  COMPLETE!")
        print(f"  Total written: {format_bytes(bytes_written_total)}")
        print(f"  Time elapsed:  {format_time(elapsed)}")
        print(f"  Average speed: {format_bytes(avg_speed)}/s")
        print(f"{'=' * 60}")

        # Flush
        kernel32.FlushFileBuffers(handle)

        return True

    finally:
        kernel32.CloseHandle(handle)


def main():
    print("=" * 60)
    print("  DISK ZERO UTILITY")
    print("  Securely wipe a disk by writing zeros to every sector")
    print("=" * 60)

    # Check admin
    if not is_admin():
        print("\nERROR: This script must be run as Administrator!")
        print("Right-click Command Prompt -> Run as Administrator")
        sys.exit(1)

    print("\nRunning with Administrator privileges.")

    # List and select disk
    disks = list_disks()
    if not disks:
        print("No disks detected. Exiting.")
        sys.exit(1)

    selected = select_disk(disks)
    if selected is None:
        print("No disk selected. Exiting.")
        sys.exit(0)

    disk_number = selected["Number"]
    disk_name = selected.get("FriendlyName", "Unknown")

    print(f"\nSelected: Disk {disk_number} - {disk_name}")

    zero_drive(disk_number)


if __name__ == "__main__":
    main()
