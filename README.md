# omarchy-amdgpu-guard

An [Omarchy](https://omarchy.org/) shell service that checks the AMD
graphics stack and tells you when part of it breaks: the kernel driver,
Vulkan for native and 32-bit (Steam/Proton) games, and VA-API video
decoding. Built on an iMac19,1 with a Radeon Pro 580X, after removing the
NVIDIA drivers that Steam had pulled in (see
[omarchy-steam-nvidia-cleanup](https://github.com/Thomster/omarchy-steam-nvidia-cleanup)),
to confirm the AMD side still works and keep watching it after updates.

No bar icon, no UI. 30 seconds after login and then hourly it runs the
check below. If something fails it sends one notification per boot. The
hourly re-runs catch amdgpu errors that only show up under load, like a
GPU reset during a game. It never changes anything and needs no root.

## What it checks

All checks run every time, even after one fails:

1. **Kernel driver:** every AMD GPU (PCI vendor `0x1002`, display class)
   is bound to `amdgpu`. On a machine with no AMD GPU the check exits 0
   and does nothing else.
2. **Vulkan, 64-bit:** `vulkaninfo --summary` lists a RADV device.
3. **Vulkan, 32-bit:** only if `lib32-vulkan-icd-loader` is installed
   (it comes with Steam). Arch has no 32-bit `vulkaninfo`, so this checks
   that the 32-bit RADV library exists and an ICD file points to it.
4. **VA-API:** `vainfo` on the GPU's render node uses Mesa's `radeonsi`
   driver and offers at least one decode profile.
5. **Vulkan ICD files:** every file in `/usr/share/vulkan/icd.d` and
   `/etc/vulkan/icd.d` points to a library that exists. A dangling ICD,
   such as `nvidia_icd.json` left without its driver, can make games
   and launchers pick a dead driver.
6. **Kernel log:** no amdgpu errors (priority `err` or worse) in this
   boot's kernel log. Skipped if your user can't read the journal.

| Exit | Meaning | Notification |
|---|---|---|
| `0` | All checks passed, or there's no AMD GPU | none |
| `1` | At least one check failed | critical, once per boot |
| `3` | Nothing failed, but `vainfo` or `vulkaninfo` is missing, so checks were skipped | low, once per boot |

## Requirements

```
sudo pacman -S --needed libva-utils vulkan-tools
```

`libva-utils` provides `vainfo`, `vulkan-tools` provides `vulkaninfo`.
Without them the plugin still runs the other checks and reports exit 3.

## Run it by hand

```
~/.config/omarchy/plugins/amdgpu-guard/bin/omarchy-amdgpu-guard
```

Sample output:

```
ok    kernel driver: 0000:01:00.0 uses amdgpu
ok    Vulkan 64-bit: AMD Radeon Pro 580X (RADV POLARIS10)
ok    Vulkan 32-bit: /usr/lib32/libvulkan_radeon.so
ok    VA-API: Mesa Gallium driver 26.2.2-arch1.1 for AMD Radeon Pro 580X (radeonsi, polaris10, ACO, DRM 3.64, 7.2.5-3-omarchy), 11 decode profiles
ok    Vulkan ICD files: all point to existing libraries
ok    kernel log: no amdgpu errors this boot
```

`--quiet` prints nothing and only sets the exit code.

## Install

```
omarchy plugin add https://github.com/Thomster/omarchy-amdgpu-guard.git --enable
```

## Related

Built like [omarchy-dkms-audio-guard](https://github.com/Thomster/omarchy-dkms-audio-guard)
and [omarchy-steam-nvidia-cleanup](https://github.com/Thomster/omarchy-steam-nvidia-cleanup).
For NVIDIA GPUs see [omarchy-nvidia-dkms-guard](https://github.com/Thomster/omarchy-nvidia-dkms-guard).

## Changelog

Current version: **1.0.0**. See [CHANGELOG.md](CHANGELOG.md).

## How this came to be

This is a personal customization for my own Omarchy setup, built with the
help of [Claude Code](https://claude.com/claude-code) (Anthropic's AI coding
agent). I'm not a professional plugin developer — please read through the
source before installing, and open an issue if something looks off.

## License

MIT
