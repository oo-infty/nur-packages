{ config, lib, pkgs, ... }:

let
  cfg = config.services.lx-music-sync-server;

  usersOption = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = lib.mdDoc ''
          Name of a user of the synchronization service.
        '';
      };

      password = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = lib.mdDoc ''
          The corresponding user's password. Warning: it will be world-readable
          in /nix/store.
        '';
      };

      passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/lx-music-sync-server-password";
        description = lib.mdDoc ''
          The file from which a user's password is loaded.
        '';
      };

      maxSnapshotNum = lib.mkOption {
        type = lib.types.ints.positive;
        default = cfg.maxSnapshotNum;
        description = lib.mdDoc ''
          The user-specific maximum number of snapshots.
        '';
      };

      listAddMusicLocation = lib.mkOption {
        type = lib.types.enum [ "top" "bottom" ];
        default = cfg.listAddMusicLocation;
        description = lib.mdDoc ''
          The user-specific location of a newly added music.
        '';
      };
    };
  };
in {
  ###### interface

  options.services.lx-music-sync-server = {
    enable = lib.mkEnableOption
      (lib.mdDoc "Data synchronization service of LX Music running on Node.js");

    package = lib.mkPackageOption pkgs "lx-music-sync-server" {};

    name = lib.mkOption {
      type = lib.types.str;
      default = "LX Music Sync Server";
      description = lib.mdDoc ''
        The name of the synchronization service.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9527;
      description = lib.mdDoc ''
        Port for theh server to listen on.
      '';
    };

    ip = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = lib.mdDoc ''
        The IP address for the service to bind. Use 127.0.0.1 by default. Use
        0.0.0.0 to accept all IPv4 requests. Or use :: to accept all requests
        including IPv4 and IPv6.
      '';
    };

    proxy = {
      enable = lib.mkEnableOption (lib.mdDoc "Whether to enable support for reverse proxy");

      header = lib.mkOption {
        type = lib.types.str;
        default = "x-real-ip";
        description = lib.mdDoc ''
          The request header's field from which the client's real IP is obtained.
        '';
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lx-music-sync-server";
      description = lib.mdDoc ''
        User under which lx-music-sync-server runs.
      '';
    };

    logDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/lx-music-sync-server/";
      description = lib.mdDoc ''
        The directory to which the service's log writes.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/lx-music-sync-server/";
      description = lib.mdDoc ''
        The directory where the service's data is stored.
      '';
    };

    maxSnapshotNum = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = lib.mdDoc ''
        The maximum number of snapshots. This option can be overriden by
        user-specific configurations.
      '';
    };

    listAddMusicLocation = lib.mkOption {
      type = lib.types.enum [ "top" "bottom" ];
      default = "top";
      description = lib.mdDoc ''
        The location of a newly added music. This option can be overriden by
        user-specific configurations.
      '';
    };

    accounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule usersOption);
      default = {};
      example = lib.literalExpression ''
        {
          user1 = {
            passwordFile = "/path/to/password";
            maxSnapshotNum = 10;
            listAddMusicLocation = "top";
          };
        }
      '';
    };
  };

  ###### implementation

  config = lib.mkIf cfg.enable {
    warnings = builtins.concatMap
      (account: lib.optional
        (account.password != null)
        "The password of lx-music-sync-server user ${account.name} will be world-readable in /nix/store")
      (builtins.attrValues cfg.accounts);

    assertions =
      let
        buildAssertion = account: [
          {
            assertion = lib.or (account.password != null) (account.passwordFile != null);
            message = "Neither a password nor a password file is set for lx-music-sync-server user ${account.name}";
          }
        ];
      in
      builtins.concatMap buildAssertion (builtins.attrValues cfg.accounts);

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      description = "lx-music-sync-server service user";
    };

    users.groups.${cfg.user} = {};

    systemd.tmpfiles.settings."10-lx-music-sync-server" = {
      ${cfg.dataDir}.d = {
        inherit (cfg) user;
        group = config.users.users.${cfg.user}.group;
      };
      ${cfg.logDir}.d = {
        inherit (cfg) user;
        group = config.users.users.${cfg.user}.group;
      };
    };

    systemd.services.lx-music-sync-server = {
      description = "LX Music Sync Server daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        PORT = builtins.toString cfg.port;
        BIND_IP = cfg.ip;
        PROXY_HEADER = lib.mkIf cfg.proxy.enable cfg.proxy.header;        
        LOG_PATH = cfg.logDir;
        DATA_PATH = cfg.dataDir;
        MAX_SNAPSHOT_NUM = builtins.toString cfg.maxSnapshotNum;
        LIST_ADD_MUSIC_LOCATION_TYPE = cfg.listAddMusicLocation;
      };

      script = let
        convertAccountConfig = account: {
          inherit (account) maxSnapshotNum;
          password =
            if account.passwordFile != null then
              ''$(cat ${account.passwordFile})''
            else
              account.password;
          "list.addMusicLocationType" = account.listAddMusicLocation;
        };
        buildEnvKeyValue = name: value: {
          name = "LX_USER_${name}";
          value = "${(builtins.toJSON (convertAccountConfig value))}";
        };
        exportEnvCmd = builtins.concatStringsSep
          " "
          (builtins.map
            ({ name, value }: ''${name}="${lib.escapeShellArg value}"'')
            (lib.mapAttrsToList buildEnvKeyValue cfg.accounts));
      in ''
        ${exportEnvCmd} ${cfg.package}/bin/lx-music-sync-server
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = config.users.users.${cfg.user}.group;
        StateDirectory = cfg.user;
        WorkDirectory = cfg.package;
        ReadWritePaths = "-${cfg.dataDir} -${cfg.logDir}";
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        DeviceAllow = "";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0007";
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ oo-infty ];
}
