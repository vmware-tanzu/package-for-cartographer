#!/usr/bin/env bash
#
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

main() {
        cd $root

        test_no_resources_set
        test_only_limit_memory_set
        test_requests_set
        test_requests_set_with_component_excluded
}

# validate that we're able to make use of the
# defaults as defined in the cartographer upstream
# configuration.
#
test_no_resources_set() {
        local actual
        local expected=$(mktemp)

        cat >$expected <<-EOM
resources:
  limits:
    cpu: 1
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
EOM

        actual=$(_apply_ytt)
        _assert_files_equal $expected $actual
}

# validate that by specifying just a single field
# out of the nested structure we're able to modify
# solely that particular field.
#
test_only_limit_memory_set() {
        local actual
        local expected=$(mktemp)

        cat >$expected <<-EOM
resources:
  limits:
    cpu: 1
    memory: 99Gi
  requests:
    cpu: 500m
    memory: 512Mi
EOM

        actual=$(
                _apply_ytt \
                        --data-value-yaml "cartographer.resources.limits.memory=99Gi"
        )
        _assert_files_equal $expected $actual
}

# validate that we can tweak a whole block
# (`resources.requests` in this case).
#
test_requests_set() {
        local actual
        local expected=$(mktemp)

        cat >$expected <<-EOM
resources:
  limits:
    cpu: 1
    memory: 1Gi
  requests:
    cpu: 99
    memory: 99Gi
EOM

        actual=$(
                _apply_ytt \
                        --data-value-yaml "cartographer.resources.requests.cpu=99" \
                        --data-value-yaml "cartographer.resources.requests.memory=99Gi"
        )
        _assert_files_equal $expected $actual
}

# validate that despite a component being excluded
# the matching still works as expected.
#
test_requests_set_with_component_excluded() {
        local actual

        actual=$(
                _apply_ytt \
                        --data-value-yaml "cartographer.resources.limits.memory=99Gi" \
                        --data-value-yaml "excluded_components=['cartographer']"
        )

        _assert_file_empty $actual
}

_apply_ytt() {
        local args=$@
        local res_fpath=$(mktemp)

        ytt -f ./carvel/ --ignore-unknown-comments $args |
                kapp tools inspect -f- \
                        --filter-kind-name=Deployment/cartographer-controller \
                        --raw |
                grep resources -A 6 |
                cut -c 9- >$res_fpath
        echo $res_fpath
}

_assert_files_equal() {
        local expected=$1
        local actual=$2

        local res=$(git diff --no-index $expected $actual)
        if [[ ! -z $res ]]; then
                echo "mismatch: $res"
                exit 1
        fi
}

_assert_file_empty() {
        local fpath=$1

        if [[ -s $fpath ]]; then
                echo "expected file $fpath to be empty but wasn't"
                exit 1
        fi
}

main "$@"
