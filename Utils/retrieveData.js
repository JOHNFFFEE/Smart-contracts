const { ethers } = require("ethers");
const createCsvWriter = require("csv-writer").createArrayCsvWriter;

const contractaddress = require("./constants/address.json");

const abi = require("./constants/abi.json");

//Mainnet rpc
const provider = new ethers.providers.JsonRpcProvider(
  "https://eth.llamarpc.com"
);
const contract = new ethers.Contract(contractaddress, abi, provider);

/*File to loop over a smart contract and retrieve and put to excel a list of
* tokenId, address holder, token URI.
*/

async function main() {
  const totalSupply = await contract.totalSupply();
  const tokenData = [];

  function cleaning(url) {
    const cleanedUrl = url
      .replace("www.https....", "")
      .replace(".json", "");
    return cleanedUrl;
  }

  for (let i = 1; i <= totalSupply; i++) {
    console.log(i);
    const tokenId = i;
    const tokenUri = await contract.tokenURI(tokenId);
    const owner = await contract.ownerOf(tokenId);
    cleanedUrl = cleaning(tokenUri);

    tokenData.push([tokenId.toString(), owner, cleanedUrl]);
  }

  console.log(tokenData);

    const csvWriter = createCsvWriter({
      header: ["Token ID", "Owner Address", "Token URI"],
      path: "nft-data.csv",
    });

    await csvWriter.writeRecords(tokenData);

    console.log("NFT data written to nft-data.csv");
}

main();
