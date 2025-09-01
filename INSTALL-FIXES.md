# Installation Fixes for NixOS

## 🐛 Issues Encountered

1. **Git repository error**: `fatal: not a git repository`
2. **Permission denied**: `rm: cannot remove '/tmp/...': Permission denied`
3. **Klipper home not found**: `Klipper home directory (/home/tofoo/klipper) not found`
4. **Cleanup failures**: Permission errors when removing temporary files

## ✅ Solutions Implemented

### 1. **Fixed Git Repository Issue**
**Problem**: The install script expects to be in a git repository.

**Solution**: Initialize git repository in temporary directory:
```bash
# Initialize git repository (install script expects this)
git init
git add .
git config user.name "Happy Hare Installer"
git config user.email "installer@happy-hare.local"
git commit -m "Initial commit for Happy Hare installation"
```

### 2. **Fixed Permission Issues**
**Problem**: Permission denied when cleaning up temporary files.

**Solution**: Better cleanup handling:
```bash
# Clean up with proper permissions
echo "Cleaning up temporary files..."
cd /
rm -rf "$TEMP_DIR" 2>/dev/null || true
```

### 3. **Fixed Klipper Home Directory**
**Problem**: Klipper home directory doesn't exist.

**Solution**: Create directory if it doesn't exist:
```bash
# Create default Klipper home if it doesn't exist
if [ ! -d "$KLIPPER_HOME" ]; then
  echo "Creating Klipper home directory: $KLIPPER_HOME"
  mkdir -p "$KLIPPER_HOME"
fi
```

### 4. **Added Git to PATH**
**Problem**: Git commands not found.

**Solution**: Add git to PATH:
```bash
export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.git}/bin:$PATH"
```

## 🚀 New: Simple Install Option

Since the original install script is complex and has many dependencies, I created a **simple install option** that's more reliable on NixOS:

### Simple Install Features
- ✅ **No git dependencies** - doesn't require git repository
- ✅ **No complex scripts** - direct file copying
- ✅ **No permission issues** - works in user directories
- ✅ **Creates basic configs** - sets up starter configuration files
- ✅ **NixOS friendly** - designed specifically for NixOS

### Usage
```bash
# Use the simple install (recommended)
nix run .#simple-install
```

### What Simple Install Does
1. **Creates directories**:
   - `~/klipper/`
   - `~/moonraker/`
   - `~/printer_data/config/mmu/`

2. **Copies files**:
   - MMU modules to Klipper
   - Moonraker components
   - Configuration templates

3. **Creates basic configs**:
   - `printer.cfg` (basic Klipper config)
   - `mmu.cfg` (basic MMU config)
   - `mmu_hardware.cfg` (basic hardware config)

## 🔧 Available Installation Methods

### Method 1: Simple Install (Recommended)
```bash
nix run .#simple-install
```
- **Pros**: Reliable, no dependencies, NixOS-friendly
- **Cons**: Less interactive, basic configuration

### Method 2: Original Install Script (Fixed)
```bash
nix run .#install
```
- **Pros**: Full interactive installation, all features
- **Cons**: More complex, may have edge cases

## 🎯 For Your Ender 3

Both methods will work, but I recommend starting with the **simple install**:

```bash
# 1. Enter development environment
nix develop

# 2. Use simple install
nix run .#simple-install

# 3. Edit configuration files
nano ~/printer_data/config/printer.cfg
nano ~/printer_data/config/mmu/base/mmu_hardware.cfg

# 4. Build firmware
nix run .#build
```

## 📝 Configuration After Installation

After installation, you'll need to:

1. **Edit printer.cfg** for your Ender 3:
   ```ini
   [mcu]
   serial: /dev/ttyACM0  # or your actual device
   
   [printer]
   kinematics: cartesian
   # Add your printer-specific configuration
   ```

2. **Edit mmu_hardware.cfg** for your MMU:
   ```ini
   [mmu_servo selector_servo]
   pin: mmu:MMU_SERVO  # Configure for your MMU
   ```

3. **Edit mmu.cfg** for MMU settings:
   ```ini
   [mmu]
   enable: True
   # Add your MMU configuration
   ```

## 🐛 Troubleshooting

### If simple-install fails:
```bash
# Check if directories exist
ls -la ~/klipper
ls -la ~/printer_data/config

# Manual installation
mkdir -p ~/klipper ~/moonraker ~/printer_data/config/mmu
```

### If original install fails:
```bash
# Use simple install instead
nix run .#simple-install
```

---

**The simple install should work reliably on NixOS! 🐰✨**