#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly root=$(cd $(dirname $0)/.. && pwd)
readonly scratch=$(mktemp -d)

main() {
        cd $root
        scan_bundle_images
}

scan_bundle_images() {
        local images=$(find_images_in_package ./release/package.yaml)

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
