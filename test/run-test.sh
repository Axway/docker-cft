#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2022 Axway Software SA and its affiliates. All rights reserved.
#

./test.sh cft wait-startup 30
if [ $? -ne 0 ]; then
  exit 1;
fi

./test.sh cft smoke-tests
if [ $? -ne 0 ]; then
  exit 1;
fi

exit 0
