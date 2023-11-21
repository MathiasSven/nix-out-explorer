# set -o errexit
# set -o pipefail
# set -e
set -Eeuo pipefail
# nixosVersion=$(curl -s "https://nix-channels.s3.amazonaws.com/" \
#   | xmllint --xpath "/*/*[local-name()='Contents']/*[local-name()='Key']/text()" - \
#   | grep "nixos-[[:digit:]]" | tail -1 | cut -f1 -d"/")

# nixosReleaseUrl=$(curl -Ls -o /dev/null -w %{url_effective} "https://channels.nixos.org/nixos-23.05")
# nixosRevision=$(curl "$nixosReleaseUrl/git-revision")
# nixosPackages=$(curl "$nixosReleaseUrl/packages.json.br")

# https://channels.nixos.org/

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
bash
rm -rf "$finalDir"
