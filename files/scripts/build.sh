#!/usr/bin/env bash
# shellcheck disable=SC2310

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cd /tmp
################----PERSONAL-START----################
# Boilerplate
# `:` == `true`
# `x || :` == `x || true` to ignore command failure
curl_gh() {
  command curl -sL \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "$@"
}

grep -qF defaultyes=True /etc/dnf/dnf.conf || printf '%s\n' defaultyes=True | tee -a /etc/dnf/dnf.conf

# Hermes
kver="$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core | sort -V | tail -n1)"
dnf5 -y install "$(curl_gh https://api.github.com/repos/MrOz59/Hermes/releases \
    | jq -r --arg ver "$fedora_ver" '[.[0].assets[].browser_download_url] |
    (map(select(contains(".fc" + $ver))).[0]) // (map(select(contains(".fc"))) | sort[-1])')"
# Hermes-KMS
git clone https://github.com/MrOz59/Hermes-KMS.git --single-branch \
    -b "$(curl_gh 'https://api.github.com/repos/MrOz59/Hermes-KMS/tags' | jq -r '.[0].name')" /tmp/hermes-kms
cd /tmp/hermes-kms
make modules KERNELRELEASE="${kver}" KDIR="/usr/lib/modules/${kver}/build" && \
make modules-install KERNELRELEASE="${kver}" DESTDIR=/
"/usr/lib/modules/${kver}/build/scripts/sign-file" sha512 /tmp/SB_KEY /tmp/SB_CERT \
    /usr/lib/modules/${kver}/extra/hermes-kms/hermes_kms.ko

### Gaming (Steam flatpak)
#dnf5 -y copr enable faugus/faugus-launcher
#dnf5 -y install faugus-launcher
#dnf5 config-manager disable copr:copr.fedorainfracloud.org:faugus:faugus-launcher
# ###

# Other softwares
                # pyside6-tools
                # cmake fakeroot mujs patch pigz rhash (included in brew)
# pesign doesn't have sysusers, fixed in F45
[ -f /usr/lib/sysusers.d/pesign.conf ] || printf '%s\n' "u pesign - 'Group for the pesign signing daemon' /run/pesign -" | tee /usr/lib/sysusers.d/pesign.conf
################----PERSONAL-END----################
