{ pkgs, lib, fetchgit }:

let src = fetchgit { inherit (lib.importJSON ./pin.json) url rev sha256; };
in (import src { inherit pkgs; }).cli

