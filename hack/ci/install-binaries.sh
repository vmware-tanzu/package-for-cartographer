#!/usr/bin/env bash
# Copyright 2022 VMware
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -o errexit
set -o nounset
set -o pipefail

readonly gh_checksum=76bd37160c61cf668b96a362ebc01d23736ebf94ec9dfe3090cacea37fd3b3fb
readonly gh_version=2.2.0
readonly grype_checksum=a0aaae28792a70fd465301cef0f3dc4bd09c2e707208f7a576e4085c8ea861d4
readonly grype_version=0.27.2
readonly kapp_checksum=5d5c4274a130f2fd5ad11ddd8fb3e0f647c8598ba25711360207fc6eab72f6be
readonly kapp_version=0.42.0
readonly ko_checksum=0b1fa3ec34f095675d1b214e6bfde1e5b73a199378e830830ec81fec3484645e
readonly ko_version=0.9.3
readonly tanzu_checksum=25e19a1e90b540dbc4fd337574a122c8450c574f5d9ed4464bb146beea8c628a
readonly tanzu_version=0.17.0
readonly ytt_checksum=2ca800c561464e0b252e5ee5cacff6aa53831e65e2fb9a09cf388d764013c40d
readonly ytt_version=0.38.0
readonly kbld_checksum=de546ac46599e981c20ad74cd2deedf2b0f52458885d00b46b759eddb917351a
readonly kbld_version=0.32.0
readonly imgpkg_checksum=14ce0b48a3a00352cdf0ef263aa98a9bcd90d5ea8634fdf6b88016e2a08f09d1
readonly imgpkg_version=0.25.0

main() {
        cd $(mktemp -d)

        for binary in $@; do
                eval install_$binary
        done
}

install_imgpkg() {
        local url=https://github.com/vmware-tanzu/carvel-imgpkg/releases/download/v${imgpkg_version}/imgpkg-linux-amd64
        local fname=imgpkg-linux-amd64

        curl -sSOL $url
        echo "${imgpkg_checksum}  $fname" | sha256sum -c

        install -m 0755 $fname /usr/local/bin/imgpkg
}

install_kbld() {
        local url=https://github.com/vmware-tanzu/carvel-kbld/releases/download/v${kbld_version}/kbld-linux-amd64
        local fname=kbld-linux-amd64

        curl -sSOL $url
        echo "${kbld_checksum}  $fname" | sha256sum -c

        install -m 0755 $fname /usr/local/bin/kbld
}

install_ytt() {
        local url=https://github.com/vmware-tanzu/carvel-ytt/releases/download/v${ytt_version}/ytt-linux-amd64
        local fname=ytt-linux-amd64

        curl -sSOL $url
        echo "${ytt_checksum}  $fname" | sha256sum -c

        install -m 0755 $fname /usr/local/bin/ytt
}

install_kapp() {
        local url=https://github.com/vmware-tanzu/carvel-kapp/releases/download/v${kapp_version}/kapp-linux-amd64
        local fname=kapp-linux-amd64

        curl -sSOL $url
        echo "${kapp_checksum}  $fname" | sha256sum -c

        install -m 0755 $fname /usr/local/bin/kapp
}

install_grype() {
        local url=https://github.com/anchore/grype/releases/download/v${grype_version}/grype_${grype_version}_linux_amd64.tar.gz
        local fname=grype_${grype_version}_linux_amd64.tar.gz

        curl -sSOL $url
        echo "${grype_checksum}  $fname" | sha256sum -c
        tar xzf $fname

        install -m 0755 ./grype /usr/local/bin
}

install_ko() {
        local url=https://github.com/google/ko/releases/download/v${ko_version}/ko_${ko_version}_Linux_x86_64.tar.gz
        local fname=ko_${ko_version}_Linux_x86_64.tar.gz

        curl -sSOL $url
        echo "${ko_checksum}  $fname" | sha256sum -c
        tar xzf $fname

        install -m 0755 ./ko /usr/local/bin
}

install_gh() {
        local url=https://github.com/cli/cli/releases/download/v${gh_version}/gh_${gh_version}_linux_amd64.tar.gz
        local fname=gh_${gh_version}_linux_amd64.tar.gz

        curl -sSOL $url
        echo "${gh_checksum}  $fname" | sha256sum -c
        tar xzf $fname --strip-components=1

        mv ./bin/gh /usr/local/bin
}

install_tanzu() {
        local url=https://github.com/vmware-tanzu/tanzu-framework/releases/download/v${tanzu_version}/tanzu-cli-linux-amd64.tar.gz
        local fname=tanzu-cli-linux-amd64.tar.gz

        curl -sSOL $url
        echo "${tanzu_checksum}  $fname" | sha256sum -c
        tar xzf $fname --strip-components=1

        mv tanzu-core-linux_amd64 /usr/local/bin/tanzu
        tanzu init
}

main "$@"
