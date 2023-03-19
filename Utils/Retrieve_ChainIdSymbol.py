import pandas as pd
import requests

# Retrieve the chains.json file
url = "https://chainid.network/chains.json"
response = requests.get(url)

# Load the JSON data into a pandas DataFrame
df = pd.read_json(response.content)

# Select only the columns for name, chainId, and nativeCurrency
df = df[["name", "chainId", "networkId", "nativeCurrency","rpc", "explorers"]]



# Extract the symbol from the nativeCurrency object
df["symbol"] = df["nativeCurrency"].apply(lambda x: x["symbol"])

df["explorer_url"] = df["explorers"].apply(lambda x: x[0]["url"] if isinstance(x, list) and len(x) > 0 else None)


# Extract the first RPC endpoint from the rpc list, if it exists
# df["rpcs"] = df["rpc"].apply(lambda x: x[0] if len(x) > 0 else None)
# dont take infura if there are many rpcs
df["rpcs"] = df["rpc"].apply(lambda x: [r for r in x if "infura" not in r][0] if len(x) > 1 and any("infura" not in r for r in x) else x[0] if len(x) > 0 else None)


# Select only the columns for chain, chainId, symbol, and rpcs
df = df[["name", "chainId", "networkId", "symbol", "rpcs","explorer_url"]]

# Rename columns to match your expected format
df.columns = ["chain", "chainId", "networkId", "symbol", "rpc","explorer_url"]

# Print the resulting DataFrame
print(df)


# Save the DataFrame to a JSON file
df.to_json("./chains.json", orient="records")
