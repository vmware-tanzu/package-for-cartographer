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

readonly BUNDLE=${BUNDLE:-imgpkg bundle image name must be provided and assumes the repo is \'package-for-cartographer\'}
readonly RELEASE_VERSION=${RELEASE_VERSION:-0.0.0}
readonly SCRATCH=${SCRATCH:-$(mktemp -d)}
readonly RELEASE_DIR=${RELEASE_DIR:-$root/release}
readonly RELEASE_DATE=${RELEASE_DATE:-$(TZ=UTC date +"%Y-%m-%dT%H:%M:%SZ")}

main() {
        cd $root

        show_vars
        create_kctrl_package
        populate_release_dir
}

show_vars() {
        echo "
        BUNDLE                  $BUNDLE
        RELEASE_DATE            $RELEASE_DATE
        RELEASE_DIR             $RELEASE_DIR
        RELEASE_VERSION         $RELEASE_VERSION
        SCRATCH                 $SCRATCH
        "
}

create_kctrl_package() {
        mkdir -p $SCRATCH/package/carvel
        cp -r ./carvel/{objects,overlays,upstream} $SCRATCH/package/carvel
        ls $SCRATCH

        registry_host=$(echo $BUNDLE | cut -d'/' -f1)
        registry_project=$(echo $BUNDLE | cut -d'/' -f2 | cut -d':' -f1)
        tag=$(echo $BUNDLE | cut -d':' -f2)

        echo "registry_host: $registry_host"
        echo "registry_project: $registry_project"
        echo "tag: $tag"
        echo "*** registry_repo is locked to package-for-cartographer ***"

        ytt --ignore-unknown-comments \
                -f ./build-templates/package-build.yml \
                -f ./build-templates/values-schema.yaml \
                --data-value build.registry_host=$registry_host \
                --data-value build.registry_project=$registry_project >\
                $SCRATCH/package/package-build.yml

        ytt --ignore-unknown-comments \
                -f ./build-templates/package-resources.yml \
                -f ./build-templates/values-schema.yaml \
                --data-value build.registry_host=$registry_host \
                --data-value build.registry_project=$registry_project >\
                $SCRATCH/package/package-resources.yml

        ytt --ignore-unknown-comments \
                -f ./build-templates/kbld-config.yaml \
                -f ./build-templates/values-schema.yaml \
                --data-value build.registry_host=$registry_host \
                --data-value build.registry_project=$registry_project >\
                $SCRATCH/package/kbld-config.yaml

        kctrl package release \
                --chdir $SCRATCH/package \
                -t $tag \
                -v $RELEASE_VERSION \
                -y \
                --copy-to $SCRATCH/bundle.tar
}

populate_release_dir() {
        mkdir -p $RELEASE_DIR
        cp -r $SCRATCH/package/* $RELEASE_DIR
        cp -r $SCRATCH/bundle.tar $RELEASE_DIR

        ls $RELEASE_DIR
}

_image_from_lockfile() {
        local lockfile=$1

        awk -F"image: " '{if ($2) print $2;}' $lockfile
}

main "$@"
