{ lib, grid, stdenv, bash, writeText, runCommand }:

name: description: { env ? {}, options ? [], flags ? [] }: commandsFn: let

  mkCommand = name: description: { aliases ? [], commands ? [], options ? [], flags ? [] }: code: rec {
    inherit name commands description aliases code options flags;
    command = name;
  };

  commands = commandsFn mkCommand;

  mkOption = short: long: default: description: { inherit short long default description; };
  mkFlag   = short: long: description: { inherit short long description; };

  mkGetOpts = { options ? [], flags ? [] }: let
    flags'   = if builtins.isFunction   flags then   flags mkFlag   else   flags;
    options' = if builtins.isFunction options then options mkOption else options;
  in ''
    POSITIONAL=()

    # Setup defaults
    ${lib.concatMapStrings ({ long, ... }: ''
      ${lib.toUpper long}=false
    '') flags'}

    ${lib.concatMapStrings ({ long, default ? null, ...}: ''
      ${lib.optionalString (default != null) ''
        ${lib.toUpper long}="${default}"
      ''}
    '') options'}

    while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
      ${lib.concatMapStrings ({ short, long, ... }:
      ''-${short} | --${long} )
        ${lib.toUpper long}=true
        shift
        ;;
        '') flags'}
      ${lib.concatMapStrings ({ short, long, ... }:
      ''-${short} | --${long} )
        ${lib.toUpper long}="$2"
        shift 2
        ;;
        '') options'}

      *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
    done
    set -- "''${POSITIONAL[@]}" # restore positional parameters
  '';

  usage = writeText "${name}-usage.txt" (mkUsageText { inherit name description flags options commands; });

  commandsUsage = runCommand "${name}-commands-usage" {} ''
    mkdir -p $out
    cd $_

    ${lib.concatMapStrings ({ command, ... }@c: ''
      cat <<EOF > ${command}
      ${mkUsageText c}
      EOF
    '') commands}
  '';

  mkUsageText = { name, description, flags, options, commands, ... }: let
    flags'   = if builtins.isFunction   flags then   flags mkFlag   else   flags;
    options' = if builtins.isFunction options then options mkOption else options;
  in ''
    Usage: ${name} [options/flags] <command> [args]

      ${description}

  '' + (lib.optionalString (flags != []) ''
    Flags:
    ${grid.gridToStringLeft (map ({ short, long, description, ... }: [
      "    "       # indentation
      "--${long}"  # long form
      "-${short}"  # short form
      " |"         # separator
      description  # description
    ]) flags')}
  '') + (lib.optionalString (options != []) ''
    Options:
    ${grid.gridToStringLeft (map ({ short, long, default, description, ... }: [
      "    "       # indentation
      "--${long}"  # long form
      "-${short}"  # short form
      " |"         # separator
      description  # description
      "   [ ${if default != null then "default: ${default}" else "required"} ]"
    ]) options')}
  '') + (lib.optionalString (commands != []) ''
    Commands:
    ${grid.gridToStringLeft (map ({ command, description, aliases, ... }: [
      "    "                                               # indentation
      (lib.concatStringsSep ", " ([ command ] ++ aliases)) # command name and aliases
      " |"                                                 # separator
      description                                          # description
    ]) commands)}
  '');

in stdenv.mkDerivation ({
  inherit name;
  phases = [ "buildPhase" "checkPhase" ];

  buildPhase = ''
    binary=$out/bin/${name}
    mkdir -p $(dirname $binary)

    cat <<'EOF' > $binary
    #!${bash}/bin/bash

    set -eo pipefail

    stderr() {
      1>&2 echo -e "$@"
    }

    err() {
      stderr "\e[31merror\e[0m:" "$@"
    }

    ${mkGetOpts { inherit options flags; }}

    cmd=$1

    if [[ -n $cmd ]]; then shift; fi

    case $cmd in
      ${lib.concatMapStrings ({ command, code, aliases, options, flags, ... }: ''
        ${command}${lib.optionalString (aliases != []) "|${lib.concatStringsSep "|" aliases}"})
          ${mkGetOpts { inherit options flags; }}
          ${code}
          ;;
        '') commands}
      help)
        if [[ -z $1 ]]; then
          cat ${usage}
        else
          cat ${commandsUsage}/$1
        fi
        ;;
      *)
        if [[ -n $cmd ]]; then
          err "unknown command: $cmd"
        fi

        cat ${usage}
        ;;
      esac
    EOF

    chmod +x $binary
    '';
} // env)
