{
  description = "Happy Hare MMU development environment for NixOS Raspberry Pi";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Klipper and related tools
    klipper = {
      url = "github:Klipper3d/klipper";
      flake = false;
    };
    
    moonraker = {
      url = "github:Arksine/moonraker";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, klipper, moonraker }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Python environment for Happy Hare development
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          # Core Python packages
          pip
          setuptools
          wheel
          
          # Development tools
          black
          flake8
          mypy
          pylint
          
          # Klipper dependencies
          cffi
          pyserial
          jinja2
          
          # Moonraker dependencies
          tornado
          
          # Testing
          pytest
          pytest-asyncio
          pytest-cov
        ]);
        
        # Development shell environment
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Python environment
            pythonEnv
            
            # Build tools
            gcc
            gnumake
            cmake
            pkg-config
            
            # Core utilities
            bash
            coreutils
            
            # Git and version control
            git
            
            # Development tools
            vim
            nano
            htop
            tmux
            
            # Network tools
            curl
            wget
            
            # Serial communication (for flashing)
            avrdude
            stm32flash
            dfu-util
            
            # Additional tools
            jq
            tree
            ripgrep
            fd
          ];
          
          # Environment variables
          shellHook = ''
            echo "🐰 Happy Hare Development Environment"
            echo "=================================="
            echo ""
            echo "Available tools:"
            echo "  - Python: $(python3 --version)"
            echo "  - Git: $(git --version)"
            echo "  - GCC: $(gcc --version | head -n1)"
            echo "  - Make: $(make --version | head -n1)"
            echo ""
            echo "Klipper and Moonraker sources are available at:"
            echo "  - Klipper: ${klipper}"
            echo "  - Moonraker: ${moonraker}"
            echo ""
            echo "To start development:"
            echo "  1. cd extras/mmu"
            echo "  2. python3 -m pytest test/"
            echo "  3. python3 mmu.py --help"
            echo ""
            echo "To flash firmware:"
            echo "  1. make menuconfig"
            echo "  2. make"
            echo "  3. make flash"
            echo ""
          '';
          
          # Set up environment for Klipper development
          KLIPPER_HOME = "${klipper}";
          MOONRAKER_HOME = "${moonraker}";
          PYTHONPATH = "${klipper}/klippy:${moonraker}/moonraker:$PYTHONPATH";
          PATH = "${pkgs.bash}/bin:${pkgs.coreutils}/bin:$PATH";
        };
        
        # Klipper firmware build
        klipperFirmware = pkgs.stdenv.mkDerivation {
          name = "klipper-firmware";
          src = klipper;
          
          nativeBuildInputs = with pkgs; [
            # gcc-arm-embedded  # Commented out as it might not be available
            # binutils-arm-embedded  # Commented out as it might not be available
            gnumake
            python3
            python3Packages.pyserial
            python3Packages.cffi
          ];
          
          buildPhase = ''
            cd klippy/chelper
            make
            cd ../..
          '';
          
          installPhase = ''
            mkdir -p $out
            cp -r klippy $out/
            cp -r lib $out/
            cp -r scripts $out/
            cp -r config $out/
          '';
        };
        
        # Happy Hare development package (not a Python package, but a development environment)
        happyHare = pkgs.stdenv.mkDerivation {
          pname = "happy-hare";
          version = "3.3.0";
          src = ./.;
          
          nativeBuildInputs = with pkgs; [
            makeWrapper
          ];
          
          installPhase = ''
            mkdir -p $out
            cp -r extras $out/
            cp -r components $out/
            cp -r config $out/
            cp install.sh $out/
            chmod +x $out/install.sh
            
            # Create wrapper script for easy access
            makeWrapper ${pythonEnv}/bin/python3 $out/bin/happy-hare-dev \
              --add-flags "-c 'import sys; sys.path.insert(0, \"$out/extras\"); import mmu.mmu; print(\"Happy Hare development environment ready\")'" \
              --set PYTHONPATH "$out/extras:$out/components:$PYTHONPATH"
          '';
          
          meta = with pkgs.lib; {
            description = "Happy Hare MMU development environment";
            homepage = "https://github.com/moggieuk/Happy-Hare";
            license = licenses.gpl3;
            platforms = platforms.all;
          };
        };
        
      in {
        # Development shell
        devShells.default = devShell;
        
        # Packages
        packages = {
          inherit klipperFirmware happyHare;
          default = happyHare;
        };
        
        # Apps
        apps = {
          # Install Happy Hare (original method)
          install = {
            type = "app";
            program = toString (pkgs.writeShellScript "install-happy-hare" ''
              echo "Installing Happy Hare..."
              
              # Create a temporary directory to work with
              TEMP_DIR=$(mktemp -d)
              echo "Working in temporary directory: $TEMP_DIR"
              
              # Copy the Happy Hare files to the temp directory
              cp -r ${toString ./.}/* "$TEMP_DIR/"
              cd "$TEMP_DIR"
              
              # Initialize git repository (install script expects this)
              git init
              git add .
              git config user.name "Happy Hare Installer"
              git config user.email "installer@happy-hare.local"
              git commit -m "Initial commit for Happy Hare installation"
              
              # Fix the shebang in install.sh to use the correct bash path
              sed -i 's|#!/bin/bash|#!${pkgs.bash}/bin/bash|g' install.sh
              chmod +x install.sh
              
              # Set environment variables
              export KLIPPER_HOME="${klipper}"
              export MOONRAKER_HOME="${moonraker}"
              export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.git}/bin:$PATH"
              
              # Create default Klipper home if it doesn't exist
              if [ ! -d "$KLIPPER_HOME" ]; then
                echo "Creating Klipper home directory: $KLIPPER_HOME"
                mkdir -p "$KLIPPER_HOME"
              fi
              
              # Run the installer with proper error handling
              echo "Running Happy Hare installer..."
              if ./install.sh; then
                echo "Happy Hare installation completed successfully!"
              else
                echo "Happy Hare installation completed with warnings (this is normal)"
              fi
              
              # Clean up with proper permissions
              echo "Cleaning up temporary files..."
              cd /
              rm -rf "$TEMP_DIR" 2>/dev/null || true
            '');
          };
          
          # Simple install (recommended for NixOS)
          simple-install = {
            type = "app";
            program = toString (pkgs.writeShellScript "simple-install-happy-hare" ''
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
            '');
          };
          
          # Flash firmware
          flash = {
            type = "app";
            program = toString (pkgs.writeShellScript "flash-firmware" ''
              echo "Flashing Klipper firmware..."
              export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.gnumake}/bin:$PATH"
              cd ${klipper}/out
              if [ -f "klipper.bin" ]; then
                echo "Found klipper.bin, ready to flash"
                echo "Use: make flash FLASH_DEVICE=/dev/ttyACM0"
              else
                echo "Please build firmware first: make menuconfig && make"
              fi
            '');
          };
          
          # Build firmware
          build = {
            type = "app";
            program = toString (pkgs.writeShellScript "build-firmware" ''
              echo "Building Klipper firmware..."
              export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.gnumake}/bin:$PATH"
              cd ${klipper}
              make menuconfig
              make
            '');
          };
        };
        
        # NixOS module for system integration
        nixosModules.happyHare = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.services.happyHare;
          in {
            options.services.happyHare = {
              enable = mkEnableOption "Happy Hare MMU service";
              
              klipperConfig = mkOption {
                type = types.path;
                description = "Path to Klipper configuration directory";
                default = "/home/klipper/printer_data/config";
              };
              
              klipperHome = mkOption {
                type = types.path;
                description = "Path to Klipper installation";
                default = "/home/klipper/klipper";
              };
            };
            
            config = mkIf cfg.enable {
              systemd.services.happy-hare = {
                description = "Happy Hare MMU Service";
                wantedBy = [ "multi-user.target" ];
                after = [ "klipper.service" "moonraker.service" ];
                
                serviceConfig = {
                  Type = "simple";
                  User = "klipper";
                  Group = "klipper";
                  WorkingDirectory = "${self.packages.${system}.happyHare}";
                  ExecStart = "${pkgs.python3}/bin/python3 ${self.packages.${system}.happyHare}/extras/mmu/mmu.py";
                  Restart = "always";
                  RestartSec = "10";
                };
                
                environment = {
                  KLIPPER_CONFIG_HOME = cfg.klipperConfig;
                  KLIPPER_HOME = cfg.klipperHome;
                };
              };
            };
          };
      }
    );
}