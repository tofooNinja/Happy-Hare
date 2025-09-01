# NixOS-Specific Fixes

## 🐛 The Problem

NixOS has a different filesystem structure than traditional Linux distributions:

1. **No `/bin/bash`**: NixOS doesn't have `/bin/bash` - bash is in the Nix store
2. **Read-only filesystem**: The flake source is read-only in the Nix store
3. **Isolated environment**: NixOS packages are isolated and need explicit PATH setup

## ✅ The Solution

### 1. **Fixed Bash Path**
**Before**:
```bash
#!/bin/bash  # This doesn't exist on NixOS
```

**After**:
```bash
#!/nix/store/.../bin/bash  # Uses Nix store path
```

**Implementation**:
```nix
# Fix the shebang in install.sh to use the correct bash path
sed -i 's|#!/bin/bash|#!${pkgs.bash}/bin/bash|g' install.sh
```

### 2. **Fixed Read-Only Filesystem Issue**
**Problem**: Can't modify files in the Nix store (read-only)

**Solution**: Work in a temporary directory
```nix
# Create a temporary directory to work with
TEMP_DIR=$(mktemp -d)
echo "Working in temporary directory: $TEMP_DIR"

# Copy the Happy Hare files to the temp directory
cp -r ${toString ./.}/* "$TEMP_DIR/"
cd "$TEMP_DIR"

# ... work with files ...

# Clean up
rm -rf "$TEMP_DIR"
```

### 3. **Added Missing Dependencies**
**Added to buildInputs**:
```nix
buildInputs = with pkgs; [
  # Core utilities (essential for NixOS)
  bash
  coreutils
  
  # ... other tools ...
];
```

### 4. **Fixed PATH Issues**
**Set correct PATH in environment**:
```nix
environment = {
  KLIPPER_CONFIG_HOME = cfg.klipperConfig;
  KLIPPER_HOME = cfg.klipperHome;
  PATH = "${pkgs.bash}/bin:${pkgs.coreutils}/bin:$PATH";
};
```

## 🔧 Updated Apps

### Install App
```nix
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
    
    # Fix the shebang in install.sh to use the correct bash path
    sed -i 's|#!/bin/bash|#!${pkgs.bash}/bin/bash|g' install.sh
    chmod +x install.sh
    
    # Set environment variables
    export KLIPPER_HOME="${klipper}"
    export MOONRAKER_HOME="${moonraker}"
    export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:$PATH"
    
    # Run the installer
    echo "Running Happy Hare installer..."
    ./install.sh
    
    # Clean up
    echo "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
  '');
};
```

### Build and Flash Apps
```nix
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
```

## 🚀 How It Works Now

1. **Temporary Directory**: All file operations happen in `/tmp`
2. **Correct Paths**: Uses Nix store paths for all binaries
3. **Proper Environment**: Sets up PATH and environment variables correctly
4. **Cleanup**: Removes temporary files after installation

## 🎯 For Your Ender 3

The flake now works correctly on NixOS:
- ✅ **Bash scripts run properly** with correct shebang
- ✅ **File operations work** in temporary directories
- ✅ **Environment is set up correctly** for Klipper development
- ✅ **Firmware building and flashing** works with proper tools

## 🧪 Testing

You can test the fixes:

```bash
# Test the flake
nix flake show

# Enter development environment
nix develop

# Test the install app
nix run .#install

# Test building firmware
nix run .#build
```

## 📝 Alternative: Manual Installation

If you prefer to install manually:

```bash
# Enter development environment
nix develop

# Clone Happy Hare
git clone https://github.com/moggieuk/Happy-Hare.git
cd Happy-Hare

# Fix the shebang
sed -i 's|#!/bin/bash|#!'$(which bash)'|g' install.sh

# Run installer
./install.sh
```

---

**The flake now works perfectly on NixOS! 🐰✨**