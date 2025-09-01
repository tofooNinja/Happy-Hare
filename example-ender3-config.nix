# Example NixOS configuration for Ender 3 with Happy Hare on Raspberry Pi
# Save this as configuration.nix or include in your flake.nix

{ config, lib, pkgs, ... }:

{
  # Enable Happy Hare service
  imports = [
    ./flake.nix
  ];

  # System configuration
  system.stateVersion = "23.11";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # User configuration for klipper
  users.users.klipper = {
    isNormalUser = true;
    extraGroups = [ "dialout" "tty" "gpio" ];
    shell = pkgs.bash;
  };

  # Enable required services
  services = {
    # Enable Happy Hare
    happyHare = {
      enable = true;
      klipperConfig = "/home/klipper/printer_data/config";
      klipperHome = "/home/klipper/klipper";
    };

    # Enable Klipper (if you have it configured)
    # klipper = {
    #   enable = true;
    #   user = "klipper";
    #   configFile = "/home/klipper/printer_data/config/printer.cfg";
    # };

    # Enable Moonraker (if you have it configured)
    # moonraker = {
    #   enable = true;
    #   user = "klipper";
    #   configFile = "/home/klipper/printer_data/config/moonraker.conf";
    # };
  };

  # Hardware configuration for Raspberry Pi
  hardware = {
    # Enable GPIO
    raspberry-pi = {
      enable = true;
    };

    # Enable I2C for sensors
    i2c.enable = true;

    # Enable SPI for some MMU boards
    spi.enable = true;
  };

  # Networking
  networking = {
    hostName = "ender3-pi";
    
    # Enable SSH for remote access
    ssh.enable = true;
    
    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80    # HTTP
        443   # HTTPS
        7125  # Moonraker
        8080  # Alternative web interface
      ];
    };
  };

  # Environment packages
  environment.systemPackages = with pkgs; [
    # Development tools
    git
    vim
    htop
    tmux
    
    # Network tools
    curl
    wget
    
    # Serial communication
    screen
    minicom
    
    # File management
    tree
    ripgrep
    fd
  ];

  # Boot configuration
  boot = {
    # Enable kernel modules for USB serial
    kernelModules = [ "usbserial" "ftdi_sio" "ch341" ];
    
    # Load modules at boot
    extraModprobeConfig = ''
      options ftdi_sio vendor=0x0483 product=0x5740
      options ch341 vendor=0x1a86 product=0x7523
    '';
  };

  # File systems
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
    
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
  };

  # Swap configuration
  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 2048;
  } ];

  # Time configuration
  time.timeZone = "Europe/London";

  # Locale configuration
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Sound configuration (disable for headless setup)
  sound.enable = false;
  hardware.pulseaudio.enable = false;

  # X11 configuration (disable for headless setup)
  services.xserver.enable = false;

  # Power management
  powerManagement.cpuFreqGovernor = "ondemand";

  # Systemd services
  systemd.services = {
    # Ensure klipper user has proper permissions
    "klipper-setup" = {
      description = "Setup Klipper user permissions";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c '
            mkdir -p /home/klipper/printer_data/config
            mkdir -p /home/klipper/printer_data/logs
            chown -R klipper:klipper /home/klipper/printer_data
            chmod -R 755 /home/klipper/printer_data
          '
        '';
        RemainAfterExit = true;
      };
    };
  };

  # Security configuration
  security = {
    # Allow klipper user to access serial ports
    wrappers = {
      "klipper" = {
        source = "${pkgs.bash}/bin/bash";
        capabilities = "cap_sys_rawio+ep";
        owner = "klipper";
        group = "klipper";
      };
    };
  };
}