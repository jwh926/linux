# Linux Kernel Repository – Rebase Summary

This repository was rebased from **Linux 7.0-rc1** onto the upstream
`torvalds/linux` tree (7.0-rc5 plus post-rc5 fixes heading toward rc6).
Below is a brief summary of the notable changes introduced across each
release-candidate cycle.

---

## 7.0-rc2 (2026-03-02)
_193 files changed, 2508 insertions(+), 1191 deletions(−)_

- **BPF:** fix races in `devmap`/`cpumap` on `PREEMPT_RT`; fix
  stack-out-of-bounds write in `devmap`; improve tnum bounds when a
  single value is known; delay-free special fields to close a
  use-after-free window; fix `kprobe_multi` cookies in `show_fdinfo`.
- **KVM:** always define `KVM_CAP_SYNC_MMU`; remove
  `CONFIG_KVM_GENERIC_MMU_NOTIFIER`.
- **s390:** fix virtual timer forwarding; fix cpu idle-exit time
  accounting; fix virtual vs physical address confusion in pfault;
  disable stack protector in `s390_reset_system()`.
- **SMB client:** fix broken multichannel with krb5+signing; avoid
  logging plaintext credentials; use `atomic_t` for `mnt_cifs_flags`.
- **SPI/regulator:** fix missing pointer assignment in STM32 DMA
  chaining; fix device-node reference leak in `bq257xx`.
- **SCSI/UFS:** fix shift-out-of-bounds when `MAXQ=32`; fix possible
  NULL dereference in `ufshcd_add_command_trace()`.
- **arm64 (JIT):** force 8-byte alignment for JIT buffer to prevent
  atomic tearing.
- **Firewire:** initialize page array correctly for `alloc_pages_bulk()`.

---

## 7.0-rc3 (2026-03-09)
_523 files changed, 6505 insertions(+), 2737 deletions(−)_

- **BPF:** fix u32/s32 bounds when ranges cross min/max boundary; fix
  precision back-tracking bug with linked registers; drop
  `kthread_exit` from `noreturn_deny`.
- **Tracing:** fix `trace_buf_size=` command-line parameter for sizes
  ≥ 2 GB; fix enabling multiple events on the kernel command line and
  bootconfig; add NULL pointer check to `trigger_data_free()`.
- **epoll:** convert `epoll_put_uevent()` to scoped user access.
- **arm64:** fix `set_access_flags()` no-op check for SMMU/ATS faults
  in contpte paths; fix `sve2p1_sigill()` hwcap selftest.
- **parisc:** fix initial page-table creation for boot; check kernel
  mapping earlier at bootup; increase initial mapping to 64 MB with
  `KALLSYMS`.
- **ATA:** fix detection of deferred `qc` timeouts in `libata-eh`.
- **SMB client:** fix oops due to uninitialized variable in
  `smb2_unlink()`.
- **DRM/panthor:** correct argument order in `gem_sync`.
- **kbuild:** fix linker-flags detection in `resolve_btfids`.
- **Memory:** require reasonably normal mappings for `MADV_DOFORK`.
- **RCU:** multiple torture-test updates for x86 preemption model
  restrictions.

---

## 7.0-rc4 (2026-03-16)
_537 files changed, 6363 insertions(+), 4005 deletions(−)_

- **BPF:** fix NULL dereference in `bpf_out_neigh_v4/v6` when IPv6 is
  disabled; fix precision backtracking with linked registers.
- **Networking:** prevent NULL deref in `ip[6]tunnel_xmit()`; fix
  divide-by-zero in `tipc_sk_filter_connect()`; restore
  `protocol != 0` check in `pneigh` update; fix LED group port bits
  in DSA Realtek; fix PTP IRQ setup error path in DSA Microchip.
- **KVM:** multiple fixes across arm64, s390, and x86 (SEV).
- **Kprobes:** avoid crash on `rmmod`/`insmod` after ftrace killed;
  remove unneeded warnings from `__arm_kprobe_ftrace()`.
- **io_uring:** check if target buffer list is still legacy on recycle.
- **bootconfig:** fix off-by-one in `xbc_verify_tree()`; fix bounds
  check before writing in `__xbc_open_brace()`; fix snprintf
  truncation check.
- **Rust:** allow `unused_features` in kbuild; fix `double_parens`
  clippy warning; replace shadowed `return` token in `pin-init`.
- **powerpc:** fix KUAP warning in VMX usercopy path; fix lockdep
  warning during PCI enumeration; fix `perf` user-callchain
  with a dead mm.
- **USB:** add `USB_QUIRK_NO_BOS` for ezcap401 at 10 Gbps speed.
- **Workqueue / cgroup / sched_ext:** multiple rc3 fixes merged.
- **XFS / Ceph / SMB:** various filesystem fixes.

---

## 7.0-rc5 (2026-03-23)
_332 files changed, 3559 insertions(+), 1498 deletions(−)_

- **BPF:** fix unsound scalar forking in `maybe_fork_scalars()` for
  `BPF_OR`; fix `INT_MIN` undefined behavior in interpreter `sdiv`/`smod`;
  fix `sync_linked_regs` zext propagation; fix exception-exit lock
  checking for sub-programs.
- **Tracing/ftrace:** fix `trace_marker` copy/linked-list updates; fix
  failure to read user space from syscall trace events; fix
  `update_ftrace_direct_mod()` hash argument; revert
  "Remove pid in task_rename tracing output".
- **ring-buffer:** fix per-subbuf entries update for persistent ring
  buffer.
- **io_uring:** fix missing `BUF_MORE` for incremental buffers at EOF;
  propagate `BUF_MORE` through early buffer-commit path.
- **DRM/xe:** fix missing runtime-PM reference in `ccs_mode_store`;
  fix GGTT MMIO access protection.
- **i2c:** fix IRQ-safe marking for Tegra devices with pins; fix fsi
  probe leak; fix `cp2615` serial-string NULL deref; defer reset on
  Armada 3700 when recovery is used.
- **ATA:** report correct sense field pointer in `ata_scsiop_maint_in()`.
- **hwmon/max6639:** fix pulses-per-revolution implementation.
- **MPTCP:** fix lock-class name family in `pm_nl_create_listen_socket`.
- **ICMP:** fix NULL pointer dereference in `icmp_tag_validation()`.
- **SMB client:** fix generic/694 due to wrong `->i_blocks`.
- **x86:** fix deconfigured-socket handling in UV platform; fix vDSO
  gettimeofday include path.
- **driver-core, tty, execve, iommu, MTD, MMC, ATA, pmdomain:**
  assorted stable fixes merged.

---

## Post-rc5 / rc6-bound fixes (through 2026-03-25)
_68 files changed, 783 insertions(+), 288 deletions(−)_

- **RCU/SRCU:** use `irq_work` to start grace periods in tiny SRCU;
  push `srcu_node` allocation to GP when non-preemptible; use raw
  spinlocks so `call_srcu()` can be used under `preempt_disable()`.
- **erofs:** fix `.fadvise()` for page-cache sharing.
- **mm/zswap:** add missing `kunmap_local()`.
- **mm/DAMON:** monitor all System RAM resources; avoid use of
  half-online-committed context.
- **mm/rmap:** clear `vma->anon_vma` on error.
- **zram:** do not `slot_free()` written-back slots.
- **platform/x86:** ISST locked-bit-width correction and HWP guard;
  intel-hid wakeup-mode during hibernation; new ASUS ROG Flow Z13 /
  G614FP / GA503QM armoury entries; new HP Omen 16 WMI entries;
  lenovo wmi-gamezone cleanup.
- **KVM:** arm64 fixes (GCS, kvmarm-fixes-7.0-4); s390 IRQ routing
  selftest; x86 KVM header syncs.
- **Xen:** XSA-482 security fix merged.
- **kbuild:** fixes-7.0-3 merged.
- **Media:** v7.0-5 fixes merged.
- **CXL:** fixes for 7.0-rc6 merged.

---

## Overall statistics (rc1 → current)
| Cycle     | Files changed | Insertions | Deletions |
|-----------|--------------|------------|-----------|
| rc1→rc2   | 193          | +2,508     | −1,191    |
| rc2→rc3   | 523          | +6,505     | −2,737    |
| rc3→rc4   | 537          | +6,363     | −4,005    |
| rc4→rc5   | 332          | +3,559     | −1,498    |
| rc5→HEAD  | 68           | +783       | −288      |
| **Total** | **1,653**    | **+19,718**| **−9,719**|
