# Simple test to validate flake structure
# This is just for syntax checking - run with: nix eval --file test-flake.nix

let
  # Mock the inputs for testing
  nixpkgs = {
    legacyPackages = {
      aarch64-linux = {
        python3 = {
          withPackages = f: { _type = "python-env"; };
        };
        mkShell = attrs: { _type = "shell"; };
        stdenv = {
          mkDerivation = attrs: { _type = "derivation"; };
        };
        writeShellScript = name: script: { _type = "script"; };
        makeWrapper = { _type = "makeWrapper"; };
        gcc = { _type = "gcc"; };
        gnumake = { _type = "make"; };
        git = { _type = "git"; };
        python3Packages = {
          pyserial = { _type = "pyserial"; };
          cffi = { _type = "cffi"; };
          jinja2 = { _type = "jinja2"; };
        };
        lib = {
          licenses = {
            gpl3 = { _type = "license"; };
          };
          platforms = {
            all = { _type = "platforms"; };
          };
        };
      };
    };
  };
  
  flake-utils = {
    lib = {
      eachDefaultSystem = f: {
        aarch64-linux = f "aarch64-linux";
      };
    };
  };
  
  klipper = "/mock/klipper";
  moonraker = "/mock/moonraker";
  
  # Test the flake structure
  result = flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      
      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        ps.pyserial
        ps.cffi
        ps.jinja2
      ]);
      
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          pythonEnv
          gcc
          gnumake
          git
        ];
      };
      
      happyHare = pkgs.stdenv.mkDerivation {
        pname = "happy-hare";
        version = "3.3.0";
        src = ./.;
        
        nativeBuildInputs = with pkgs; [
          makeWrapper
        ];
        
        installPhase = ''
          mkdir -p $out
          echo "Happy Hare package created"
        '';
      };
      
    in {
      devShells.default = devShell;
      packages = {
        inherit happyHare;
        default = happyHare;
      };
      apps = {
        install = {
          type = "app";
          program = toString (pkgs.writeShellScript "install" "echo 'install script'");
        };
      };
    }
  );
  
in result