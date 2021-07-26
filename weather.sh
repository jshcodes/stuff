#!/bin/bash
curl wttr.in/$(curl ipinfo.io | jq -r .city)
