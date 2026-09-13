#!/usr/bin/env bash
set -euo pipefail

# User-local, checksum-verified toolchain installer for Ubuntu WSL.
# No sudo, AWS credentials, or global package-manager changes are required.

tools_root="${XDG_DATA_HOME:-${HOME}/.local/share}/orderflow-tools"
bin_dir="${HOME}/.local/bin"
temp_dir="$(mktemp -d)"

cleanup() {
  case "${temp_dir}" in
    /tmp/*) rm -rf -- "${temp_dir}" ;;
    *) printf 'Refusing to remove unexpected temporary path: %s\n' "${temp_dir}" >&2 ;;
  esac
}
trap cleanup EXIT

require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Required bootstrap tool is missing: %s\n' "$1" >&2
    exit 1
  }
}

for bootstrap_tool in curl tar sha256sum install awk grep; do
  require "${bootstrap_tool}"
done

install -d -m 0755 "${bin_dir}" "${tools_root}"

node_shasums="${temp_dir}/node-SHASUMS256.txt"
curl --fail --silent --show-error --location \
  https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt \
  --output "${node_shasums}"
node_archive="$(awk '/linux-x64\.tar\.xz$/ {print $2; exit}' "${node_shasums}")"
test -n "${node_archive}"
node_version="${node_archive#node-}"
node_version="${node_version%-linux-x64.tar.xz}"
curl --fail --silent --show-error --location \
  "https://nodejs.org/dist/latest-v24.x/${node_archive}" \
  --output "${temp_dir}/${node_archive}"
(
  cd "${temp_dir}"
  grep " ${node_archive}$" "${node_shasums}" | sha256sum --check
)
node_install_dir="${tools_root}/node-${node_version}"
if [[ ! -x "${node_install_dir}/bin/node" ]]; then
  install -d -m 0755 "${node_install_dir}"
  tar -xJf "${temp_dir}/${node_archive}" --strip-components=1 -C "${node_install_dir}"
fi
ln -sfn "${node_install_dir}/bin/node" "${bin_dir}/node"
ln -sfn "${node_install_dir}/bin/npm" "${bin_dir}/npm"
ln -sfn "${node_install_dir}/bin/npx" "${bin_dir}/npx"
ln -sfn "${node_install_dir}/bin/corepack" "${bin_dir}/corepack"

kubectl_version="v1.37.0"
curl --fail --silent --show-error --location \
  "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl" \
  --output "${temp_dir}/kubectl"
curl --fail --silent --show-error --location \
  "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl.sha256" \
  --output "${temp_dir}/kubectl.sha256"
printf '%s  %s\n' "$(<"${temp_dir}/kubectl.sha256")" "${temp_dir}/kubectl" | sha256sum --check
install -m 0755 "${temp_dir}/kubectl" "${bin_dir}/kubectl"

helm_version="v4.3.0"
helm_archive="helm-${helm_version}-linux-amd64.tar.gz"
curl --fail --silent --show-error --location \
  "https://get.helm.sh/${helm_archive}" \
  --output "${temp_dir}/${helm_archive}"
curl --fail --silent --show-error --location \
  "https://get.helm.sh/${helm_archive}.sha256sum" \
  --output "${temp_dir}/${helm_archive}.sha256sum"
(
  cd "${temp_dir}"
  sha256sum --check "${helm_archive}.sha256sum"
)
tar -xzf "${temp_dir}/${helm_archive}" -C "${temp_dir}"
install -m 0755 "${temp_dir}/linux-amd64/helm" "${bin_dir}/helm"

eksctl_archive="eksctl_Linux_amd64.tar.gz"
curl --fail --silent --show-error --location \
  "https://github.com/eksctl-io/eksctl/releases/latest/download/${eksctl_archive}" \
  --output "${temp_dir}/${eksctl_archive}"
curl --fail --silent --show-error --location \
  https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt \
  --output "${temp_dir}/eksctl_checksums.txt"
(
  cd "${temp_dir}"
  grep " ${eksctl_archive}$" eksctl_checksums.txt | sha256sum --check
)
tar -xzf "${temp_dir}/${eksctl_archive}" -C "${temp_dir}"
install -m 0755 "${temp_dir}/eksctl" "${bin_dir}/eksctl"

gh_version="2.100.0"
gh_archive="gh_${gh_version}_linux_amd64.tar.gz"
curl --fail --silent --show-error --location \
  "https://github.com/cli/cli/releases/download/v${gh_version}/${gh_archive}" \
  --output "${temp_dir}/${gh_archive}"
curl --fail --silent --show-error --location \
  "https://github.com/cli/cli/releases/download/v${gh_version}/gh_${gh_version}_checksums.txt" \
  --output "${temp_dir}/gh_checksums.txt"
(
  cd "${temp_dir}"
  grep " ${gh_archive}$" gh_checksums.txt | sha256sum --check
)
tar -xzf "${temp_dir}/${gh_archive}" -C "${temp_dir}"
install -m 0755 "${temp_dir}/gh_${gh_version}_linux_amd64/bin/gh" "${bin_dir}/gh"

export PATH="${bin_dir}:${PATH}"
printf 'node=%s\n' "$(node --version)"
printf 'npm=%s\n' "$(npm --version)"
printf 'kubectl=%s\n' "$(kubectl version --client --output=yaml | awk '/gitVersion:/ {print $2; exit}')"
printf 'helm=%s\n' "$(helm version --short)"
printf 'eksctl=%s\n' "$(eksctl version)"
printf 'gh=%s\n' "$(gh --version | awk 'NR == 1 {print $3}')"
