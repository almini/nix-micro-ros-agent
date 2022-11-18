{
  description = "Micro-ROS-Agent package flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ros-overlay.url = "github:lopsided98/nix-ros-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, ros-overlay, ... }: {
    overlays.default = final: prev: let 
      ros2 = rec {
        pkgs = import ros-overlay.inputs.nixpkgs {
          system = final.system;
          overlays = [
            ros-overlay.overlays.default
          ];
        };
        distro = pkgs.rosPackages.humble;
      }; 
    in {

      micro-xrce-dds-agent = with final; stdenv.mkDerivation rec {
        pname = "micro-xrce-dds-agent";
        version = "2.2.1";

        src = fetchgit {
          url = "https://github.com/eProsima/Micro-XRCE-DDS-Agent.git";
          rev = "021828fe7c25daebc0b9f043a4bbe75cfc2710d5";
          sha256 = "sha256-K9KornFM7d0m2VRATZiJpFIjNmtDKNEx2QvvpX60oFs=";
        };

        cmakeFlags = [
          "-DMICROROSAGENT_SUPERBUILD:BOOL=OFF"
          "-DUAGENT_USE_SYSTEM_FASTDDS:BOOL=ON"
          "-DUAGENT_USE_SYSTEM_FASTCDR:BOOL=ON"
          "-DUAGENT_USE_SYSTEM_LOGGER:BOOL=ON"
          "-DUAGENT_CED_PROFILE:BOOL=OFF"
          "-DUAGENT_P2P_PROFILE:BOOL=OFF"
          "-DUAGENT_BUILD_EXECUTABLE:BOOL=ON"
          "-DUAGENT_ISOLATED_INSTALL:BOOL=OFF"
        ];

        buildInputs = [ ros2.distro.fastrtps ros2.distro.spdlog-vendor ];

      };

      micro-ros-agent = with final; stdenv.mkDerivation rec {
        pname = "micro-ros-agent";
        version = "3.0.4";

        src = fetchgit {
          url = "https://github.com/micro-ROS/micro-ROS-Agent.git";
          rev = "0e41ea652238bd0123f6249d69b533d282882dd6";
          sha256 = "sha256-0/5cLd2IWhK8dpDCzZr+UfIi4j04afbXg2Dk7Sn/Aps=";
        };

        sourceRoot = "${src.name}/micro_ros_agent";

        cmakeFlags = [
          "-DMICROROSAGENT_SUPERBUILD:BOOL=OFF"
          "-DUAGENT_USE_SYSTEM_LOGGER:BOOL=ON"
        ];

        buildInputs = [ 
          ros2.distro.ament-cmake 
          ros2.distro.fastcdr 
          ros2.distro.fastrtps 
          ros2.distro.fastrtps-cmake-module
          ros2.distro.spdlog-vendor 
          ros2.distro.rosidl-cmake
          ros2.distro.rmw-dds-common
          ros2.distro.rmw-fastrtps-shared-cpp
          ros2.distro.ament-lint-auto
          ros2.distro.micro-ros-msgs
          final.micro-xrce-dds-agent
        ];

        postInstall = ''
          mkdir -p $out/bin
          ln -s $out/lib/micro_ros_agent/micro_ros_agent $out/bin/micro_ros_agent
        '';

        meta = {
          description = ''ROS 2 package using Micro XRCE-DDS Agent'';
          license = with lib.licenses; [ asl20 ];
        };

      };

    };
  } // flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
    let
      pkgs = import nixpkgs { 
        inherit system; 
        overlays = [ 
          self.overlays.default
        ]; 
      };
    in
    {

      packages.micro-xrce-dds-agent = pkgs.micro-xrce-dds-agent;
      packages.micro-ros-agent = pkgs.micro-ros-agent;
      packages.default = pkgs.micro-ros-agent;

    });
}