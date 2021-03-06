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

readonly root=$(cd "$(dirname $0)/.." && pwd)
readonly scratch=$(mktemp -d)
readonly release_body=$scratch/release-body.txt

main() {
        test $# -eq 0 && {
                echo "usage:     $0 <tag>"
                echo "example:   $0 v1.2.3"
                exit 1
        }

        cd $root
        craft_release_body
        push $1
}

craft_release_body() {
        local checksums_file=$(mktemp)

        pushd release
        sha256sum * >$checksums_file
        popd

        cat <<-EOF >$release_body
	<p>sha256sum</p>
	<pre>
	$(cat $checksums_file)
	</pre>
	EOF
}

push() {
        local version=$1

        gh release create $version \
                --draft \
                --prerelease \
                --title $version \
                --notes-file $release_body \
                ./release/bundle.tar \
                ./release/package-install.yaml \
                ./release/package-metadata.yaml \
                ./release/package.yaml \
                ./README.md
}

main "$@"
