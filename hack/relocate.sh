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

readonly BUNDLE=${BUNDLE?:registry must be specified}
readonly DIR=${DIR:?directory with package to relocate}

readonly root=$(cd $(dirname $0)/.. && pwd)
readonly scratch=$(mktemp -d)

main() {
        cd $root
        show_vars

        local release_dir=$(realpath $DIR)
        relocate_imgpkg_bundle_to_registry $release_dir
        patch_package_image $release_dir
}

show_vars() {
        echo "
        BUNDLE                  $BUNDLE

        root                    $root
        scratch                 $scratch
        "
}

relocate_imgpkg_bundle_to_registry() {
        local release_dir=$1

        local bundle_tarball=$release_dir/bundle.tar
        local repository=$BUNDLE
        local image

        imgpkg copy \
                --tar $bundle_tarball \
                --to-repo $repository \
                --lock-output $scratch/bundle.lock.yaml
}

patch_package_image() {
        local release_dir=$1
        local package_file=$release_dir/package.yaml
        local bundle_image

        bundle_image=$(_image_from_lockfile $scratch/bundle.lock.yaml)

        update_image_field_from_file $package_file $bundle_image
}

update_image_field_from_file() {
        local filename=$1
        local new_image=$2

        sed -i -e "s#image: .*#image: $new_image#g" $filename
}

_image_from_lockfile() {
        local lockfile=$1

        awk -F"image: " '{if ($2) print $2;}' $lockfile
}

main "$@"
