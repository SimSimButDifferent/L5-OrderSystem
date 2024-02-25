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
        const name = "Alice"
        const age = "25"
        await orderSystem.connect(owner).newUserProfile(name, age)
    })

    describe("newUserProfile", function () {
        it("Should set and get a user profile", async function () {
            const name = "Alice"
            const age = "25"
            await orderSystem.connect(owner).newUserProfile(name, age)
            const [profileName, profileAge] = await orderSystem.getProfile(
                owner.address,
            )
            expect(profileName).to.equal(name)
            expect(profileAge).to.equal(age)
        })

        it("Should emit a ProfileCreated event", async function () {
            const name = "Alice"
            const age = "25"
            await expect(orderSystem.connect(owner).newUserProfile(name, age))
                .to.emit(orderSystem, "ProfileCreated")
                .withArgs(owner.address, name, age)
        })

        it("Should revert if name is empty", async function () {
            const name = ""
            const age = "25"
            await expect(
                orderSystem.connect(owner).newUserProfile(name, age),
            ).to.be.revertedWith("Name cannot be empty")
        })

        it("Should revert if age is empty", async function () {
            const name = "Alice"
            const age = ""
            await expect(
                orderSystem.connect(owner).newUserProfile(name, age),
            ).to.be.revertedWith("Age cannot be empty")
        })
    })

    describe("createOrder", function () {
        it("Should revert if User is not registered", async function () {
            await expect(
                orderSystem.createOrder(addr1.address, orderAmount),
            ).to.be.revertedWith("User profile does not exist")
        })
        it("Should create an order", async function () {
            await orderSystem.createOrder(owner.address, orderAmount)
            const order = await orderSystem.getOrder(orderId)
            expect(order.id).to.equal(orderId)
            expect(order.customer).to.equal(owner.address)
            expect(order.amount).to.equal(orderAmount)
            expect(order.state).to.equal(0) // OrderState.Created
        })

        it("Should revert if order amount is 0", async function () {
            await expect(
                orderSystem.createOrder(owner.address, 0),
            ).to.be.revertedWith("Amount should be greater than 0")
        })

        it("Should allow multiple orders", async function () {
            const order1 = await orderSystem.createOrder(
                owner.address,
                orderAmount,
            )
            const order2 = await orderSystem.createOrder(
                owner.address,
                orderAmount,
            )
            const order = await orderSystem.getOrder(orderId + 1)
            expect(order.id).to.equal(orderId + 1)
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

    describe("adminDeleteProfileAndOrders", function () {
        it("Should delete a user profile and orders", async function () {
            const name = "Bob"
            const age = "30"
            await orderSystem.connect(addr1).newUserProfile(name, age)
            await orderSystem.createOrder(addr1.address, orderAmount)
            await orderSystem.connect(addr1).confirmOrder(orderId)
            await orderSystem.adminDeleteProfileAndOrders(addr1.address)
            await expect(
                orderSystem.getProfile(addr1.address),
            ).to.be.revertedWith("Profile does not exist for the given address")
        })

        describe("deleteProfile", function () {
            it("Should delete a user profile", async function () {
                await orderSystem.deleteProfile()
            })
            it("Should emit a ProfileDeleted event", async function () {
                await expect(orderSystem.deleteProfile())
                    .to.emit(orderSystem, "ProfileDeleted")
                    .withArgs(owner.address)
            })

            it("Should revert if user has pending orders", async function () {
                await orderSystem.createOrder(owner.address, orderAmount)
                await expect(orderSystem.deleteProfile()).to.be.revertedWith(
                    "Cannot delete profile with active orders",
                )
            })
        })

        describe("cancelOrder", function () {
            it("User can cancel an order", async function () {
                await orderSystem.createOrder(owner.address, orderAmount)
                await orderSystem.confirmOrder(orderId)
                await orderSystem.cancelOrder(orderId)
                const order = await orderSystem.getOrder(orderId)
                expect(order.state).to.equal(3) // OrderState.Cancelled
            })

            it("Should emit an OrderCancelled event", async function () {
                await orderSystem.createOrder(owner.address, orderAmount)
                await orderSystem.confirmOrder(orderId)
                await expect(orderSystem.cancelOrder(orderId))
                    .to.emit(orderSystem, "OrderCancelled")
                    .withArgs(orderId, owner.address)
            })

            it("Only the order customer can cancel an order", async function () {
                await orderSystem.createOrder(owner.address, orderAmount)
                await expect(
                    orderSystem.connect(addr1).cancelOrder(orderId),
                ).to.be.revertedWith("Only customer can cancel order")
            })

            it("User cannot cancel an order that is already delivered", async function () {
                await orderSystem.createOrder(owner.address, orderAmount)
                await orderSystem.confirmOrder(orderId)
                await orderSystem.confirmDelivery(orderId)
                await expect(
                    orderSystem.cancelOrder(orderId),
                ).to.be.revertedWith("Order already delivered")
            })

            it("User cannot cancel an order that is already cancelled", async function () {
                await orderSystem.createOrder(owner.address, orderAmount)
                await orderSystem.confirmOrder(orderId)
                await orderSystem.cancelOrder(orderId)
                await expect(
                    orderSystem.cancelOrder(orderId),
                ).to.be.revertedWith("Order already cancelled")
            })
        })

        describe("Getter functions", function () {
            beforeEach(async function () {
                await orderSystem.createOrder(owner.address, orderAmount)
                await orderSystem.confirmOrder(orderId)
            })

            describe("getOrder", function () {
                it("Should get an a users multiple orders", async function () {
                    await orderSystem.createOrder(owner.address, orderAmount)
                    const order = await orderSystem.getMyOrders()
                    const order1 = order[0]
                    const order2 = order[1]
                    expect(order1).to.equal(0)
                    expect(order2).to.equal(1)
                })
            })

            describe("getOrderState", function () {
                it("Should get the state of an order", async function () {
                    const state = await orderSystem.getOrderState(orderId)
                    expect(state).to.equal(1) // OrderState.Confirmed
                })
            })

            describe("getOrders", function () {
                it("Should get an order of a specific user", async function () {
                    const order = await orderSystem.getOrders(owner.address)
                    expect(order[0]).to.equal(orderId)
                })

                it("Should only allow owner to call getOrders", async function () {
                    await expect(
                        orderSystem.connect(addr1).getOrders(owner.address),
                    ).to.be.revertedWith("Only owner can call this function")
                })
            })
        })
    })
})
