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

## Compatibility

See [status.md](status.md) for tested kernel/OS combinations.

## Applying the Patches

```bash
git clone https://github.com/andrewak54/ClaudeVmware
cd ClaudeVmware
sudo bash apply-patches.sh
```

The script extracts the VMware source tarballs, applies all patches, repacks them, and runs `vmware-modconfig --console --install-all`.

## After a Kernel Update

The patched tarballs in `/usr/lib/vmware/modules/source/` persist across kernel updates. After installing a new kernel, just run:

```bash
sudo vmware-modconfig --console --install-all
```
