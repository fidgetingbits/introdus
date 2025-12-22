# FIXME: This could be made a lot less ghetto
{
  pkgs,
  ...
}:
pkgs.writeShellApplication {
  name = "check-sops";
  runtimeInputs = [ pkgs.ripgrep ];

  text = # bash
    ''
      # If the sops-nix service wasn't started at all, we don't need to check
      # if it failed
      sops_log=$(journalctl --no-pager --no-hostname --since "10 minutes ago")
      if ! echo "$sops_log" | rg -q "Starting sops-nix activation"; then
        exit 0
      fi

      sops_result=$(echo "$sops_log" |
        tac |
        awk '!flag; /Starting sops-nix activation/{flag = 1};' |
        tac |
        rg sops)

      # If we don't have "Finished sops-nix activation." in the logs, then we failed
      if [[ ! $sops_result =~ "Finished sops-nix activation" ]]; then
        echo "ERROR: sops-nix failed to activate"
        echo "ERROR: $sops_result"
        exit 1
      fi
    '';
}
