#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates.
#

set -euo pipefail

main() {
    local service="${1:-cft}"
    
    echo "Starting tests for service: $service"
    
    ./test.sh "$service" wait-startup 30
    
    ./test.sh "$service" smoke-tests

    ./test.sh "$service" test-run-transfer

    echo "All tests completed successfully"
    return 0
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
