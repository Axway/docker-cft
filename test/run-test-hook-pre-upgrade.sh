#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#

service="cft"

./test.sh $service wait-startup 30
if [ $? -ne 0 ]; then
  exit 1;
fi

./test.sh $service smoke-tests
if [ $? -ne 0 ]; then
  exit 1;
fi

./test.sh $service test-run-transfer
if [ $? -ne 0 ]; then
  exit 1;
fi

./test.sh $service test-create-data
if [ $? -ne 0 ]; then
  exit 1;
fi

exit 0
