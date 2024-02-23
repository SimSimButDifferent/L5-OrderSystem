const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("OrderSystem", function () {
    let OrderSystem, orderSystem, owner, addr1
    const orderId = 0
    const orderAmount = 100

    beforeEach(async function () {
        OrderSystem = await ethers.getContractFactory("OrderSystem")
        ;[owner, addr1] = await ethers.getSigners()
        orderSystem = await OrderSystem.deploy()
    })

    describe("createOrder", function () {
        it("Should create an order", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            const order = await orderSystem.getOrder(orderId)
            expect(order.id).to.equal(orderId)
            expect(order.customer).to.equal(owner.address)
            expect(order.amount).to.equal(orderAmount)
            expect(order.state).to.equal(0) // OrderState.Created
        })

        it("Should emit an OrderCreated event", async function () {
            await expect(orderSystem.createOrder(owner.address, orderAmount))
                .to.emit(orderSystem, "OrderCreated")
                .withArgs(orderId, owner.address, orderAmount)
        })
    })
    describe("confirmOrder", function () {
        it("Should confirm an order", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await orderSystem.confirmOrder(orderId)
            const order = await orderSystem.getOrder(orderId)
            expect(order.state).to.equal(1) // OrderState.Confirmed
        })

        it("Should emit an OrderConfirmed event", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await expect(orderSystem.confirmOrder(orderId))
                .to.emit(orderSystem, "OrderConfirmed")
                .withArgs(orderId, owner.address)
        })

        it("Only the order customer can confirm an order", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await expect(
                orderSystem.connect(addr1).confirmOrder(orderId),
            ).to.be.revertedWith("Only customer can confirm order")
        })
    })

    describe("confirmDelivery", function () {
        it("User can confirm delivery of an order", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await orderSystem.confirmOrder(orderId)
            await orderSystem.confirmDelivery(orderId)
            const order = await orderSystem.getOrder(orderId)
            expect(order.state).to.equal(2) // OrderState.Delivered
        })

        it("Should emit an OrderDelivered event", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await orderSystem.confirmOrder(orderId)
            await expect(orderSystem.confirmDelivery(orderId))
                .to.emit(orderSystem, "OrderDelivered")
                .withArgs(orderId, owner.address)
        })

        it("Only the order customer can confirm delivery", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await orderSystem.confirmOrder(orderId)
            await expect(
                orderSystem.connect(addr1).confirmDelivery(orderId),
            ).to.be.revertedWith("Only customer can confirm delivery")
        })

        it("User cannot confirm delivery of an order that is not confirmed", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await expect(
                orderSystem.confirmDelivery(orderId),
            ).to.be.revertedWith("Order not confirmed")
        })

        it("User cannot confirm delivery of an order that is already delivered", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await orderSystem.confirmOrder(orderId)
            await orderSystem.confirmDelivery(orderId)

            await expect(
                orderSystem.confirmDelivery(orderId),
            ).to.be.revertedWith("Order already delivered")
        })
    })
    describe("setProfile", function () {
        it("Should set and get a user profile", async function () {
            const name = "Alice"
            const age = "25"
            await orderSystem.connect(owner).setProfile(name, age)
            const [profileName, profileAge] = await orderSystem.getProfile(
                owner.address,
            )
            expect(profileName).to.equal(name)
            expect(profileAge).to.equal(age)
        })

        it("Should emit a ProfileCreated event", async function () {
            const name = "Alice"
            const age = "25"
            await expect(orderSystem.connect(owner).setProfile(name, age))
                .to.emit(orderSystem, "ProfileCreated")
                .withArgs(owner.address, name, age)
        })

        it("Should revert if name is empty", async function () {
            const name = ""
            const age = "25"
            await expect(
                orderSystem.connect(owner).setProfile(name, age),
            ).to.be.revertedWith("Name cannot be empty")
        })

        it("Should revert if age is empty", async function () {
            const name = "Alice"
            const age = ""
            await expect(
                orderSystem.connect(owner).setProfile(name, age),
            ).to.be.revertedWith("Age cannot be empty")
        })
    })
})
