#!/bin/bash


# DEBUG: cli.azure.cli.core.sdk.policies: Request URL: 'https://centraluseuap.management.azure.com/subscriptions/a38e7552-bad2-4006-8c5c-83b0df1d835f/resourceGroups/rg-ksacrtask/providers/Microsoft.ContainerRegistry/registries/crksacrtask/runs/cfe/listLogSasUrl?api-version=2019-06-01-preview'

# Variables
storage_account="wusmanaged243"
blob_url="https://$storage_account.blob.core.windows.net/2723160017d64d77874c4cec45ac0784-ozm8223uou/logs/cff/rawtext.log"
sas_token="sv=2023-01-03&se=2024-10-24T17%3A17%3A29Z&sr=b&sp=r&sig=HRF8l8HWqsH1xVSzO8NfPAMtdUyRPOMbDqJzUuxMQA0%3D"
url="$blob_url?$sas_token"
chunk_size=2024  # Size of each chunk in bytes
start_byte=0
end_byte=$((chunk_size - 1))

# Function to download a chunk
download_chunk() {
  local start=$1
  local end=$2
  az rest --method get --url "$url" --headers "{\"x-ms-range\": \"bytes=$start-$end\"}" --verbose 2>&1
}

# Get the total size of the blob
response=$(download_chunk 0 0)
# -e ensures new lines preserved
content_range=$(echo -e "$response" | grep -i 'Content-Range' | awk '{print $4}' | sed "s/'//g")
# echo -e content_range: $content_range
total_size=$(echo "$content_range" | cut -d'/' -f2)
echo total_size: $total_size

# Loop to download the blob in chunks
while true; do
  end_byte=$((start_byte + chunk_size - 1))
   if [ "$end_byte" -ge "$total_size" ]; then
    end_byte=$total_size
  fi
  response=$(download_chunk $start_byte $end_byte)
  
  # Extract headers from the response
  content_length=$(echo -e "$response" | grep -i 'Content-Length' | awk '{print $3}' | sed "s/'//g")
  content_range=$(echo -e "$response" | grep -i 'Content-Range' | awk '{print $4}' | sed "s/'//g")
  
  echo "Content-Length: $content_length"
  echo "Content-Range: $content_range"

  # Break the loop if no more content is available
  if [ -z "$content_length" ] || [ "$content_length" -eq 0 ]; then
    break
  fi
  
  # Print the chunk content
  echo "$response" | grep -A 1000 'Response content:' | tail -n +2
  
  # Update the byte range for the next chunk
  start_byte=$((start_byte + chunk_size))
   if [ "$start_byte" -ge "$total_size" ]; then
    start_byte=$total_size
  fi
  # end_byte=$((start_byte + chunk_size - 1))
  
  echo "Start Byte: $start_byte"
  echo "End Byte: $end_byte"

   # Exit if start_byte equals end_byte
  if [ "$start_byte" -eq "$end_byte" ]; then
    echo "Start Byte equals End Byte. Exiting."
    break
  fi
  
  # Check if we have reached the end of the content
  if [[ "$content_range" == */* ]]; then
    total_size=$(echo "$content_range" | cut -d'/' -f2)
    if [[ "$content_range" == "*/$total_size" ]]; then
      echo "Reached the end of the file."
      break
    fi
  fi


done