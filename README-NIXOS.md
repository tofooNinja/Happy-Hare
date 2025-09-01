# Happy Hare NixOS Development Environment

This flake provides a complete development environment for Happy Hare MMU development on NixOS Raspberry Pi, including Klipper firmware building and flashing capabilities.

## 🐰 What's Included

- **Python Development Environment**: All necessary Python packages for Happy Hare development
- **Klipper Integration**: Klipper source code and firmware building tools
- **Moonraker Support**: Moonraker integration for web interface
- **ARM Cross-Compilation**: Tools for building firmware for various MCUs
- **Development Tools**: Code formatting, linting, testing, and debugging tools
- **Serial Communication**: Tools for flashing firmware to your Ender 3

## 🚀 Quick Start

### 1. Add to your NixOS Configuration

Add this flake to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    happy-hare = {
      url = "path:./path/to/happy-hare-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, happy-hare }:
    {
      nixosConfigurations.your-pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          # Your existing modules...
          happy-hare.nixosModules.happyHare
          {
            services.happyHare.enable = true;
            # Optional: customize paths
            services.happyHare.klipperConfig = "/home/klipper/printer_data/config";
            services.happyHare.klipperHome = "/home/klipper/klipper";
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

# Or use the flake directly
nix develop .#default
```

### 3. Build and Flash Klipper Firmware

```bash
# Build firmware for your Ender 3
nix run .#build

# Flash to your printer
nix run .#flash
```

## 🔧 Development Workflow

### Setting up Happy Hare

1. **Enter the development environment**:
   ```bash
   nix develop
   ```

2. **Install Happy Hare**:
   ```bash
   nix run .#install
   ```

3. **Configure your printer**:
   - Edit configuration files in `~/printer_data/config/mmu/`
   - Use the interactive installer for initial setup

### Building Firmware

1. **Configure Klipper**:
   ```bash
   cd $KLIPPER_HOME
   make menuconfig
   ```
   
   Select your board (for Ender 3, typically):
   - **Micro-controller Architecture**: STMicroelectronics STM32
   - **Processor model**: STM32F103
   - **Bootloader offset**: 28KiB bootloader
   - **Clock Reference**: 8 MHz crystal
   - **Communication interface**: USB (on PA11/PA12)

2. **Build the firmware**:
   ```bash
   make
   ```

3. **Flash to your printer**:
   ```bash
   make flash FLASH_DEVICE=/dev/ttyACM0
   ```

### Testing Happy Hare

```bash
# Run tests
cd extras/mmu
python3 -m pytest test/

# Run linting
flake8 .
black .
mypy .

# Test MMU functionality
python3 mmu.py --help
```

## 📁 Project Structure

```
.
├── flake.nix              # Main flake configuration
├── README-NIXOS.md        # This file
├── extras/
│   └── mmu/              # Happy Hare MMU modules
├── components/            # Moonraker components
├── config/               # Configuration templates
└── install.sh            # Installation script
```

## 🛠️ Available Commands

### Development Commands

- `nix develop` - Enter development environment
- `nix run .#install` - Install Happy Hare
- `nix run .#build` - Build Klipper firmware
- `nix run .#flash` - Flash firmware to printer

### Package Commands

- `nix build .#happyHare` - Build Happy Hare package
- `nix build .#klipperFirmware` - Build Klipper firmware package

## 🔌 Hardware Setup

### Ender 3 with MMU

1. **Connect your MMU** to the appropriate pins on your Ender 3
2. **Install sensors** (filament runout, gate sensors, etc.)
3. **Configure hardware** in `mmu_hardware.cfg`
4. **Test connections** using Happy Hare's built-in testing tools

### Common MMU Types Supported

- ERCF
- Tradrack
- Box Turtle
- Angry Beaver
- Night Owl
- 3MS
- 3D Chameleon
- QuattroBox
- PicoMMU
- Custom designs

## 🐛 Troubleshooting

### Common Issues

1. **Permission denied on serial port**:
   ```bash
   sudo usermod -a -G dialout $USER
   # Log out and back in
   ```

2. **Firmware won't flash**:
   - Check USB connection
   - Verify correct device path (`/dev/ttyACM0` or `/dev/ttyUSB0`)
   - Ensure printer is in bootloader mode

3. **Python import errors**:
   ```bash
   export PYTHONPATH="$KLIPPER_HOME/klippy:$MOONRAKER_HOME/moonraker:$PYTHONPATH"
   ```

### Getting Help

- Check the [Happy Hare Wiki](https://github.com/moggieuk/Happy-Hare/wiki)
- Join the [Discord community](https://discord.gg/aABQUjkZPk)
- Review Klipper documentation for firmware issues

## 🔄 Updates

To update your development environment:

```bash
# Update flake inputs
nix flake update

# Rebuild environment
nix develop --recreate
```

## 📝 Configuration Examples

### Basic MMU Configuration

```ini
# ~/printer_data/config/mmu/base/mmu.cfg
[mmu]
enable: True
# Add your MMU configuration here
```

### Hardware Configuration

```ini
# ~/printer_data/config/mmu/base/mmu_hardware.cfg
[mmu_servo selector_servo]
pin: mmu:MMU_SERVO
# Add your hardware configuration here
```

## 🤝 Contributing

1. Fork the Happy Hare repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This flake is provided under the same license as Happy Hare (GPLv3).

---

**Happy printing! 🐰🎨**