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

main() {
        cd $root/tests

        run_test
}

run_test() {
        local name=test-basic

        kapp deploy --yes -a $name -f ./01-test-basic.yaml
        trap "kapp delete -a $name --yes" EXIT

        for sleep_duration in {10..1}; do
                echo "sleeping ${sleep_duration}s"
                sleep $sleep_duration

                kubectl get configmap workload-$name && {
                        echo "succeeded!"
                        return 0
                }
        done

        echo "failed :("
        exit 1
}

main "$@"
