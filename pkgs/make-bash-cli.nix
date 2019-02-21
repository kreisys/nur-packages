{ lib, grid, stdenv, bash, shfmt, linkFarm, writeText, runCommand }:

let
  self = name: description: { arguments ? [], aliases ? [], env ? {}, options ? [], flags ? [] }: commandsFn: let
    command = name;
    defaultFlags = [ (mkFlag "h" "help" "show help") ];

    mkOption = short: long: default: description: { inherit short long default description; };
    mkFlag   = short: long:          description: { inherit short long         description; };

    mkGetOpts = { options ? [], flags ? [], ... }@c: let
      flags'   = if builtins.isFunction   flags then   flags mkFlag   else   flags;
      options' = if builtins.isFunction options then options mkOption else options;
    in ''
      # Setup defaults
      ${lib.concatMapStrings ({ long, ... }: ''
        ${lib.toUpper long}=false
      '') (defaultFlags ++ flags')}

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
          '') (defaultFlags ++ flags')}
        ${lib.concatMapStrings ({ short, long, ... }:
        ''-${short} | --${long} )
          ${lib.toUpper long}="$2"
          shift 2
          ;;
          '') options'}
        *) break ;;
      esac
      done

      # Assert all options are defined
      ${lib.concatMapStrings ({ long, ...}: ''
        if ! [[ -v ${lib.toUpper long} ]] && ! $HELP; then
          err "required option '${long}' has not been set"
          opts_failed=
        fi
      '') options'}

      if [[ -v opts_failed ]] || $HELP; then
        cat ${mkUsage c}
        exit 1
      fi
    '';

    mkUsageText = { name, description, flags ? [], options ? [], commands ? [], ... }: let
      flags'   = if builtins.isFunction   flags then   flags mkFlag   else   flags;
      options' = if builtins.isFunction options then options mkOption else options;
    in ''
      Usage: ${name} [options/flags] <command> [args]

        ${description}

    '' + (lib.optionalString ((defaultFlags ++ flags') != []) ''
      Flags:
      ${grid.gridToStringLeft (map ({ short, long, description, ... }: [
        "    "       # indentation
        "--${long}"  # long form
        "-${short}"  # short form
        " |"         # separator
        description  # description
      ]) (defaultFlags ++ flags'))}
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
    '') + (lib.optionalString (commands != [] && ! builtins.isString commands) ''
      Commands:
      ${grid.gridToStringLeft (map ({ command, description, aliases ? [], ... }: [
        "    "                                               # indentation
        (lib.concatStringsSep ", " ([ command ] ++ aliases)) # command name and aliases
        " |"                                                 # separator
        description                                          # description
      ]) commands)}
    '');

    mkUsage = { name, ... }@c: writeText "${name}-usage.txt" (mkUsageText c);

    mkCli = { name, description, flags, options, ... }@c: let 
      mkCommand = name: description: { arguments ? [], aliases ? [], options ? [], flags ? [] }@c: code: c // {
        inherit name commands description code;
        command = name;
      };

      commands = if builtins.isFunction commandsFn then commandsFn mkCommand else commandsFn;

      usage = mkUsage (c // { inherit commands; });

      commandsUsage = linkFarm "${name}-commands-usage" (lib.flatten (map ({ aliases ? [], command, ... }@c: let
        usage = mkUsage c;
      in [{
        name = command;
        path = usage;
      }] ++ (map (alias: {
        name = alias;
        path = usage;
      }) aliases)) commands));

    in ''
      ${mkGetOpts c}

      ${if builtins.isString commands then ''
        ${commands}
      '' else ''

      cmd=$1

      if [[ -n $cmd ]]; then shift; fi

      case $cmd in
        ${lib.concatMapStrings ({ name, code, aliases ? [], options ? [], flags ? [], ... }: ''
          ${name}${lib.optionalString (aliases != []) "|${lib.concatStringsSep "|" aliases}"})
            ${mkGetOpts c}
            ${code}
            ;;
          '') commands}
        help)
          if [[ -z $1 ]]; then
            cat ${usage}
          elif [[ -f ${commandsUsage}/$1 ]]; then
            cat ${commandsUsage}/$1
          else
            err "help: unknown command: $1"
          fi
          ;;
        *)
          if [[ -n $cmd ]]; then
            err "unknown command: $cmd"
          fi

          cat ${usage}
          ;;
      esac
      ''}
    '';

  in stdenv.mkDerivation ({
    inherit name;

    phases      = [ "buildPhase" "checkPhase" ];
    buildInputs = [ shfmt ];

    buildPhase = ''
      mkdir -p $out/bin

      cd $_

      cat <<'EOF' | shfmt -i 2 > ${name}
      #!${bash}/bin/bash

      set -eo pipefail

      stderr() {
        1>&2 echo -e "$@"
      }

      err() {
        stderr "\e[31merror\e[0m:" "$@"
      }

      ${mkCli { inherit name description options flags; } }

      EOF

      chmod +x ${name}
      ${lib.concatMapStrings (alias: ''
        ln -s ${name} ${alias}
      '') aliases}
    '';
    } // env);
  in self
