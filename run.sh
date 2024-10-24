#!/bin/bash

registry=crbundleexecqawestus

# az acr login -n crbundleexecqawestus

# output=$(az acr run --registry $registry --cmd '$Registry/hello:v5' /dev/null 2>&1) # 3 seconds

# output=$(cat bash-echo.yaml | az acr run --registry $registry  -f - /dev/null 2>&1) 
output=$(cat bash-echo-3.yaml | az acr run --registry $registry  -f - /dev/null 2>&1) 

input=$(echo $output | grep Queued)
id=$(echo "$input" | sed 's/.*ID: \([^ ]*\).*/\1/')

echo "Logs..."
az acr task logs --registry $registry --run-id $id

