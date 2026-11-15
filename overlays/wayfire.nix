# Wayfire 0.11 adds ext-data-control-v1 (vicinae clipboard history).
# Taken from NixOS/nixpkgs#492535; drop once nixpkgs has wayfire >= 0.11.
final: prev: {
  wf-config = prev.wf-config.overrideAttrs (_: {
    version = "0.11.0";
    src = final.fetchFromGitHub {
      owner = "WayfireWM";
      repo = "wf-config";
      rev = "v0.11.0";
      hash = "sha256-hZcmnteB8/DbKjQGY1QLSI32z+OBnp1b8RjJ8pPH1JY=";
    };
  });

  wayfire = (prev.wayfire.override { wlroots_0_19 = final.wlroots_0_20; }).overrideAttrs (o: {
    version = "0.11.0";
    src = final.fetchFromGitHub {
      owner = "WayfireWM";
      repo = "wayfire";
      rev = "v0.11.0";
      fetchSubmodules = true;
      hash = "sha256-G6GakEpnqw3xORXP7mr2YoyAEymozV0CYeof+a1Nh74=";
    };
    postPatch = "";
    patches = [
      (final.fetchpatch {
        name = "wayfire_fix_hermiticity";
        url = "https://github.com/WayfireWM/wayfire/commit/6cf51df330564d97d922cdaa84e0e130311d8337.patch";
        hash = "sha256-Drs5wuyF4cfzm3Jdv0fv05FeWjqNhHfVzJK7ZLM04v0=";
      })
      (final.fetchpatch {
        name = "wayfire_fix_squeezimize";
        url = "https://github.com/WayfireWM/wayfire/commit/2bd9c6d175a788ba057add7eb762e8b0ca4ea7cd.patch";
        hash = "sha256-pG6tnYiff9gj1AM6mNzhmU8JjoevSlMWeY0XREYq38Q=";
      })
    ];
    propagatedBuildInputs = o.propagatedBuildInputs ++ [ final.libgbm ];
  });

  wayfirePlugins = prev.wayfirePlugins.overrideScope (_: wprev: {
    wcm = wprev.wcm.overrideAttrs (o: {
      version = "0.11.0-unstable-2026-07-28";
      src = final.fetchFromGitHub {
        owner = "WayfireWM";
        repo = "wcm";
        rev = "14f2e03fc4bfa3a20d10b913461636363e39240c";
        fetchSubmodules = true;
        hash = "sha256-ShclD93AQDHXwjCDTN8zom1xr3v4oMKLzO2q7B3ZAPg=";
      };
      nativeBuildInputs = o.nativeBuildInputs ++ [ final.fmt.dev ];
      buildInputs = o.buildInputs ++ [ final.fmt ];
    });
  });
}
