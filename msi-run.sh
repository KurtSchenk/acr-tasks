
#!/bin/bash

rg=rg-ksacrtask
location=westus
registry=crksacrtask # crbundleexecqawestus
kv="kvksacrtask"
secret_name="secret"
secret_value="value02"
repo_url="https://github.com/KurtSchenk/acr-tasks.git"
branch="ks-experiment"
repo_url="$repo_url#$branch" 

user_principal_name=$(az ad signed-in-user show --query userPrincipalName -o tsv)


create_resource_group() {
    az group create -n $rg -l $location
}

create_acr() {
    az acr create -n $registry -g $rg --sku Basic
}

create_key_vault() {
    # Check if the Key Vault exists
    if ! az keyvault show -n $kv &> /dev/null; then
    echo "Creating Key Vault $kv..."
    az keyvault create -n $kv -g $rg -l $location
    else
    echo "Key Vault $kv already exists."
fi
}

create_umi_get_ids()
{
    output=$(az identity create -g $rg -n msi_user_identity)
    principal_id=$(echo $output | jq -r '.principalId')
    id=$(echo $output | jq -r '.id')
}

assign_roles_key_vault()
{
    az role assignment create --role "Key Vault Secrets Officer" --assignee $user_principal_name --scope $(az keyvault show -n $kv --query id -o tsv)
    az role assignment create --role reader --assignee $principal_id --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rg
    az role assignment create --role "Key Vault Secrets User" --assignee $principal_id --scope $(az keyvault show -n $kv --query id -o tsv)
}

create_acr_task()
{
    az acr task create -n msitask -r $registry -c $repo_url \
    -f managed-identities.yaml --pull-request-trigger-enabled false --commit-trigger-enabled false \
    --assign-identity $id
}

# create_resource_group
# create_acr
# az acr login -n $registry
# create_key_vault
# create_umi_get_ids
# assign_roles_key_vault
# create_acr_task
# az keyvault secret set --vault-name $kv -n $secret_name --value $secret_value
az acr task run -n msitask -r $registry --set registryName=$registry
# az acr task logs --registry $registry -n msitask

exit


  # output=$(az acr run --registry $registry --cmd '$Registry/hello:v5' /dev/null 2>&1) # 3 seconds

# output=$(cat bash-echo.yaml | az acr run --registry $registry  -f - /dev/null 2>&1) 
output=$(cat bash-echo-3.yaml | az acr run --registry $registry  -f - /dev/null 2>&1) 

input=$(echo $output | grep Queued)
id=$(echo "$input" | sed 's/.*ID: \([^ ]*\).*/\1/')

echo "Logs..."
az acr task logs --registry $registry --run-id $id
