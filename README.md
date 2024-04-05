
# MYICO Crowdsale Project

Welcome to MYICO, a multifunctional crowdsale project built using Hardhat and Solidity. This project aims to provide an updated version of a crowdsale contract based on OpenZeppelin's crowdsale, with enhancements such as compatibility with Solidity version 0.8.20 and additional functionalities including whitelisting, refundable features, post-delivery options, timed crowdsale, cap limit, minting capabilities, and more.

## Features

- **Solidity 0.8.20 Compatibility**: The codebase has been updated to utilize the features of Solidity version 0.8.20.
- **Whitelisting**: Allows for whitelisting of addresses, ensuring only whitelisted participants can contribute to the crowdsale.
- **Refundable**: Implements refund functionality in case the crowdfunding goal is not met within the specified timeframe.
- **Post-Delivery**: Provides options for post-delivery of tokens after the successful conclusion of the crowdsale.
- **Timed Crowdsale**: Sets a specific timeframe for the crowdsale to run, ensuring it automatically ends at the defined time.
- **Cap Limit**: Enforces a cap limit on the total amount of funds that can be raised during the crowdsale.
- **Mintable Tokens**: Allows for the minting of tokens, providing flexibility in token distribution.
- **Additional Functionalities**: Other functionalities to enhance the crowdsale experience and adaptability.

## Usage

To utilize this project:

1. Clone the repository to your local machine.
2. Install dependencies using `yarn install`.
3. Configure your environment variables and settings as per your requirements.
4. Compile the contracts using `yarn hardhat compile`.
5. Test the contracts to ensure functionality using `yarn hardhat test`.
6. Deploy the contracts to your desired Ethereum network using `yarn hardhat deploy`.

```shell
yarn hardhat help
yarn hardhat test
REPORT_GAS=true yarn hardhat test
yarn hardhat node
yarn hardhat run scripts/deploy.js
yarn hardhat compile
yarn hardhat deploy
```

Ensure you have configured your environment variables, network settings, and other parameters correctly before deploying the contracts.

## Author

This project was authored by Muhammet Isik. You can find more of Muhammet's work on [GitHub](https://github.com/muhammet72).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Feel free to reach out for any inquiries or assistance. Happy Crowdfunding with MYICO! 🚀
