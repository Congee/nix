with import <nixpkgs> {};

buildGoModule rec{
  pname = "hydra";
  version = "v1.10.3";
  vendorSha256 = "05x0g74i4l7nxjmc3wl6z9w82s5qqavj9a47wdb1kn029vkpasp0";

  src = builtins.fetchGit {
    url = "https://github.com/ory/hydra.git";
    ref = "master";
    rev = "cbf1c976fa8259a3d2c4cd9f6d3b54d4d1383179";
  };

  # tries to connect to sqlite. nope
  doCheck = false;

  postInstall = ''
    find -L $out/bin -type f -not -name hydra -delete
  '';

  meta = with lib; {
    description = "OpenID Certified™ OpenID Connect and OAuth Provider written in Go - cloud native, security-first, open source API security for your infrastructure. SDKs for any language. Compatible with MITREid.";
    homepage = "https://www.ory.sh/hydra";
    licenses = licenses.apache2;
    maintainers = with maintainers; [ congee ];
    mainProgram = "hydra";
  };
}
