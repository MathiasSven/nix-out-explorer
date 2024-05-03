systems="$(nix eval --raw --impure --expr 'builtins.currentSystem')"

systems+=("x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" \
      "armv6l-linux" "armv7l-linux" "i686-linux" "mipsel-linux" \
      "armv5tel-linux" "powerpc64le-linux" "riscv64-linux")

baseUrl="https://cache.nixos.org/"

finalDir=$(mktemp -d)

getSystems() {
  IFS=$'\n'
  echo "${systems[*]}" | uniq | fzf -q "" -e -m \
    --layout=reverse \
    --marker='>>'
}

fetch() {
  export NIXPKGS_ALLOW_BROKEN=1
  nixOutPath=$(nix eval nixpkgs-stable#$2.outPath --system $1 --raw --impure)
  outPathHask=$(echo "$nixOutPath" | cut -d '/' -f4 | cut -d '-' -f1)
  narUrlField=$(curl "$baseUrl$outPathHask.narinfo" | grep URL)
  narUrl="${narUrlField#URL: }"

  mkdir "$finalDir/$1"
  curl "$baseUrl$narUrl" | xz -dc | nix-store --restore "$finalDir/$1/$2-out/"
}

mapfile -t selectedSystems < <( getSystems )
mapfile -t selectedDrv < <( nixfzf --raw )

for system in "${selectedSystems[@]}";
do 
  for drv in "${selectedDrv[@]}";
  do
    fetch $system $drv
  done
done

cd "$finalDir"
$SHELL
rm -rf "$finalDir"
