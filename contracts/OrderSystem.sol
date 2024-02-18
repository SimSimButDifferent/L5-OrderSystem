// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OrderSystem {
    enum OrderState {
        Created,
        Confirmed,
        Delivered
    }

    struct UserProfile {
        string name;
        string age;
        uint[] currentOrders;
        uint[] completedOrders;
    }

    struct Order {
        uint id;
        address customer;
        uint amount;
        OrderState state;
    }

    mapping(address => UserProfile) private profiles;

    mapping(uint => Order) private orders;

    uint private orderId = 0;

    function createOrder(
        address _customer,
        uint _amount
    ) public returns (uint) {
        uint currentOrderId = orderId;
        orderId++;
        UserProfile storage profile = profiles[_customer];
        profile.currentOrders.push(currentOrderId);
        orders[currentOrderId] = Order(
            currentOrderId,
            _customer,
            _amount,
            OrderState.Created
        );
        return currentOrderId;
    }

    function confirmOrder(uint OrderToBeConfirmed) public {
        Order storage order = orders[OrderToBeConfirmed];
        require(order.state == OrderState.Created, "Order already confirmed");
        order.state = OrderState.Confirmed;
    }

    function deliverOrder(uint deliveredOrder) public {
        Order storage order = orders[deliveredOrder];
        UserProfile storage profile = profiles[order.customer];
        require(order.state == OrderState.Confirmed, "Order not confirmed");
        require(
            msg.sender == order.customer,
            "Only customer can confirm delivery"
        );
        order.state = OrderState.Delivered;
        // remove from current orders and add to completed orders
        for (uint i = 0; i < profile.currentOrders.length; i++) {
            if (profile.currentOrders[i] == deliveredOrder) {
                profile.currentOrders[i] = profile.currentOrders[
                    profile.currentOrders.length - 1
                ];
                profile.currentOrders.pop();
                break;
            }
        }

        profile.completedOrders.push(deliveredOrder);
    }

    function setProfile(string memory _name, string memory _age) public {
        profiles[msg.sender].name = _name;
        profiles[msg.sender].age = _age;
    }

    function getProfile(
        address _user
    ) public view returns (string memory, string memory) {
        return (profiles[_user].name, profiles[_user].age);
    }

    function getOrderState(uint id) public view returns (OrderState) {
        return orders[id].state;
    }

    function getOrder(uint id) public view returns (Order memory) {
        return orders[id];
    }

    function getOrders(address _user) public view returns (uint[] memory) {
        return profiles[_user].currentOrders;
    }
}
