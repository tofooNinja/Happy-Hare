# Test script for the install app
# This simulates what the install app does

{ pkgs ? import <nixpkgs> {} }:

let
  # Mock the install script
  testInstall = pkgs.writeShellScript "test-install" ''
    echo "Testing Happy Hare installation..."
    
    # Create a temporary directory
    TEMP_DIR=$(mktemp -d)
    echo "Working in temporary directory: $TEMP_DIR"
    
    # Copy files (simulate copying from flake source)
    echo "Copying files..."
    mkdir -p "$TEMP_DIR"
    echo "#!/bin/bash" > "$TEMP_DIR/install.sh"
    echo "echo 'Happy Hare installer running...'" >> "$TEMP_DIR/install.sh"
    echo "echo 'KLIPPER_HOME: $KLIPPER_HOME'" >> "$TEMP_DIR/install.sh"
    echo "echo 'MOONRAKER_HOME: $MOONRAKER_HOME'" >> "$TEMP_DIR/install.sh"
    
    cd "$TEMP_DIR"
    
    # Fix shebang
    sed -i 's|#!/bin/bash|#!${pkgs.bash}/bin/bash|g' install.sh
    chmod +x install.sh
    
    # Set environment
    export KLIPPER_HOME="/mock/klipper"
    export MOONRAKER_HOME="/mock/moonraker"
    export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:$PATH"
    
    # Run installer
    echo "Running installer..."
    ./install.sh
    
    # Clean up
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
    
    echo "Test completed successfully!"
  '';
in
  testInstall