with import <nixpkgs/lib>;
let
  getBuildablesFor = system:
    (import ../../ci.nix { inherit system; }).buildables;
  darwinBuildables = getBuildablesFor "x86_64-darwin";
  linuxBuildables = getBuildablesFor "x86_64-linux";

  # str -> str -> str:
  # mkJobName "x86_64-darwin" "nested.package" -> "nested_package-x86_64-darwin"
  mkJobName = system: attrPath:
    "${replaceStrings [ "." ] [ "_" ] attrPath}-${system}";

  mkDarwinJobName = mkJobName "x86_64-darwin";
  mkLinuxJobName = mkJobName "x86_64-linux";

  mkJob = runs-on: attributes: {
    inherit runs-on;
    steps = [
      { uses = "actions/checkout@v2"; }
      { uses = "cachix/install-nix-action@v8"; }
      {
        uses = "cachix/cachix-action@v5";
        "with" = {
          name = "kreisys";
          signingKey = "'\${{ secrets.CACHIX_SIGNING_KEY }}'";
          inherit attributes;
        };
      }
    ];
  };

  mkDarwinJob = mkJob "macos-latest";
  mkLinuxJob = mkJob "ubuntu-latest";

  linuxJobs = pipe linuxBuildables [
    ((flip genAttrs) id)
    (mapAttrs' (n: v: nameValuePair (mkLinuxJobName n) (mkLinuxJob v)))
  ];

  darwinJobs = pipe darwinBuildables [
    ((flip genAttrs) id)
    (mapAttrs' (n: v: nameValuePair (mkDarwinJobName n) (mkDarwinJob v)))
  ];

in builtins.toJSON {
  name = "CI";
  on.push.branches = [ "master" ];
  jobs = linuxJobs // darwinJobs;
}
