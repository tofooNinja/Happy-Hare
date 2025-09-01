# Simple Happy Hare installation for NixOS
# This bypasses the complex install.sh script and sets up Happy Hare manually

{ pkgs ? import <nixpkgs> {} }:

let
  simpleInstall = pkgs.writeShellScript "simple-install" ''
    echo "🐰 Simple Happy Hare Installation for NixOS"
    echo "=========================================="
    
    # Set up directories
    KLIPPER_HOME="$HOME/klipper"
    MOONRAKER_HOME="$HOME/moonraker"
    CONFIG_HOME="$HOME/printer_data/config"
    
    echo "Setting up directories..."
    mkdir -p "$KLIPPER_HOME"
    mkdir -p "$MOONRAKER_HOME"
    mkdir -p "$CONFIG_HOME"
    mkdir -p "$CONFIG_HOME/mmu/base"
    mkdir -p "$CONFIG_HOME/mmu/addons"
    
    echo "Klipper home: $KLIPPER_HOME"
    echo "Moonraker home: $MOONRAKER_HOME"
    echo "Config home: $CONFIG_HOME"
    
    # Copy Happy Hare files
    echo "Copying Happy Hare files..."
    
    # Copy MMU modules to Klipper
    if [ -d "${toString ./.}/extras/mmu" ]; then
      echo "Installing MMU modules to Klipper..."
      mkdir -p "$KLIPPER_HOME/klippy/extras/mmu"
      cp -r ${toString ./.}/extras/mmu/* "$KLIPPER_HOME/klippy/extras/mmu/"
    fi
    
    # Copy Moonraker components
    if [ -d "${toString ./.}/components" ]; then
      echo "Installing Moonraker components..."
      mkdir -p "$MOONRAKER_HOME/moonraker/components"
      cp -r ${toString ./.}/components/* "$MOONRAKER_HOME/moonraker/components/"
    fi
    
    # Copy configuration templates
    if [ -d "${toString ./.}/config" ]; then
      echo "Installing configuration templates..."
      cp -r ${toString ./.}/config/* "$CONFIG_HOME/mmu/"
    fi
    
    # Create basic printer.cfg if it doesn't exist
    if [ ! -f "$CONFIG_HOME/printer.cfg" ]; then
      echo "Creating basic printer.cfg..."
      cat > "$CONFIG_HOME/printer.cfg" << 'EOF'
# Basic Klipper configuration for Happy Hare
# Add your printer configuration here

[mcu]
serial: /dev/ttyACM0

[printer]
kinematics: cartesian
max_velocity: 300
max_accel: 3000
max_z_velocity: 5
max_z_accel: 100

# Include Happy Hare configuration
[include mmu/base/mmu.cfg]
[include mmu/base/mmu_hardware.cfg]

# Add your printer-specific configuration below
EOF
    fi
    
    # Create basic mmu.cfg
    if [ ! -f "$CONFIG_HOME/mmu/base/mmu.cfg" ]; then
      echo "Creating basic mmu.cfg..."
      cat > "$CONFIG_HOME/mmu/base/mmu.cfg" << 'EOF'
# Happy Hare MMU Configuration
# This is a basic configuration - customize for your MMU

[mmu]
enable: True
# Add your MMU configuration here
EOF
    fi
    
    # Create basic mmu_hardware.cfg
    if [ ! -f "$CONFIG_HOME/mmu/base/mmu_hardware.cfg" ]; then
      echo "Creating basic mmu_hardware.cfg..."
      cat > "$CONFIG_HOME/mmu/base/mmu_hardware.cfg" << 'EOF'
# Happy Hare Hardware Configuration
# Configure your MMU hardware here

# Example for a basic servo-based selector
[mmu_servo selector_servo]
pin: mmu:MMU_SERVO
# Add your hardware configuration here
EOF
    fi
    
    echo ""
    echo "✅ Happy Hare installation completed!"
    echo ""
    echo "Next steps:"
    echo "1. Edit $CONFIG_HOME/printer.cfg for your printer"
    echo "2. Edit $CONFIG_HOME/mmu/base/mmu_hardware.cfg for your MMU"
    echo "3. Edit $CONFIG_HOME/mmu/base/mmu.cfg for MMU settings"
    echo "4. Build and flash Klipper firmware"
    echo ""
    echo "For help, see: https://github.com/moggieuk/Happy-Hare/wiki"
  '';
in
  simpleInstall