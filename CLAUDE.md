# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory is a working area for diagnosing and patching VMware Workstation kernel module compilation issues on Linux. It currently contains a VMware log (`vmware-3593.log`) capturing a failed module build.

## Environment

- **Host OS:** Ubuntu 24.04.3 LTS (Noble Numbat), x86_64
- **Kernel:** 6.17.0-14-generic
- **Kernel headers:** `/usr/src/linux-headers-6.17.0-14-generic`
- **Compiler:** gcc-13 (`/usr/bin/gcc`)
- **VMware Workstation:** 17.6.1 (build-24319023)

## Applied Fixes for Kernel 6.17 (Feb 2026)

Patches were applied to `/usr/lib/vmware/modules/source/` tarballs. `vmware-modconfig --console --install-all` now rebuilds and installs cleanly.

### vmmon fixes (`vmmon-only/`)
1. **`Makefile`**: Changed `BUILD_DIR` to always be `/lib/modules/$(VM_UNAME)/build` instead of deriving it from `$(HEADER_DIR)/..`. In kernel 6.17 kbuild context, `LINUXINCLUDE` contains multiple `-I...` flags; using it as `HEADER_DIR` corrupted `BUILD_DIR` and caused VM_KBUILD detection to fail, which fell back to the standalone (non-kbuild) build system.
2. **`Makefile.kernel`**: Added `ccflags-y := $(CC_OPTS) $(INCLUDE)` alongside `EXTRA_CFLAGS` — in kernel 6.17, `EXTRA_CFLAGS` is no longer processed by kbuild; `ccflags-y` is the modern replacement that carries the `-I./include` paths.
3. **`Makefile.kernel`**: Added `OBJECT_FILES_NON_STANDARD_common/phystrack.o := y` and `OBJECT_FILES_NON_STANDARD_common/task.o := y` — objtool fall-through/end-of-section errors for these files (VMware's `Panic()` is not on objtool's noreturn whitelist; `Task_Switch` uses non-standard crosspage assembly).
4. **`include/compat_version.h`**: Added compat defines `del_timer_sync → timer_delete_sync` (renamed in kernel 6.15) and `rdmsrl_safe → rdmsrq_safe` (MSR API rename in kernel 6.x).

### vmnet fixes (`vmnet-only/`)
1. **`Makefile`**: Same `BUILD_DIR` fix as vmmon.
2. **`Makefile.kernel`**: Added `ccflags-y` alongside `EXTRA_CFLAGS`.
3. **`userif.c`**: Fixed `VNetCsumAndCopyToUser()` for kernel ≥ 5.19 — replaced `user_access_begin()` + `csum_partial_copy_nocheck()` with `csum_partial()` + `copy_to_user()`. In kernel 6.17, objtool rejects `csum_partial_copy_nocheck()` being called within an active UACCESS region.

## Useful Commands

```bash
# Check VMware module status
modinfo vmmon
modinfo vmnet

# Manually trigger VMware module rebuild (as root)
vmware-modconfig --console --install-all

# View active VMware log
tail -f /tmp/vmware-$(id -u)/vmware-*.log

# Install kernel headers if missing
sudo apt install linux-headers-$(uname -r)

# Load modules manually after successful build
sudo modprobe vmmon
sudo modprobe vmnet

# Check kernel module load errors
dmesg | grep -i vmware
journalctl -k | grep -i vmware
```

## Re-applying After a Kernel Update

If a new kernel is installed:
1. Re-apply the same source patches to `/usr/lib/vmware/modules/source/` tarballs (extract, patch, repack without build artifacts, with `vmmon-only/` or `vmnet-only/` as the tar root).
2. Run `sudo vmware-modconfig --console --install-all` to rebuild for the new kernel.

The patched tarballs are preserved in `/usr/lib/vmware/modules/source/`, so `vmware-modconfig` will use them automatically.
