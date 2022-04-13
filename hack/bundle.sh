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

readonly root=$(cd $(dirname $0)/.. && pwd)

readonly NAME=${NAME:?name must be set}
readonly PACKAGE_NAME=${PACKAGE_NAME:?package name must be set}
readonly BUNDLE=${BUNDLE:?imgpkg bundle image name must be provided}
readonly DIR=${DIR:?directory to package must be provided}

readonly RELEASE_VERSION=${RELEASE_VERSION:?release version must be set}
readonly SCRATCH=${SCRATCH:-$(mktemp -d)}
readonly RELEASE_DIR=${RELEASE_DIR:-$root/release}
readonly RELEASE_DATE=${RELEASE_DATE:-$(TZ=UTC date +"%Y-%m-%dT%H:%M:%SZ")}

main() {
        cd $root
        show_vars

        local product_dir=$(realpath $DIR)

        create_imgpkg_bundle $product_dir
        create_carvel_packaging_objects $product_dir
        populate_release_dir $product_dir
}

show_vars() {
        echo "
        BUNDLE                  $BUNDLE
        DIR                     $DIR
        NAME                    $NAME
        PACKAGE_NAME            $PACKAGE_NAME

        RELEASE_DATE            $RELEASE_DATE
        RELEASE_DIR             $RELEASE_DIR
        RELEASE_VERSION         $RELEASE_VERSION
        SCRATCH                 $SCRATCH
        "
}

create_imgpkg_bundle() {
        local dir=$1

        mkdir -p $SCRATCH/bundle/{.imgpkg,config}

        cp -r $dir/README.md $SCRATCH/README.md
        cp -r $dir/config/{objects,overlays,upstream} $SCRATCH/bundle/config
        kbld \
                -f $dir/config/upstream \
                --imgpkg-lock-output $SCRATCH/bundle/.imgpkg/images.yml \
                >/dev/null

        imgpkg push -f $SCRATCH/bundle \
                --bundle $BUNDLE \
                --lock-output $SCRATCH/bundle.initial.lock.yaml

        imgpkg copy \
                --bundle $(_image_from_lockfile $SCRATCH/bundle.initial.lock.yaml) \
                --to-tar $SCRATCH/bundle.tar

        imgpkg copy \
                --tar $SCRATCH/bundle.tar \
                --to-repo $BUNDLE \
                --lock-output $SCRATCH/bundle.lock.yaml
}

create_carvel_packaging_objects() {
        local dir=$1
        local image

        image=$(_image_from_lockfile $SCRATCH/bundle.lock.yaml)
        mkdir -p $SCRATCH/package

        for package_fpath in ./packaging/{package,metadata}.yaml; do
                ytt --ignore-unknown-comments \
                        -f ./packaging/schema.yaml \
                        -f $package_fpath \
                        -f $dir/package-values.yaml \
                        --data-value name=$PACKAGE_NAME \
                        --data-value image=$image \
                        --data-value version=$RELEASE_VERSION \
                        --data-value released_at=$RELEASE_DATE > \
                        $SCRATCH/"$(basename $package_fpath)"
        done
}

# ./release/
# ├── cartographer
# │   ├── cartographer-bundle.tar
# │   ├── metadata.yaml
# │   └── package.yaml
# ...
# └── cartographer-tce
#     ├── cartographer-tce-bundle.tar
#     ├── metadata.yaml
#     └── package.yaml
#
populate_release_dir() {
        local dir=$1
        local release_dir=$RELEASE_DIR/$NAME

        mkdir -p $release_dir

        cp -r $SCRATCH/README.md $release_dir/README.md
        cp -r $SCRATCH/bundle.tar $release_dir/bundle.tar
        cp -r $SCRATCH/{package,metadata}.yaml $release_dir

        tree -a $RELEASE_DIR
}

_image_from_lockfile() {
        local lockfile=$1

        awk -F"image: " '{if ($2) print $2;}' $lockfile
}

main "$@"
