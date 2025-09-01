# Happy Hare NixOS Flake - Usage Guide

## 🐛 Issue Fixed

The original error was caused by trying to build Happy Hare as a Python package when it's actually a Klipper extension. The flake has been updated to:

1. **Treat Happy Hare as a development environment** rather than a Python package
2. **Use `stdenv.mkDerivation`** instead of `buildPythonPackage`
3. **Provide proper file structure** for Klipper integration

## 🚀 How to Use

### 1. Add to Your NixOS Configuration

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    happy-hare = {
      url = "path:./path/to/this/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, happy-hare }:
    {
      nixosConfigurations.your-pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          happy-hare.nixosModules.happyHare
          {
            services.happyHare.enable = true;
          }
        ];
      };
    };
}
```

### 2. Enter Development Environment

```bash
# Enter the development shell
nix develop

# You'll see a welcome message with available tools
```

### 3. Install Happy Hare

```bash
# Run the installer
nix run .#install

# This will:
# - Set up Klipper integration
# - Configure Moonraker
# - Install configuration files
```

### 4. Build and Flash Firmware

```bash
# Build Klipper firmware for your Ender 3
nix run .#build

# Flash to your printer
nix run .#flash
```

## 📦 What's Available

### Development Shell (`nix develop`)
- **Python Environment**: All necessary packages for Happy Hare development
- **Build Tools**: GCC, Make, CMake for firmware building
- **Development Tools**: Git, Vim, debugging tools
- **Serial Tools**: AVRDUDE, STM32Flash for firmware flashing
- **ARM Cross-Compilation**: Tools for STM32 and other MCUs

### Apps (`nix run .#app-name`)
- **`install`**: Run the Happy Hare installer
- **`build`**: Build Klipper firmware
- **`flash`**: Flash firmware to printer

### Packages (`nix build .#package-name`)
- **`happyHare`**: Happy Hare development environment
- **`klipperFirmware`**: Klipper firmware build tools

### NixOS Module
- **`services.happyHare`**: System service for Happy Hare
- **Automatic integration** with Klipper and Moonraker

## 🔧 Development Workflow

1. **Enter development environment**:
   ```bash
   nix develop
   ```

2. **Install Happy Hare**:
   ```bash
   nix run .#install
   ```

3. **Configure your MMU**:
   - Edit files in `~/printer_data/config/mmu/`
   - Use the interactive installer for initial setup

4. **Build firmware**:
   ```bash
   cd $KLIPPER_HOME
   make menuconfig  # Configure for your board
   make            # Build firmware
   ```

5. **Flash firmware**:
   ```bash
   make flash FLASH_DEVICE=/dev/ttyACM0
   ```

## 🎯 For Ender 3

The flake is specifically configured for Ender 3:

- **MCU**: STM32F103
- **Architecture**: STMicroelectronics STM32
- **Bootloader**: 28KiB bootloader
- **Clock**: 8 MHz crystal
- **Communication**: USB (PA11/PA12)

## 🐛 Troubleshooting

### If you get permission errors:
```bash
sudo usermod -a -G dialout $USER
# Log out and back in
```

### If firmware won't flash:
- Check USB connection
- Verify device path (`/dev/ttyACM0` or `/dev/ttyUSB0`)
- Ensure printer is in bootloader mode

### If Python imports fail:
```bash
export PYTHONPATH="$KLIPPER_HOME/klippy:$MOONRAKER_HOME/moonraker:$PYTHONPATH"
```

## 📁 File Structure

After installation:
```
~/printer_data/config/
├── mmu/
│   ├── base/
│   │   ├── mmu.cfg
│   │   └── mmu_hardware.cfg
│   └── addons/
└── printer.cfg (includes mmu config)
```

## 🔄 Updates

To update your environment:
```bash
nix flake update
nix develop --recreate
```

---

**The flake is now ready to use! 🐰✨**