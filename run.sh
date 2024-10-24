#!/bin/bash

# Got this from msi-run.log, and works
# TODO: See how the blog name isues guid and a suffix. This is what I have talked about as security measure in the past
# az rest --method get --url "https://wusmanaged243.blob.core.windows.net/2723160017d64d77874c4cec45ac0784-ozm8223uou/logs/cfe/rawtext.log?sv=2023-01-03&se=2024-10-24T16%3A05%3A23Z&sr=b&sp=r&sig=qNHhqORLlyM8uNHThj4yI9RJTI%2B9ZLet2Z7X5iT7xps%3D"

registry=crbundleexecqawestus

# az acr login -n crbundleexecqawestus

# output=$(az acr run --registry $registry --cmd '$Registry/hello:v5' /dev/null 2>&1) # 3 seconds

# output=$(cat bash-echo.yaml | az acr run --registry $registry  -f - /dev/null 2>&1) 
# output=$(cat bash-echo-3.yaml | az acr run --registry $registry  -f - /dev/null 2>&1) 
output=$(cat build-hello-world.yaml | az acr run --registry $registry  -f - /dev/null 2>&1) 

input=$(echo $output | grep Queued)
id=$(echo "$input" | sed 's/.*ID: \([^ ]*\).*/\1/')

echo "Logs..."
az acr task logs --registry $registry --run-id $id

