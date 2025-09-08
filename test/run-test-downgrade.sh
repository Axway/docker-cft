#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates.
#

set -euo pipefail

main() {
    local service="${1:-cft}"
    
    echo "Starting downgrade tests for service: $service"

    ./test.sh "$service" wait-startup 30

    ./test.sh "$service" smoke-tests

    ./test.sh "$service" test-check-transfer

    ./test.sh "$service" test-check-data

    ./test.sh "$service" export-database

    # Check readiness with expected 503 HTTP code
    ./test.sh "$service" check-readiness 503 debug

    ./test.sh "$service" check-liveness

    echo "Downgrade tests completed successfully"
    return 0
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
