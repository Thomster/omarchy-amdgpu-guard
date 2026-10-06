# Changelog

All notable changes to omarchy-amdgpu-guard. Versions follow [Semantic Versioning](https://semver.org/).

## 1.0.0 – 2026-10-06

### Added

- Initial release: read-only check of the amdgpu kernel driver, RADV Vulkan (64-bit via vulkaninfo, 32-bit via the lib32 ICD), VA-API decoding via vainfo, dangling Vulkan ICD files and amdgpu errors in this boot's kernel log; notifies once per boot and result.
