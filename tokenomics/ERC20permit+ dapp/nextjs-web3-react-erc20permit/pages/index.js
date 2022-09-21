import Head from "next/head";
import Image from "next/image";
import styles from "../styles/Home.module.css";
import { useWeb3React } from "@web3-react/core";
import { InjectedConnector } from "@web3-react/injected-connector";

import { abiToken } from "../constants/abi-token";
import { abiVault } from "../constants/abi-vault";

import { useState, useEffect } from "react";
import { ethers } from "ethers";

export const injected = new InjectedConnector();

export default function Home() {
  const [hasMetamask, setHasMetamask] = useState(false);

  useEffect(() => {
    if (typeof window.ethereum !== "undefined") {
      setHasMetamask(true);
    }
  });

  const {
    active,
    activate,
    chainId,
    account,
    library: provider,
  } = useWeb3React();

  async function connect() {
    if (typeof window.ethereum !== "undefined") {
      try {
        await activate(injected);
        setHasMetamask(true);
      } catch (e) {
        console.log(e);
      }
    }
  }

  async function getPermitSignature(signer, token, spender, value, deadline) {
    const [nonce, name, version, chainId] = await Promise.all([
      token.nonces(signer.getAddress()),
      token.name(),
      "1",
      signer.getChainId(),
    ]);

    return ethers.utils.splitSignature(
      await signer._signTypedData(
        {
          name,
          version,
          chainId,
          verifyingContract: token.address,
        },
        {
          Permit: [
            {
              name: "owner",
              type: "address",
            },
            {
              name: "spender",
              type: "address",
            },
            {
              name: "value",
              type: "uint256",
            },
            {
              name: "nonce",
              type: "uint256",
            },
            {
              name: "deadline",
              type: "uint256",
            },
          ],
        },
        {
          owner: account,
          spender,
          value,
          nonce,
          deadline,
        }
      )
    );
  }

  async function execute() {
    if (active) {
      const signer = provider.getSigner();
      //token contract on rinkeby
      const contractAddress = "0xD9dc2Eaf2e2BA2d88aCB873a9DA873D4f7b4c15d";
      const token = new ethers.Contract(contractAddress, abiToken, signer);
      //vault contract on rinkeby
      const VaultAddress = "0xcB5BfF6Deb5fF32E9aBA8eC0a3d5d6637261740C";
      const vault = new ethers.Contract(VaultAddress, abiVault, signer);

      try {
        const amount = 1000;
        const deadline = ethers.constants.MaxUint256;

        const { v, r, s } = await getPermitSignature(
          signer,
          token,
          VaultAddress,
          amount,
          deadline
        );

        await vault.depositWithPermit(amount, deadline, v, r, s);
      } catch (error) {
        console.log(error);
      }
    }
  }

  return (
    <div>
      {hasMetamask ? (
        active ? (
          "Connected! "
        ) : (
          <button onClick={() => connect()}>Connect</button>
        )
      ) : (
        "Please install metamask"
      )}

      {active ? <button onClick={() => execute()}>Execute</button> : ""}
    </div>
  );
}
