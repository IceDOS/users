{ icedosLib, ... }:

let
  inherit (icedosLib)
    mkBoolOption
    mkStrListOption
    mkStrOption
    mkSubmoduleAttrsOption
    ;
in
{
  options.icedos.users = mkSubmoduleAttrsOption { } {
    defaultPassword = mkStrOption { default = "1"; };
    description = mkStrOption { default = ""; };
    extraGroups = mkStrListOption { default = [ ]; };
    home = mkStrOption { default = ""; };
    isNormalUser = mkBoolOption { default = true; };
    isSystemUser = mkBoolOption { default = false; };
    sudo = mkBoolOption { default = true; };
  };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          ...
        }:

        let
          inherit (lib)
            attrNames
            mapAttrs
            foldl'
            ;

          cfg = config.icedos;
        in
        {
          nix.settings.trusted-users = [
            "root"
          ]
          ++ (foldl' (acc: user: acc ++ [ user ]) [ ] (attrNames cfg.users));

          users.users = mapAttrs (
            user: _:
            let
              userAttrs = cfg.users.${user};
              homeDir = userAttrs.home;
            in
            {
              description = "${userAttrs.description}";
              extraGroups = [ ] ++ lib.optional userAttrs.sudo "wheel" ++ userAttrs.extraGroups;
              home = if (builtins.stringLength homeDir != 0) then homeDir else "/home/${user}";
              isNormalUser = userAttrs.isNormalUser;
              isSystemUser = userAttrs.isSystemUser;
              password = userAttrs.defaultPassword;
            }
          ) cfg.users;

          home-manager.users = mapAttrs (user: _: { home.stateVersion = cfg.system.version; }) cfg.users;
        }
      )
    ];

  meta.name = "default";
}
