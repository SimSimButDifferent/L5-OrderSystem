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
    })
    describe("confirmOrder", function () {
        it("Should confirm an order", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await orderSystem.confirmOrder(orderId)
            const order = await orderSystem.getOrder(orderId)
            expect(order.state).to.equal(1) // OrderState.Confirmed
        })
    })

    describe("deliverOrder", function () {
        it("Should deliver an order", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            await orderSystem.confirmOrder(orderId)
            await orderSystem.deliverOrder(orderId)
            const order = await orderSystem.getOrder(orderId)
            expect(order.state).to.equal(2) // OrderState.Delivered
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
    })
})
