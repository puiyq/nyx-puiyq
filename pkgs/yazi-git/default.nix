{
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "yazi_git";
  prev = prev.yazi;

  versionNyxPath = "pkgs/yazi-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "sxyazi";
    repo = "yazi";
  };

  preOverride = _prevAttrs: {
    cargoPatches = [ ];
    patches = [ ];
    sourceRoot = "source";
  };

  postOverride =
    prevAttrs:
    let
      dateStr = builtins.substring 9 8 prevAttrs.version;
      dateParts = builtins.match "(.{4})(.{2})(.{2})" dateStr;
      buildDate = if dateParts != null then builtins.concatStringsSep "-" dateParts else "1970-01-01";
    in
    {
      doCheck = false;

      "env.YAZI_GEN_COMPLETIONS" = "true";
      "env.VERGEN_GIT_SHA" = prevAttrs.src.rev or "unknown";
      "env.VERGEN_BUILD_DATE" = buildDate;
    };
}
