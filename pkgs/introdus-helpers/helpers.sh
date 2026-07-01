#!/usr/bin/env bash
set -eo pipefail

### UX helpers
function red() {
    printf "\033[31m[!] %s \033[0m\n" "$1"
    if [ -n "${2-}" ]; then
        printf "\033[31m[!] %s \033[0m\n" "$($2)"
    fi
}

function green() {
    printf "\033[32m[+] %s \033[0m\n" "$1"
    if [ -n "${2-}" ]; then
        printf "\033[32m[+] %s \033[0m\n" "$($2)"
    fi
}

function blue() {
    printf "\033[34m[*] %s \033[0m\n" "$1"
    if [ -n "${2-}" ]; then
        printf "\033[34m[*] %s \033[0m\n" "$($2)"
    fi
}

function yellow() {
    printf "\033[33m[*] %s \033[0m\n" "$1"
    if [ -n "${2-}" ]; then
        printf "\033[33m[*] %s \033[0m\n" "$($2)"
    fi
}

# Ask yes or no, with yes being the default
function yes_or_no() {
    echo -en "\x1B[34m[?] $* [y/n] (default: y): \x1B[0m"
    while true; do
        read -rp "" yn
        yn=${yn:-y}
        case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        esac
    done
}

# Need this to avoid some wacky pre-commit hook issues related to if rebuild fails and
# flake.lock stays staged, which ends up wiping out all changes due to stashing bug
CLEAN=0
cleanup_flake_lock() {
    # If the command succeeds, the justfile will clean up for us
    if [ $? -ne 0 ]; then
        if [[ $CLEAN -eq 0 ]]; then
            git rm --cached -f flake.lock 2>/dev/null || true
            red "Rebuild failed, cleaning up lock files"
            rm flake.lock 2>/dev/null || true
            CLEAN=1
        fi
    fi
}

# Ask yes or no, with no being the default
function no_or_yes() {
    echo -en "\x1B[34m[?] $* [y/n] (default: n): \x1B[0m"
    while true; do
        read -rp "" yn
        yn=${yn:-n}
        case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        esac
    done
}

### SOPS helpers

if [ -z "${NIX_SECRETS_DIR+x}" ]; then
    red "ERROR: The NIX_SECRETS_DIR variable must point to the absolute path of your nix-secrets folder"
    red "You probably want to add it to your nixos-config shell.nix file"
fi
SOPS_FILE="${NIX_SECRETS_DIR}/.sops.yaml"

# Updates the .sops.yaml file with a new host or user age key.
function sops_update_age_key() {
    field="$1"
    keyname="$2"
    key="$3"

    if [ ! "$field" == "hosts" ] && [ ! "$field" == "users" ]; then
        red "Invalid field passed to sops_update_age_key. Must be either 'hosts' or 'users'."
        exit 1
    fi

    if [[ -n $(yq ".keys.${field}[] | select(anchor == \"$keyname\")" "${SOPS_FILE}") ]]; then
        green "Updating existing ${keyname} key"
        yq -i "(.keys.${field}[] | select(anchor == \"$keyname\")) = \"$key\"" "$SOPS_FILE"
    else
        green "Adding new ${keyname} key"
        yq -i ".keys.$field += [\"$key\"] | .keys.${field}[-1] anchor = \"$keyname\"" "$SOPS_FILE"
    fi
}

# Adds the user and host to the shared.yaml creation rules
function sops_add_shared_creation_rules() {
    u="\"$1_$2\"" # quoted user_host for yaml
    h="\"$2\""    # quoted hostname for yaml

    cat "${SOPS_FILE}"
    echo "${SOPS_FILE}"
    shared_selector='.creation_rules[] | select(.path_regex == "shared\.yaml$")'
    if [[ -n $(yq "$shared_selector" "${SOPS_FILE}") ]]; then
        if [[ -z $(yq "$shared_selector.key_groups[].age[] | select(alias == $h)" "${SOPS_FILE}") ]]; then
            green "Adding $u and $h to shared.yaml rule"
            # NOTE: Split on purpose to avoid weird file corruption
            yq -i "($shared_selector).key_groups[].age += [$u, $h]" "$SOPS_FILE"
            yq -i "($shared_selector).key_groups[].age[-2] alias = $u" "$SOPS_FILE"
            yq -i "($shared_selector).key_groups[].age[-1] alias = $h" "$SOPS_FILE"
        fi
    else
        red "shared.yaml rule not found"
    fi
}

# Adds the user and host to the host.yaml creation rules
function sops_add_host_creation_rules() {
    host="$2"                     # hostname for selector
    h="\"$2\""                    # quoted hostname for yaml
    u="\"$1_$2\""                 # quoted user_host for yaml
    w="\"$(whoami)_$(hostname)\"" # quoted whoami_hostname for yaml
    n="\"$(hostname)\""           # quoted hostname for yaml

    host_selector=".creation_rules[] | select(.path_regex | contains(\"${host}\.yaml\"))"
    if [[ -z $(yq "$host_selector" "${SOPS_FILE}") ]]; then
        green "Adding new host file creation rule"
        yq -i ".creation_rules += {\"path_regex\": \"${host}\\.yaml$\", \"key_groups\": [{\"age\": [$u, $h]}]}" "$SOPS_FILE"
        # Add aliases one by one
        yq -i "($host_selector).key_groups[].age[0] alias = $u" "$SOPS_FILE"
        yq -i "($host_selector).key_groups[].age[1] alias = $h" "$SOPS_FILE"
        yq -i "($host_selector).key_groups[].age[2] alias = $w" "$SOPS_FILE"
        yq -i "($host_selector).key_groups[].age[3] alias = $n" "$SOPS_FILE"
    fi
}

# Adds the user and host to the host.yaml creation rules
# and the shared.yaml. Defaults to adding to shared
function sops_add_creation_rules() {
    user="$1"
    host="$2"
    shared="${3-1}"

    if [ "$shared" -ne 0 ]; then
        sops_add_shared_creation_rules "$user" "$host"
    fi
    sops_add_host_creation_rules "$user" "$host"
}

age_secret_key=""
# Generate a user age key, update the .sops.yaml entries, and return the key in age_secret_key
# args: user, hostname
function sops_generate_user_age_key() {
    target_user="$1"
    target_hostname="$2"
    key_name="${target_user}_${target_hostname}"
    green "Age key does not exist. Generating."
    user_age_key=$(age-keygen)
    readarray -t entries <<<"$user_age_key"
    age_secret_key=${entries[2]}
    public_key=$(echo "${entries[1]}" | rg key: | cut -f2 -d: | xargs)
    green "Generated age key for ${key_name}"
    # Place the anchors into .sops.yaml so other commands can reference them
    sops_update_age_key "users" "$key_name" "$public_key"
    sops_add_creation_rules "${target_user}" "${target_hostname}"
    # "return" key so it can be used by caller
    export age_secret_key
}

function sops_setup_user_age_key() {
    target_user="$1"
    target_hostname="$2"

    secret_file="${NIX_SECRETS_DIR}/sops/${target_hostname}.yaml"
    config="${NIX_SECRETS_DIR}/.sops.yaml"
    # If the secret file doesn't exist, it means we're generating a new user key as well
    if [ ! -f "$secret_file" ]; then
        green "Host secret file does not exist. Creating $secret_file"
        sops_generate_user_age_key "${target_user}" "${target_hostname}"
        mkdir -p "$(dirname "$secret_file")"
        echo "{}" >"$secret_file"
        sops --config "$config" -e "$secret_file" >"$secret_file.enc"
        mv "$secret_file.enc" "$secret_file"
        #exit 0
    fi
    if ! sops --config "$config" -d --extract '["keys]["age"]' "$secret_file" >/dev/null 2>&1; then
        if [ -z "$age_secret_key" ]; then
            sops_generate_user_age_key "${target_user}" "${target_hostname}"
        fi
        cat "$secret_file"
        # shellcheck disable=SC2116,SC2086
        sops --config "$config" --set '["keys"]["age"] "'"$age_secret_key"'"' "$secret_file"
    else
        green "Age key already exists for ${target_hostname}"
    fi
}

### Trap helpers

# FIXME: Revisit the log, error, fatal functions with coloring, etc

# From https://stackoverflow.com/questions/3338030/multiple-bash-traps-for-the-same-signal/7287873#7287873

# note: printf is used instead of echo to avoid backslash
# processing and to properly handle values that begin with a '-'.
log() { printf '%s\n' "$*"; }
error() { log "ERROR: $*" >&2; }
fatal() {
    error "$@"
    exit 1
}

# appends a command to a trap
#
# - 1st arg:  code to add
# - remaining args:  names of traps to modify
#
trap_add() {
    trap_add_cmd=$1
    shift || fatal "${FUNCNAME[1]} usage error"
    for trap_add_name in "$@"; do
        trap -- "$(
            # helper fn to get existing trap command from output
            # of trap -p
            # shellcheck disable=SC2329
            extract_trap_cmd() { printf '%s\n' "${3:-}"; }
            # print existing trap command with newline
            eval "extract_trap_cmd $(trap -p "${trap_add_name}")"
            # print the new trap command
            printf '%s\n' "${trap_add_cmd}"
        )" "${trap_add_name}" ||
            fatal "unable to add to trap ${trap_add_name}"
    done
}
# set the trace attribute for the above function.  this is
# required to modify DEBUG or RETURN traps because functions don't
# inherit them unless the trace attribute is set
declare -f -t trap_add
