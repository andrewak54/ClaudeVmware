# VMware Workstation 17.6.1 — Kernel 6.17 Patches

Patches to build and load VMware Workstation 17.6.1 kernel modules (`vmmon` and `vmnet`) on **Linux kernel 6.17** (Ubuntu 24.04 HWE).

## Environment

| Component | Version |
|-----------|---------|
| VMware Workstation | 17.6.1 (build-24319023) |
| Kernel | 6.17.0-14-generic |
| OS | Ubuntu 24.04.3 LTS (Noble Numbat) |
| Compiler | gcc-13 |

## Patches

| Patch | File(s) | Description |
|-------|---------|-------------|
| [0001](patches/0001-vmmon-vmnet-fix-BUILD_DIR-for-kernel-6.17-kbuild.patch) | `Makefile` (both) | Fix `BUILD_DIR` detection broken by `LINUXINCLUDE` containing multiple `-I` flags in kbuild context |
| [0002](patches/0002-vmmon-vmnet-add-ccflags-y-for-kernel-6.17.patch) | `Makefile.kernel` (both) | Add `ccflags-y` — `EXTRA_CFLAGS` is no longer processed by kbuild in kernel 6.17 |
| [0003](patches/0003-vmmon-compat-renamed-kernel-6.x-APIs.patch) | `vmmon-only/include/compat_version.h` | Compat defines for renamed APIs: `del_timer_sync` → `timer_delete_sync` (kernel 6.15) and `rdmsrl_safe` → `rdmsrq_safe` |
| [0004](patches/0004-vmmon-objtool-exclude-non-standard-flow-files.patch) | `vmmon-only/Makefile.kernel` | Exclude `phystrack.o` and `task.o` from objtool — VMware's `Panic()` isn't on objtool's noreturn whitelist; `Task_Switch()` uses non-standard crosspage assembly |
| [0005](patches/0005-vmnet-userif-fix-UACCESS-csum_partial_copy_nocheck.patch) | `vmnet-only/userif.c` | Replace `user_access_begin()` + `csum_partial_copy_nocheck()` with `csum_partial()` + `copy_to_user()` — kernel 6.17 objtool rejects the former pattern |

## Applying the Patches

```bash
# Extract VMware module sources
mkdir -p /tmp/vmware-fix/vmmon /tmp/vmware-fix/vmnet
tar xf /usr/lib/vmware/modules/source/vmmon.tar -C /tmp/vmware-fix/vmmon
tar xf /usr/lib/vmware/modules/source/vmnet.tar -C /tmp/vmware-fix/vmnet

# Apply patches
cd /tmp/vmware-fix
for p in /path/to/patches/*.patch; do patch -p1 < "$p"; done

# Repack (without build artifacts)
sudo tar cf /usr/lib/vmware/modules/source/vmmon.tar -C /tmp/vmware-fix/vmmon vmmon-only/
sudo tar cf /usr/lib/vmware/modules/source/vmnet.tar -C /tmp/vmware-fix/vmnet vmnet-only/

# Build and install
sudo vmware-modconfig --console --install-all
```

## After a Kernel Update

The patched tarballs in `/usr/lib/vmware/modules/source/` persist across kernel updates. After installing a new kernel, just run:

```bash
sudo vmware-modconfig --console --install-all
```
