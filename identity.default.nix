# Public placeholder identity, used by CI (Garnix) and by anyone who builds this
# flake without an override. It intentionally does NOT contain a real username.
#
# To build with your real identity, keep it OUT of this repo and select it with:
#   --override-input identity path:$HOME/.secrets/identity.nix
# where $HOME/.secrets/identity.nix contains e.g.:
#   { username = "yourname"; }
{
  username = "nixbuilder";
}
