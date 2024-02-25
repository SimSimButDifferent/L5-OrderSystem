// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* Events */

// Event to log the creation of an order
event OrderCreated(uint orderId, address customer, uint amount);
// Event to log the confirmation of an order
event OrderConfirmed(uint orderId, address customer);
//  Event to log the delivery of an order
event OrderDelivered(uint orderId, address customer);
// Event to log creating a user profile
event ProfileCreated(address user, string name, string age);

contract OrderSystem {
    /* State Variables */
    address private owner;

    // Owner of the contract
    constructor() {
        owner = msg.sender;
    }

    /* Enums */

    // Enums for different states of an order
    enum OrderState {
        Created,
        Confirmed,
        Delivered
    }

    /* Structs */

    // Struct to store user profile details and orders
    struct UserProfile {
        string name;
        string age;
        uint[] currentOrders;
        uint[] completedOrders;
    }

    // Struct to store order details and state
    struct Order {
        uint id;
        address customer;
        uint amount;
        OrderState state;
    }

    /* Mappings */

    // mapping to store user profiles using address as key
    mapping(address => UserProfile) private profiles;

    // mapping to store orders, using the orderId as key
    mapping(uint => Order) private orders;

    // variable to store order id
    uint private orderId = 0;

    /* Modifiers */

    // Modifier to check if the sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /* Functions */

    /**
     * @dev Set user profile. Must be called before placing an order
     * @param _name Name of the user
     * @param _age Age of the user
     */
    function newUserProfile(string memory _name, string memory _age) public {
        // Check if the name and age are not empty
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_age).length > 0, "Age cannot be empty");
        // Set the user profile details
        profiles[msg.sender].name = _name;
        profiles[msg.sender].age = _age;

        emit ProfileCreated(msg.sender, _name, _age);
    }

    /**
     * @dev Create an order
     * @param _customer Address of the customer
     * @param _amount Amount of the order
     * @return orderId of the created order
     */
    function createOrder(
        address _customer,
        uint _amount
    ) public returns (uint) {
        // Check if the amount is greater than 0
        require(_amount > 0, "Amount should be greater than 0");

        // Must create a user profile before placing an order
        require(
            bytes(profiles[_customer].name).length > 0,
            "User profile does not exist"
        );

        // Sets the orderId to the created order then increments OrderId
        uint currentOrderId = orderId;
        orderId++;

        // Add the order to the customer's profile
        UserProfile storage profile = profiles[_customer];
        // Add the order to the customer's current orders
        profile.currentOrders.push(currentOrderId);
        // Add the order to the orders mapping
        orders[currentOrderId] = Order(
            currentOrderId,
            _customer,
            _amount,
            OrderState.Created
        );
    
        emit OrderCreated(currentOrderId, _customer, _amount);

        return currentOrderId;
    }

    /**
     * @dev Confirm an order
     * @param OrderToBeConfirmed Order to be confirmed
     */
    function confirmOrder(uint OrderToBeConfirmed) public {
        // Only customer can confirm the order
        require(
            msg.sender == orders[OrderToBeConfirmed].customer,
            "Only customer can confirm order"
        );
        // Get the order to be confirmed
        Order storage order = orders[OrderToBeConfirmed];
        // Check if the order is in the created state
        require(order.state == OrderState.Created, "Order already confirmed");

        order.state = OrderState.Confirmed;

        emit OrderConfirmed(OrderToBeConfirmed, order.customer);
    }

    /**
     * @dev Deliver an order
     * @param deliveredOrder Order to be delivered
     */
    function confirmDelivery(uint deliveredOrder) public {
        // require that the msg.sender is the user who created the order
        require(
            msg.sender == orders[deliveredOrder].customer,
            "Only customer can confirm delivery"
        );
        // Get the order to be delivered
        Order storage order = orders[deliveredOrder];
        // Get the customer's profile
        UserProfile storage profile = profiles[order.customer];
        // Check if the order is not already delivered
        require(order.state != OrderState.Delivered, "Order already delivered");
        // Check if the order is in the confirmed state
        require(order.state == OrderState.Confirmed, "Order not confirmed");

        order.state = OrderState.Delivered;

        emit OrderDelivered(deliveredOrder, order.customer);

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

        // Add the order to the customer's completed orders
        profile.completedOrders.push(deliveredOrder);
    }

    
    /* Getter Functions */

    /**
     * @dev Get user profile
     * @param _user Address of the user
     * @return Name and age of the user
     */
    function getProfile(
        address _user
    ) public view onlyOwner returns (string memory, string memory) {
        // Check if the address is valid
        require(_user != address(0), "Invalid address");
        // Check if the profile exists
        require(
            bytes(profiles[_user].name).length > 0,
            "Profile does not exist for the given address"
        );

        return (profiles[_user].name, profiles[_user].age);
    }

    /**
     * @dev Get order state
     * @param id Order id
     * @return Order state
     */
    function getOrderState(uint id) public view returns (OrderState) {
        return orders[id].state;
    }

    /**
     * @dev Get order details
     * @param id Order id
     * @return Order details
     */
    function getOrder(uint id) public view returns (Order memory) {
        require(orders[id].id == id, "Order does not exist");

        return orders[id];
    }

    /**
     * @dev Get orders of a user
     * @param _user Address of the user
     * @return Orders of the user
     */
    function getOrders(address _user) public view onlyOwner returns (uint[] memory) {
        require(
            bytes(profiles[_user].name).length > 0,
            "Profile does not exist for the given address"
        );
        return profiles[_user].currentOrders;
    }

    function getMyOrders() public view returns (uint[] memory) {
        require(
            bytes(profiles[msg.sender].name).length > 0,
            "Profile does not exist for the given address");

        return profiles[msg.sender].currentOrders;
    }
}
