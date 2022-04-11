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

readonly root=$(cd $(dirname $0)/.. && pwd)
readonly scratch=$(mktemp -d)

main() {
        cd $root

        for package_file in $(find ./release -name "package.yaml"); do
                scan_bundle_images $package_file
        done
}

scan_bundle_images() {
        local package_file=$1
        local images=$(find_images_in_package $package_file)

        for image in $images; do
                scan_image $image
        done
}

find_images_in_package() {
        local package_file=$1

        {
                imgpkg pull \
                        --bundle $(bundle_image_name $package_file) \
                        --output $scratch/bundle

                kbld \
                        -f $scratch/bundle \
                        --lock-output $scratch/images.yaml
        } >/dev/null

        cat $scratch/bundle/.imgpkg/images.yml | awk -F'image: ' '{if ($2) print $2;}'
}

scan_image() {
        local image=$1

        echo "
        Scanning image: $image
        "

        grype registry:$image
}

bundle_image_name() {
        local package_file=$1

        awk -F'image: ' '{if ($2) print $2;}' $package_file
}

main "$@"
