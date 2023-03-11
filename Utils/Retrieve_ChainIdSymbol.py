import pandas as pd
import requests

# Retrieve the chains.json file
url = "https://chainid.network/chains.json"
response = requests.get(url)

# Load the JSON data into a pandas DataFrame
df = pd.read_json(response.content)

# Select only the columns for name, chainId, and nativeCurrency
df = df[["name", "chainId", "networkId", "nativeCurrency","rpc"]]

# Extract the symbol from the nativeCurrency object
df["symbol"] = df["nativeCurrency"].apply(lambda x: x["symbol"])

# Extract the first RPC endpoint from the rpc list, if it exists
df["rpcs"] = df["rpc"].apply(lambda x: x[0] if len(x) > 0 else None)

# Select only the columns for chain, chainId, symbol, and rpcs
df = df[["name", "chainId", "networkId", "symbol", "rpcs"]]

# Rename columns to match your expected format
df.columns = ["chain", "chainId", "networkId", "symbol", "rpc"]

# Print the resulting DataFrame
print(df)


# Save the DataFrame to a JSON file
df.to_json("./chains.json", orient="records")
