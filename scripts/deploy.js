const hre = require("hardhat")
const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")

async function main() {
    if (developmentChains.includes(network.name)) {
        const OrderSystem = await hre.ethers.getContractFactory("OrderSystem")

        console.log("Deploying...")

        const orderSystem = await OrderSystem.deploy()
        console.log(`OrderSystem deployed to: ${orderSystem.target}`)
    }

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        const OrderSystem = await hre.ethers.getContractFactory("OrderSystem")

        console.log("Deploying...")

        const orderSystem = await OrderSystem.deploy()
        console.log(`OrderSystem deployed to: ${orderSystem.target}`)

        const desiredConfirmations = 6
        const receipt = await orderSystem
            .deploymentTransaction()
            .wait(desiredConfirmations)

        console.log(
            `Transaction confirmed. Block number: ${receipt.blockNumber}`,
        )
        await hre.run("verify:etherscan", { address: orderSystem.target })
        console.log("OrderSystem verified!")
        console.log("--------------------------------------------------")
    }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
