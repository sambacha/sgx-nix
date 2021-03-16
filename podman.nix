 { config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ podman conmon runc cni cni-plugins slirp4netns ];
  
  environment.etc."containers/registries.conf".text = ''
    [registries.search]
    registries = [
      'docker.io',
      'registry.fedoraproject.org',
      'registry.access.redhat.com',
      'quay.io'
    ]
  '';

  environment.etc."containers/policy.json".text = ''
    {
        "default": [
            {
                "type": "insecureAcceptAnything"
            }
        ],
        "transports":
            {
                "docker-daemon":
                    {
                        "": [{"type":"insecureAcceptAnything"}]
                    }
            }
    }
  '';

  environment.etc."cni/net.d/00-loopback.conf".text = ''
    {
      "cniVersion": "0.3.0",
      "type": "loopback"
    }
  '';

  environment.etc."cni/net.d/87-podman-bridge.conflist".text = ''
    {
        "cniVersion": "0.3.0",
        "name": "podman",
        "plugins": [
          {
            "type": "bridge",
            "bridge": "cni0",
            "isGateway": true,
            "ipMasq": true,
            "ipam": {
                "type": "host-local",
                "subnet": "10.88.0.0/16",
                "routes": [
                    { "dst": "0.0.0.0/0" }
                ]
            }
          },
          {
            "type": "portmap",
            "capabilities": {
              "portMappings": true
            }
          }
        ]
    }
  '';

  environment.etc."containers/libpod.conf".text = ''
    # libpod.conf is the default configuration file for all tools using libpod to
    # manage containers
    # Default transport method for pulling and pushing for images
    image_default_transport = "docker://"
    # Paths to search for the Conmon container manager binary
    runtime_path = [
      "${pkgs.runc}/bin/runc"
    ]
    # Paths to look for the Conmon container manager binary
    conmon_path = [
      "${pkgs.conmon}/bin/conmon"
    ]
    # Environment variables to pass into conmon
    conmon_env_vars = [
      # "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ]
    # CGroup Manager - valid values are "systemd" and "cgroupfs"
    cgroup_manager = "systemd"
    # Container init binary
    #init_path = "/usr/libexec/podman/catatonit"
    # Directory for persistent libpod files (database, etc)
    # By default, this will be configured relative to where containers/storage
    # stores containers
    # Uncomment to change location from this default
    #static_dir = "/var/lib/containers/storage/libpod"
    # Directory for temporary files. Must be tmpfs (wiped after reboot)
    tmp_dir = "/var/run/libpod"
    # Maximum size of log files (in bytes)
    # -1 is unlimited
    max_log_size = -1
    # Whether to use chroot instead of pivot_root in the runtime
    no_pivot_root = false
    # Directory containing CNI plugin configuration files
    cni_config_dir = "/etc/cni/net.d/"
    # Directories where the CNI plugin binaries may be located
    cni_plugin_dir = [
      "${pkgs.cni-plugins}/bin"
    ]
    # Default CNI network for libpod.
    # If multiple CNI network configs are present, libpod will use the network with
    # the name given here for containers unless explicitly overridden.
    # The default here is set to the name we set in the
    # 87-podman-bridge.conflist included in the repository.
    # Not setting this, or setting it to the empty string, will use normal CNI
    # precedence rules for selecting between multiple networks.
    cni_default_network = "podman"
    # Default libpod namespace
    # If libpod is joined to a namespace, it will see only containers and pods
    # that were created in the same namespace, and will create new containers and
    # pods in that namespace.
    # The default namespace is "", which corresponds to no namespace. When no
    # namespace is set, all containers and pods are visible.
    #namespace = ""
    # Default pause image name for pod pause containers
    pause_image = "k8s.gcr.io/pause:3.1"
    # Default command to run the pause container
    pause_command = "/pause"
    # Determines whether libpod will reserve ports on the host when they are
    # forwarded to containers. When enabled, when ports are forwarded to containers,
    # they are held open by conmon as long as the container is running, ensuring that
    # they cannot be reused by other programs on the host. However, this can cause
    # significant memory usage if a container has many ports forwarded to it.
    # Disabling this can save memory.
    #enable_port_reservation = true
    # Default libpod support for container labeling
    # label=true
    # Paths to look for a valid OCI runtime (runc, runv, etc)
    # FIXME: this doesn't seem to take effect
    [runtimes]
    runc = [
      "${pkgs.runc}/bin/runc"
    ]
'';
}
