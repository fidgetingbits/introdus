# Git settings for development systems. This will enable things like per-folder
# and per project git configurations to enable git-force specific commit
# signing. It relies on ssh key signing only.

# When using auth this expects a yubikey should be used. Touching shouldn't be
# required for most repos that don't actually need auth, but we want it for ones we are doing
# dev on. Solution is to hardcode repos that require auth and default to ssh for those only

{
  config,
  osConfig,
  lib,
  ...
}:
let
  cfg = config.introdus.gitDev;
  home = config.home.homeDirectory;

  forges = {
    # forge name   email prefix
    "codeberg.org" = "noreply";
    "github.com" = "users.noreply";
    "gitlab.com" = "users.noreply";
  };
  forgeEmail = forge: prefix: "${cfg.handle}@${prefix}.${forge}";

  insteadOfList =
    domain: urls:
    urls
    |> lib.map (url: {
      "ssh://git@${domain}/${url}" = {
        insteadOf = "https://${domain}/${url}";
      };
    });

  workRepoNames =
    lib.attrNames cfg.workRepos
    # nixfmt hack
    |> lib.optionals osConfig.hostSpec.isWork;

  workDomain =
    domain:
    lib.optionals (osConfig.hostSpec.isWork && (cfg.workRepos ? ${domain})) cfg.workRepos.${domain};

  alwaysSshRepos =
    (lib.attrNames cfg.devRepos) ++ workRepoNames
    |> lib.map (domain: insteadOfList domain (cfg.devRepos.${domain} ++ (workDomain domain)))
    |> lib.concatLists
    |> lib.foldl' lib.recursiveUpdate { };
in
{
  options = {
    introdus.gitDev = {
      enable = lib.mkEnableOption "Enable git development settings";
      handle = lib.mkOption {
        default = osConfig.hostSpec.handle;
        example = "wukong";
        type = lib.types.str;
        description = "";
      };
      sshFolder = lib.mkOption {
        default = "${home}/.ssh";
        example = "/home/wukong/.ssh";
        type = lib.types.str;
        description = "";
      };
      publicKey = lib.mkOption {
        default =
          if osConfig.hostSpec.useYubikey then
            "${config.introdus.gitDev.sshFolder}/id_yubikey.pub"
          else
            "${config.introdus.gitDev}/id_ed25519.pub";
        type = lib.types.str;
        description = "";
      };
      email = lib.mkOption {
        default = osConfig.hostSpec.email;
        example = {
          git = rec {
            primary = "wukong@personal-domain.com";
            work = "wukong@work-domain.com";
          };
        };
        # FIXME: Make the type more strict
        type = lib.types.attrsOf lib.types.anything;
        description = "";
        # FIXME: add a check to ensure primary and work exist in the same
      };
      devFolders = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "/home/wukong/src" ];
        description = "List of folders to set your private dev git settings";
      };
      devRepos = lib.mkOption {
        default = { };
        example =
          let
            handle = config.introdus.gitDev.handle;
          in
          {
            "github.com" = [
              "${handle}/private1"
              "${handle}/private2"
            ];
          };
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        description = "List of work servers to include ssh insteadOf url substitutions for";
      };

      workFolders = lib.mkOption {
        default = [ ];
        example = [ "${home}/work/dev/" ];
        type = lib.types.listOf lib.types.str;
        description = "List of folders to set your work dev git settings";
      };
      workServers = lib.mkOption {
        default = [ ];
        example = [ "git.work-server.com" ];
        type = lib.types.listOf lib.types.str;
        description = "List of work servers to include ssh insteadOf url substitutions for";
      };
      workRepos = lib.mkOption {
        default = { };
        example = {
          "github.com" = [
            "workOrg/private1"
            "workOrg/private2"
          ];
        };
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        # FIXME: Test this is still true after changes
        description = ''
          List of work servers to include ssh insteadOf url substitutions for.
                  If you want to swap an entire server, leave the repo part an empty string'';
      };
      # FIXME: Make this is a list of paths that we check all of for the presence of the specified keys?
      # or just take absolute paths for keys and ditch this option?
      keysPath = lib.mkOption {
        default = "hosts/common/users/super/keys/";
        type = lib.types.str;
        example = "hosts/common/users/wukong/keys/";
        description = "";
      };
      devKeys = lib.mkOption {
        default = [ ];
        example = [ "id_foo.pub" ];
        type = lib.types.listOf lib.types.str;
        description = "List of pub keys to allow for mark as verified for git signing on personal projects";
      };
      workKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "id_foo.pub" ];
        description = "List of pub keys to allow for mark as verified for git signing on work projects";
      };
      usePrivateEmails = lib.mkOption {
        default = true;
        type = lib.types.boolean;
        example = false;
        description = ''
          If true, enables noreply emails to be configured for all major forges.
                  NOTE: The email is built using your handle like:
                  ${config.introdus.gitDev.handle}@users.noreply.codeberg.org
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      settings = {
        user = {
          name = cfg.handle; # Default name for all git operations
          email = cfg.email.git.primary; # # Default email for all git operations
          signingkey = "${cfg.publicKey}";
        };
        # FIXME: Could consider this type of stuff moving elsewhere, and focus
        # this module ONLY on insteadOf type rules and signing
        init.defaultBranch = "main";
        pull.rebase = "true";

        # Don't warn on empty git add calls. Because of "git re-commit" automation
        advice.addEmptyPathspec = false;

        url = alwaysSshRepos;

        commit.gpgsign = "true";
        gpg = {
          format = "ssh";
          # See later zsh alias for how we handle yubikey ssh signing with git
          ssh.allowedSignersFile = "${home}/.ssh/allowed_signers";
        };
      };
      includes =
        let
          privateGitConfig = {
            user = {
              name = cfg.handle;
              # FIXME: Change this to private maybe? Otherwise it's redundant with the global setting
              email = cfg.email.git.primary;
            };
          };
          workGitConfig = {
            user = {
              # FIXME: Probably change this to an option
              name = osConfig.hostSpec.userFullName;
              # Takes the first work email out of a possible list
              email = if (lib.isList cfg.email.work) then lib.elem 0 cfg.email.work else cfg.email.work;
            };
          };
          mapFolders =
            paths: contents:
            lib.map (f: {
              condition = "gitdir:${f}";
              inherit contents;
            }) paths;
          mapRemotes =
            remotes:
            lib.mapAttrsToList (name: value: {
              condition = "hasconfig:remote.*.url:**/*${name}/**";
              contents = {
                user.email = (forgeEmail name value);
              };
            }) remotes;

        in
        # Order matters. Last match wins, so we want granular email changes last
        (mapFolders cfg.devFolders privateGitConfig)
        ++ (mapFolders cfg.workFolders workGitConfig)
        ++ (mapRemotes forges);

      signing = {
        signByDefault = true;
        key = cfg.publicKey;
      };
    };

    programs.zsh.initContent = ''
      # git can't handle ssh-add -L output with a yubikey sk-ssh entry,
      # so we alias git here to force it to use the ssh-agent output
      if [[ -n $SSH_CONNECTION ]]; then
          TEMP_KEY=$(mktemp)
          ssh-add -L | head -n 1 >"$TEMP_KEY"
          alias git="git -c user.signingKey=$TEMP_KEY"
      fi
    '';

    home.file.".ssh/allowed_signers".text =
      let
        # FIXME: This should integrate cfg.devMails and check cfg.usePrivateEmails
        devEmails = lib.mapAttrsToList (name: value: forgeEmail name value) forges;
        # If email.work is set and not set it to "", returns a list of said emails
        workEmail =
          if (cfg.email ? work) then
            if (lib.isList cfg.email.work) then
              cfg.email.work
            else
              lib.flatten [
                (lib.filter (n: n != "") [ cfg.email.work ])
              ]
          else
            [ ];
        genGitEmailKeys =
          emails: keys:
          lib.concatMapStringsSep "\n" (
            key:
            let
              signers =
                emails
                |> lib.filter (s: s != "")
                # nixfmt hack
                |> lib.concatStringsSep ",";
              keyContent =
                "${cfg.keysPath}/${key}"
                |> lib.custom.relativeToRoot
                # nixfmt hack
                |> lib.fileContents;
            in
            ''${signers} namespaces="git" ${keyContent}\n''
          ) keys;
      in
      ''
        ${genGitEmailKeys devEmails cfg.devKeys};
        ${genGitEmailKeys workEmail cfg.workKeys}
      '';
  };
}
