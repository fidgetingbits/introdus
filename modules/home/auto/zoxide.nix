{ lib, ... }:
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  programs.zsh.initContent =
    lib.mkAfter
      # bash
      ''
        # Shouldn't need this with
        # programs.zoxide.enableZshIntegration but I seem to anyway :/
        eval "$(zoxide init zsh)"

        function zoxide_fzf() {
            local orig_buffer=$LBUFFER
            local selection
            selection=$(zoxide query --list | \
                          fzf --height 40% --reverse --border) || {
                LBUFFER=$orig_buffer
                return 0
            }

            if [[ -n "$selection" ]]; then
                LBUFFER+="$selection"
            fi
        }

        # Keybindings must be after vi mode enters
        # See https://github.com/jeffreytse/zsh-vi-mode#execute-extra-commands
        function zvm_after_init() {
            zle -N zoxide_fzf
            bindkey '^F' zoxide_fzf
        }
      '';
}
