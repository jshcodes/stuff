#!/bin/bash

if type aws >/dev/null 2>&1; then
  echo "This is AWS"
  curl -o aws_count.py https://raw.githubusercontent.com/jshcodes/stuff/main/aws-cspm-benchmark.py
  sudo pip3 install tabulate
  python3 aws_count.py
  rm aws_count.py
fi

if type az >/dev/null 2>&1; then
  echo "This is Azure"
  curl -o azure_count.py https://raw.githubusercontent.com/jshcodes/stuff/main/azure-cspm-benchmark.py
  python3 -m pip install azure-mgmt-resource azure-identity
  python3 azure_count.py
  rm azure_count.py
fi
