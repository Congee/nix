if [ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/ip') ]; then
  export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
fi
