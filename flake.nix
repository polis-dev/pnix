{
  description = "Polis NIX utilities (with zero dependencies!).";
  outputs = {self}:
    with builtins; rec {
      /*
      trivial (one-liners, self describing)
      */
      lib.archList = ["x86_64" "aarch64" "powerpc" "riscv32" "riscv64" "mips64el" "mipsel" "armv7l" "i686"];
      lib.colonSeparated = concatStringsSep ":";
      lib.const = lib.fromTOMLFile ./const.toml;
      lib.currentArch = elemAt lib.currentSystemPair 0;
      lib.currentDir = lib.getEnvOrDefault "PWD" "${self.outPath}";
      lib.currentHomeDir = lib.getEnvOrDefault "HOME" lib.const.default.homeDir;
      lib.currentOS = elemAt lib.currentSystemPair 1;
      lib.currentShell = lib.getEnvOrDefault "SHELL" "/bin/bash";
      lib.currentSystem = lib.getAttrOrDefault "currentSystem" builtins lib.unknownSystem;
      lib.currentSystemPair = match "(.*)-(.*)" lib.currentSystem;
      lib.currentUser = lib.getEnvOrDefault "USER" "nobody";
      lib.dashSeparated = concatStringsSep "-";
      lib.defaultSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin" "aarch64-linux"];
      lib.defaultSystemsMap = lib.eachSystemMap lib.defaultSystems;
      lib.eachDefaultSystem = lib.eachSystem lib.defaultSystems;
      lib.dotSeparated = concatStringsSep ".";
      lib.fromJSONFile = path: fromJSON (readFile path);
      lib.fromTOMLFile = path: fromTOML (readFile path);
      lib.getExe = drv: "${drv}${drv.passthru.exePath or "/bin/${drv.pname or drv.name}"}";
      lib.isApp = x: isAttrs x && x ? type && x.type == "app";
      lib.isBSD = lib.isFreeBSD || lib.isNetBSD || lib.isOpenBSD;
      lib.isDarwin = lib.currentOS == "darwin";
      lib.isDerivation = x: isAttrs x && x ? type && x.type == "derivation";
      lib.isFTP = lib.uriProtoEquals "ftp";
      lib.isFreeBSD = lib.currentOS == "freebsd";
      lib.isGIT = lib.uriProtoEquals "git";
      lib.isGitHub = lib.uriDomainEquals "github.com";
      lib.isGitLab = lib.uriDomainEquals "gitlab.com";
      lib.isHTTP = lib.uriProtoEquals "http";
      lib.isHTTPS = lib.uriProtoEquals "https";
      lib.isLinux = lib.currentOS == "linux";
      lib.isNetBSD = lib.currentOS == "netbsd";
      lib.isOpenBSD = lib.currentOS == "openbsd";
      lib.isSSH = lib.uriProtoEquals "ssh";
      lib.lineSeparated = concatStringsSep "\n";
      lib.nameValuePair = name: value: {inherit name value;};
      lib.nixVersion = nixVersion;
      lib.nixVersionAtLeast = lib.versionAtLeast nixVersion;
      lib.nixVersionLessThan = lib.versionLessThan nixVersion;
      lib.nixVersionMatches = lib.versionMatches nixVersion;
      lib.nixVersionOutdated = !(lib.nixVersionAtLeast "2.11");
      lib.osList = ["linux" "darwin" "freebsd" "openbsd" "netbsd" "none" "cygwin" "mingw32" "mingw64" "haiku"];
      lib.pipe = val: functions: foldl' (x: f: f x) val functions;
      lib.pnix.lastModifiedDate = self.sourceInfo.lastModifiedDate;
      lib.pnix.narHash = self.sourceInfo.narHash;
      lib.possibleSystems = concatMap (arch: map (os: "${arch}-${os}") lib.osList) lib.archList;
      lib.semicolonSeparated = concatStringsSep ";";
      lib.spaceSeparated = concatStringsSep " ";
      lib.tabSeparated = concatStringsSep "\t";
      lib.toJSONFile = name: value: toFile name (toJSON value);
      lib.toXMLFile = name: value: toFile name (toXML value);
      lib.unknownSystem = "unknown-unknown";
      lib.uriDomain = v: elemAt (match "^.*://([^/]+)/?(.*)?$" "${v}") 0;
      lib.uriDomainEquals = a: b: lib.uriDomain "${b}" == "${a}";
      lib.uriProto = v: elemAt (match "^(.*)://.*$" "${v}") 0;
      lib.uriProtoEquals = a: b: lib.uriProto "${b}" == "${a}";
      lib.versionAtLeast = a: b: (compareVersions a b) >= 0;
      lib.versionLessThan = a: b: (compareVersions a b) < 0;
      lib.versionMatches = a: b: (compareVersions a b) == 0;

      /*
      chooses the larger of two numbers.
      */
      lib.max = x: y:
        if x > y
        then x
        else y;

      /*
      chooses the smaller of two numbers.
      */
      lib.min = x: y:
        if x < y
        then x
        else y;

      /*
      attempt to get an attribute value named "n" from attribute set "s"
      otherwise use default value "v".
      */
      lib.getAttrOrDefault = n: s: v:
        if hasAttr n s
        then getAttr n s
        else v;

      /*
      attempt to get an env var value named "n" otherwise use default value "v".
      */
      lib.getEnvOrDefault = n: v:
        if getEnv n != ""
        then getEnv n
        else v;

      /*
      Used to match Nix flake's convention for defining runnable apps.
      */
      lib.mkApp = {
        drv,
        name ? drv.pname or drv.name,
        exePath ? drv.passthru.exePath or "/bin/${name}",
      }: {
        type = "app";
        program = "${drv}${exePath}";
      };

      /*
      Used to match Nix flake's convention. Basically transforms
       packages = { hello = <derivation>; };
      into
       packages = { x86_64-linux.hello = <derivation>; };
      */
      lib.eachSystemMap = systems: f:
        listToAttrs (map (system: {
            name = system;
            value = f system;
          })
          systems);

      /*
      Used to match Hydra's convention of how to define jobs. Basically transforms
         hydraJobs = {
           hello = <derivation>;
           haskellPackages.aeson = <derivation>;
         }
      to
       hydraJobs = {
         hello.x86_64-linux = <derivation>;
         haskellPackages.aeson.x86_64-linux = <derivation>;
       }
      */
      lib.eachSystem = systems: f: let
        # if the given flake does `eachSystem [ "x86_64-linux" ] { ... }`.
        pushDownSystem = system: merged:
          mapAttrs
          (name: value:
            if ! (isAttrs value)
            then value
            else if lib.isDerivation value
            then (merged.${name} or {}) // {${system} = value;}
            else pushDownSystem system (merged.${name} or {}) value);
        # merge the outputs for all systems.
        op = attrs: system: let
          ret = f system;
          op = attrs: key: let
            appendSystem = key: system: ret:
              if key == "hydraJobs"
              then (pushDownSystem system (attrs.hydraJobs or {}) ret.hydraJobs)
              else {${system} = ret.${key};};
          in
            attrs
            // {
              ${key} =
                (attrs.${key} or {})
                // (appendSystem key system ret);
            };
        in
          foldl' op attrs (attrNames ret);
      in
        foldl' op {} systems;

      lib.filterAttrs = pred: set:
        listToAttrs (
          concatMap
          (name: let
            v = set.${name};
          in
            if pred name v
            then [(lib.nameValuePair name v)]
            else [])
          (attrNames set)
        );

      lib.filterPackages = system: packages:
        lib.filterAttrs (n: v:
          lib.isDerivation v
          && !(meta.broken or false)
          && !(elem system (meta.badPlatforms or []))
          && (elem system (meta.platforms or lib.defaultSystems)))
        packages;
    };
}
