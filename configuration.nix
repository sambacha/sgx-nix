{ config, pkgs, ... }:

let
  posh = global_args: run_args: image: (pkgs.writeScriptBin "posh" ''
      #! ${pkgs.bash}/bin/bash
      source /etc/profile
      tty -s && tty="-t" || quiet="-q"
      test -S "$SSH_AUTH_SOCK" && ssh="-v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK -e SSH_AUTH_SOCK"
      ${pkgs.podman}/bin/podman pull $quiet ${image} >/dev/null
      shift
      exec ${pkgs.podman}/bin/podman ${global_args} run --rm -i $tty $ssh -v ~/:/root -w /root --network host ${run_args} ${image} $@
    '')
    .overrideAttrs(attrs: attrs // {
        passthru = {
          shellPath = "/bin/posh";
        };
    });
in {
  imports = [ ./hardware-configuration.nix ./sshonly.nix ./ddns.nix ./sgx.nix ./podman.nix ];
  system.stateVersion = "19.09";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = { "fs.inotify.max_user_watches" = "524288"; };

  networking.useDHCP = false;
  networking.wireless.enable = false;
  networking.interfaces.eno1.useDHCP = true;

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "US/Eastern";

  environment.systemPackages = with pkgs; [ wget vim git tmux ];

  programs.bash.enableCompletion = true;

  users.users = {
    admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEkOn7R17qbf9kFJPNCgBo1mElbDn8HROzaCwgm/Vk+FPoFTn36uqokPFZOAxQ6oXOnof4PTz3JoYIONOnwtgg8= sam@manifoldfinnace.com"
      ];
    };
    sambacha = {
      shell = posh "" "--device /dev/sgx/enclave" "quay.io/enarx/fedora";
      isNormalUser = true;
      subUidRanges = [{ startUid = 100000; count = 10000; }];
      subGidRanges = [{ startGid = 100000; count = 10000; }];
      openssh.authorizedKeys.keys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEkOn7R17qbf9kFJPNCgBo1mElbDn8HROzaCwgm/Vk+FPoFTn36uqokPFZOAxQ6oXOnof4PTz3JoYIONOnwtgg8= sam@manifoldfinnace.com"
      ];
    };
  };
}
