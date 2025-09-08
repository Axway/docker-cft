#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates.
#

set -euo pipefail

main() {
    local service="cft"
    
    echo "Starting hook pre-upgrade tests for service: $service"

    ./test.sh "$service" wait-startup 30

    ./test.sh "$service" smoke-tests

    ./test.sh "$service" test-run-transfer

    ./test.sh "$service" test-check-transfer

    ./test.sh "$service" test-create-data

    echo "Hook pre-upgrade tests completed successfully"
    return 0
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
