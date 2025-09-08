#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates.
#

set -euo pipefail

main() {
    local service="${1:-cft}"
    local export_flag="${2:-}"
    local doexport=true
    
    if [[ "$export_flag" == "noexport" ]]; then
        doexport=false
    fi
    
    echo "Starting upgrade tests for service: $service (export: $doexport)"
    
    /test.sh "$service" wait-startup 30

    ./test.sh "$service" smoke-tests

    ./test.sh "$service" test-check-transfer

    ./test.sh "$service" test-check-data

    if [[ "$doexport" == true ]]; then
        ./test.sh "$service" export-database
        
        # Check readiness with expected 503 status
        ./test.sh "$service" check-readiness 503
    fi
    
    ./test.sh "$service" check-liveness

    echo "Upgrade tests completed successfully"
    return 0
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
