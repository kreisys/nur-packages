{ coreutils, lib, grid, stdenv, bashInteractive, shfmt, writeText, runCommand, utillinux }:

with lib;

name: description: { packages ? [], arguments ? [], aliases ? [], options ? [], flags ? [], preInit ? "", init ? "", meta ? {} }: action: let
  defaultFlags = [ (mkFlag "h" "help" "show help")
                   (mkFlag "p" "porcelain" "opt for machine-friendly output") ];

  mkArgument = name:                 description: { inherit name               description; };
  mkFlag     = short: long:          description: { inherit short long         description; };
  mkOption   = short: long: default: description: { inherit short long default description; };

  mkGetOpts = { usage, options ? [], flags ? [], ... }: ''
    # Setup defaults
    ${concatMapStrings ({ long, ... }: ''
      ${toUpper long}=false
      ${long}=false
    '') (defaultFlags ++ flags)}

    ${concatMapStrings ({ long, default ? null, ...}: ''
      ${optionalString (default != null) ''
        ${toUpper long}="${default}"
        ${long}="${default}"
      ''}
    '') options}

    while [[ $# > 0 ]]; do
      key="$1"

      case $key in
        ${concatMapStrings ({ short, long, ... }:
        ''-${short} | --${long} )
          ${toUpper long}=true
          ${long}=true
          shift
          ;;
          '') (defaultFlags ++ flags)}
        ${concatMapStrings ({ short, long, ... }:
        ''-${short} | --${long} )
          ${toUpper long}="$2"
          ${long}="$2"
          shift 2
          ;;
          '') options}
        *) break ;;
      esac
    done

    # Assert all options are defined
    ${concatMapStrings ({ long, ... }: ''
      if ! [[ -v ${toUpper long} ]] && ! $HELP; then
        err "required option '${long}' has not been set"
        exit=1
        HELP=true
      fi
    '') options}

    if $HELP; then
      exit=0
      if $PORCELAIN; then
        printf -- "${name}\t${description}\n"
      else
        . ${usage}

        if compgen -c ${name}- &>/dev/null; then
          echo 'Addon Commands:'
          compgen -c ${name}- | sed 's/$/ --help --porcelain/' | bash | sort | uniq | sed 's/^${name}-/   /' | sed 's/\t/#| /' | column -t -s#
        fi
      fi
    fi

    if [[ -v exit ]]; then
      exit $exit
    fi
  '';

  mkUsageText = { name, description, arguments ? [], flags ? [], options ? [], commands ? [], previous ? [], ... }: let
    hasCommands = commands != [] && ! builtins.isString commands;
    usageText = ''
      Usage: ${concatStringsSep " " (previous ++ [ name ])} [options/flags] ${optionalString hasCommands "<command> "}${concatMapStringsSep " " ({ name, ... }: "<${name}>") arguments}

        ${description}

    '' + (optionalString (arguments != []) ''
      Arguments:
      ${grid.gridToStringLeft (map ({ name, description, ... }: [
        "    "       # indentation
        name         # argument name
        " |"         # separator
        description  # description
      ]) arguments)}
    '') + (optionalString ((defaultFlags ++ flags) != []) ''
      Flags:
      ${grid.gridToStringLeft (map ({ short, long, description, ... }: [
        "    "       # indentation
        "--${long}"  # long form
        "-${short}"  # short form
        " |"         # separator
        description  # description
      ]) (defaultFlags ++ flags))}
    '') + (optionalString (options != []) ''
      Options:
      ${grid.gridToStringLeft (map ({ short, long, default, description, ... }: [
        "    "       # indentation
        "--${long}"  # long form
        "-${short}"  # short form
        " |"         # separator
        description  # description
        "   [ ${if default != null then "default: ${default}" else "required"} ]"
      ]) options)}
    '') + (optionalString hasCommands ''
      Commands:
      ${grid.gridToStringLeft (map ({ name, description, aliases ? [], ... }: [
        "    "                                            # indentation
        (concatStringsSep ", " ([ name ] ++ aliases)) # command name and aliases
        " |"                                              # separator
        description                                       # description
      ]) commands)}
    '');
  in ''
    cat <<EOF
    ${usageText}
    EOF
  '';

  mkUsage = { name, ... }@c: writeText "${name}-usage.txt" (mkUsageText c);

  mkCli =
    { action
    , name
    , description
    , preInit   ? ""
    , init      ? ""
    , arguments ? []
    , flags     ? []
    , options   ? []
    , previous  ? []
    , packages  ? []
    , ... }@c:

    assert ! builtins.isString action -> arguments == [];
  let
    mkCommand = name: description: { preInit ? "", init ? "", arguments ? [], aliases ? [], options ? [], flags ? [], packages ? [] }: action: {
      inherit action preInit init arguments aliases description flags name options packages;
    };

    commands   = if builtins.isFunction    action then    action mkCommand  else    action;
    arguments' = if builtins.isFunction arguments then arguments mkArgument else arguments;
    flags'     = if builtins.isFunction     flags then     flags mkFlag     else     flags;
    options'   = if builtins.isFunction   options then   options mkOption   else   options;

    usage = mkUsage (c // {
      inherit commands previous;

      arguments = arguments';
      options   = options';
      flags     = flags';
    });

    currentName = name;

  in ''
    PATH=${makeBinPath packages}:$PATH

    ${preInit}

    ${mkGetOpts (c // {
      inherit usage;

      options = options';
      flags   = flags';
    })}

    ${init}

    ${if builtins.isString commands then ''
      ${concatMapStrings ({ name, ...}: ''
        if [[ $# > 0 ]]; then
          ${toUpper name}=$1
          ${name}=$1
          shift
        else
          err "argument '${name}' has not been specified"
          args_failed=
        fi
      '') arguments'}

      if [[ -v args_failed ]] || $HELP; then
        . ${usage}
        exit 1
      fi

      ${commands}

    '' else ''

    if [[ $# > 0 ]]; then
      cmd=$1
      shift
    else
      . ${usage}
      exit 1
    fi

    case $cmd in
      ${concatMapStrings ({ name, aliases ? [], ... }@c: ''
        ${name}${optionalString (aliases != []) "|${concatStringsSep "|" aliases}"})
          ${mkCli (c // { previous = previous ++ [ currentName ]; })}
          ;;
        '') commands}
      *)
        if [[ -n $cmd ]]; then
          err "unknown command: $cmd"
        fi

        . ${usage}
        ;;
    esac
    ''}
  '';

in stdenv.mkDerivation ({
  inherit name meta;

  phases      = [ "buildPhase" "checkPhase" ];
  buildInputs = [ shfmt ];

  buildPhase = ''
    mkdir -p $out/bin

    cd $_

    cat <<'EOF' | shfmt -i 2 > ${name}
    #!${bashInteractive}/bin/bash

    set -euo pipefail

    PATH=${lib.makeBinPath [ coreutils ]}:$PATH

    stderr() {
      1>&2 echo -e "$@"
    }

    err() {
      stderr "\e[31merror\e[0m:" "$@"
    }

    fatal() {
      stderr "\e[31mfatal\e[0m:" "$@"
      exit 1
    }

    warn() {
      stderr "\e[33mwarning\e[0m:" "$@"
    }

    cleanup() {
      chmod -R +w $TMP
      rm -rf $_
    }

    trap_add() {
      trap_add_cmd=$1; shift || fatal "$FUNCNAME usage error"
      for trap_add_name in "$@"; do
        trap -- "$(
          extract_trap_cmd() { printf '%s\n' "$3"; }
          eval "extract_trap_cmd $(trap -p "$trap_add_name")"
          printf '%s\n' "$trap_add_cmd"
        )" "$trap_add_name" \
          || fatal "unable to add to trap $trap_add_name"
      done
    }

    TMP=$(mktemp -d --tmpdir ${name}.XXXXXX)
    trap cleanup EXIT

    ${mkCli { inherit arguments action name description options flags preInit init packages; } }

    EOF

    chmod +x ${name}
    ${concatMapStrings (alias: ''
      ln -s ${name} ${alias}
    '') aliases}
  '';

  checkPhase = ''
    true
  '';
})
