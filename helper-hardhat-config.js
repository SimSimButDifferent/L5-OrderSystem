const hre = require("hardhat")
const { ethers } = require("hardhat")

const networkConfig = {
    31377: {
        name: "localhost",
    },
    11155111: {
        name: "sepolia",
    },
}

const developmentChains = ["hardhat", "localhost"]

module.exports = { networkConfig, developmentChains }
