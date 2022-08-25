# 4 types of tokens

## standart tokens

*  Normal ERC20

## Liquidity Generator Token (https://testnet.bscscan.com/address/0xe15c39f985bfb25c023af3762cd01717090b5290)

* Transaction fee to generate yield (%): The % amount of tokens from every transaction that are distributed to all token holders.
* Transaction fee to generate liquidity (%): The % amount of tokens from every transaction that are distributed to the liquidity pool.
* Max transaction percent (%): Any transactions that trades more than this percentage of the total supply will be rejected.
* Charity percent (%): The % amount of tokens from every transaction are distributed to a charity address.
* Charity address: All charity tokens from “Charity percent (%)” will be distributed to this address.

## Baby Token (reward - wrapped bnb -- 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd) (https://testnet.bscscan.com/address/0x329f3a745b35630b0c1e6a707c87517b5151146b)

* Reward token: The contract address of the token that you want to use to reward your users. For example, you are creating a BabyDogeXXX token on the Binance Smart Chain and you want to reward your users with DOGE, enter 0xba2ae424d960c26247dd6c32edc70b295c744c43 (Binance-Peg Dogecoin contract address).
* Minimum token balance for dividends: In order to receive rewards, each wallet must hold at least this amount of tokens. Its value must be of more than $50. (Minimum token balance for dividends must be less than or equal 0.1% total supply)
* Token reward fee (%): The % amount of tokens from every transaction that is distributed to all token holders. If you choose DOGE as reward token, your users will be rewarded in DOGE instead of the base token. When the amount of tokens is greater than 0.002% of the total supply, reward fee will be automatically swapped to the reward token.
* Router: Select PancakeSwap for the Binance Smart Chain; select UniSwap, SushiSwap or ShibaSwap for the Etherum Network; select QuickSwap for the Matic Chain; select KuSwap for the Kucoin Chain.
* Auto add liquidity (%): The % amount of tokens from every transaction that is automatically sent to the liquidity pool.
* Marketing fee (%): The % amount of tokens from every transaction that is sent to the marketing address. If you choose DOGE as the reward token, the marketing wallet will receive DOGE instead of the base token.
* Marketing wallet: Tokens from the “Marketing fee (%)” section will be sent to this address.

## Buyback Baby Token (https://testnet.bscscan.com/address/0x95a9a96c11976a5e3b471da3f5b00cf0019aff56)

* Router: Select PancakeSwap for the Binance Smart Chain; select UniSwap, SushiSwap or ShibaSwap for the Etherum Network; select QuickSwap for the Matic Chain; select KuSwap for the Kucoin Chain; select TradeJoe or Pangolin for AVAX.
* Reward token: The contract address of the token that you want to use to reward your users. For example, you are creating a BuybackBabyDogeXXX token on the Binance Smart Chain and you want to reward your users with DOGE, enter DOGE token address in this field (Binance-Peg Dogecoin contract address).
* Liquidity Fee(%): The % amount of tokens from every transaction that is automatically sent to the liquidity pool.
* Buyback Fee (%): The % amount of BNB from every transaction that is used to buy back tokens. It will generate a contract address to store BNB. You need to call buy back function to start buying back tokens.
* Reflection Fee (%): The % amount of tokens from every transaction that is distributed to all token holders. If you choose DOGE as a reward token, your users will be rewarded in DOGE instead of the base token.
* Marketing Fee (%): The % amount of BNB from every transaction that is sent to the owner wallet.
