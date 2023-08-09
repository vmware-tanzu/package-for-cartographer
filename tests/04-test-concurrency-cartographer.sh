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

        test_no_concurrency_set
        test_concurrency_set
}

# validate that concurrency defaults get picked up
test_no_concurrency_set() {
        local actual
        local expected=$(mktemp)

        cat >$expected <<-EOM
args:
- -cert-dir=/cert
- -metrics-port=9998
- -max-concurrent-deliveries=2
- -max-concurrent-workloads=2
- -max-concurrent-runnables=2
EOM

        actual=$(_apply_ytt)
        _assert_files_equal $expected $actual
}

# validate that we can tweak concurrency
#
test_concurrency_set() {
        local actual
        local expected=$(mktemp)

        cat >$expected <<-EOM
args:
- -cert-dir=/cert
- -metrics-port=9998
- -max-concurrent-deliveries=31
- -max-concurrent-workloads=41
- -max-concurrent-runnables=43
EOM

        actual=$(
                _apply_ytt \
                        --data-value-yaml "cartographer.concurrency.max_deliveries=31" \
                        --data-value-yaml "cartographer.concurrency.max_workloads=41" \
                        --data-value-yaml "cartographer.concurrency.max_runnables=43"
        )
        _assert_files_equal $expected $actual
}

_apply_ytt() {
        local args=$@
        local res_fpath=$(mktemp)

        ytt -f ./carvel/ --ignore-unknown-comments $args |
                kapp tools inspect -f- \
                        --filter-kind-name=Deployment/cartographer-controller \
                        --raw |
                grep args -A 5 |
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

main "$@"
