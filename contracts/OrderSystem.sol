// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* Events */

// Event to log the creation of an order
event OrderCreated(uint orderId, address customer, uint amount);
// Event to log the confirmation of an order
event OrderConfirmed(uint orderId, address customer);
//  Event to log the delivery of an order
event OrderDelivered(uint orderId, address customer);
// Event to log cancelation of an order
event OrderCancelled(uint orderId, address customer);
// Event to log creating a user profile
event ProfileCreated(address user, string name, string age);
// Event to log deleting a user profile
event ProfileDeleted(address user);

/* Custom Errors */

// Custom error for a user that has not yet created a profile
error UserProfileDoesNotExist();
// Custom error for an order that is already confirmed
error OrderAlreadyConfirmed();
// Custom error for an order that is already delivered
error OrderAlreadyDelivered();
// Custom error for an order that is not confirmed
error OrderNotConfirmed();
// Custom error so users can not delete profiles with active orders
error CannotDeleteProfileWithActiveOrders();
// Custom Error for order that is already cancelled
error OrderAlreadyCancelled();



/**
 * @title OrderSystem
 * @dev Contract to manage orders and user profiles
 */
contract OrderSystem {
    /* State Variables */
    address private owner;

    /* Constructor */
    // Set the owner of the contract
    constructor() {
        owner = msg.sender;
    }

    /* Enums */

    // Enums for different states of an order
    enum OrderState {
        Created,
        Confirmed,
        Delivered,
        Cancelled
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
     * @param _amount Amount of the order
     * @return orderId of the created order
     */
    function createOrder(
        uint _amount
    ) public returns (uint) {
        // Check if the amount is greater than 0
        require(_amount > 0, "Amount should be greater than 0");

        address customer = msg.sender;
        // Must create a user profile before placing an order
        if(
            bytes(profiles[customer].name).length <= 0){
                revert UserProfileDoesNotExist();
            }
        

        // Sets the orderId to the created order then increments OrderId
        uint currentOrderId = orderId;
        orderId++;

        // Add the order to the customer's profile
        UserProfile storage profile = profiles[customer];
        // Add the order to the customer's current orders
        profile.currentOrders.push(currentOrderId);
        // Add the order to the orders mapping
        orders[currentOrderId] = Order(
            currentOrderId,
            customer,
            _amount,
            OrderState.Created
        );
    
        emit OrderCreated(currentOrderId, customer, _amount);

        return currentOrderId;
    }

    /**
     * @dev Confirm an order
     * @param orderToBeConfirmed Order to be confirmed
     */
    function confirmOrder(uint orderToBeConfirmed) public {
        // Only customer can confirm the order
        require(
            msg.sender == orders[orderToBeConfirmed].customer,
            "Only customer can confirm order"
        );
        // Get the order to be confirmed
        Order storage order = orders[orderToBeConfirmed];
        // Check if the order is in the created state
        if(order.state == OrderState.Confirmed){
            revert OrderAlreadyConfirmed();
        }

        order.state = OrderState.Confirmed;

        emit OrderConfirmed(orderToBeConfirmed, order.customer);
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
        if(order.state == OrderState.Delivered){
            revert OrderAlreadyDelivered();
        }
        // Check if the order is in the confirmed state
        if(order.state != OrderState.Confirmed){
            revert OrderNotConfirmed();
        }

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

    function adminDeleteProfileAndOrders(address _user) public onlyOwner {
        require(
            bytes(profiles[_user].name).length > 0,
            "Profile does not exist for the given address"
        );
        // Cancel all orders of user
        for (uint i = 0; i < profiles[_user].currentOrders.length; i++) {
            cancelOrder(profiles[_user].currentOrders[i]);
        }
        // Delete the user profile
        delete profiles[_user];
        // Emit the event
        emit ProfileDeleted(_user);
    }

    /**
     * @dev Delete user profile
     */
    function deleteProfile() public {
        // Check if the profile exists
        if(
            bytes(profiles[msg.sender].name).length <= 0){
                revert UserProfileDoesNotExist();
            }
        // Check if the user has active orders
        if(profiles[msg.sender].currentOrders.length != 0){
            revert CannotDeleteProfileWithActiveOrders();
        }
        // Delete the user profile
        delete profiles[msg.sender];
        // Emit the event
        emit ProfileDeleted(msg.sender);
    }

    /**
     * @dev Cancel an order
     * @param idToCancel Order to be cancelled
     */
    function cancelOrder(uint idToCancel) public {
        // require that the msg.sender is the user who created the order
        if(msg.sender != owner){
            require(
                msg.sender == orders[idToCancel].customer,
                "Only customer can cancel order"
            );
        }
       
        // Get the order to be delivered
        Order storage order = orders[idToCancel];
        // Get the customer's profile
        UserProfile storage profile = profiles[order.customer];

        // Check if the order is not already cancelled
        if (order.state == OrderState.Cancelled) {
            revert OrderAlreadyCancelled();
        }

        // Check if the order is not already delivered
        if(order.state == OrderState.Delivered){
            revert OrderAlreadyDelivered();
        }
        // Check if the order is in the confirmed state
        if(order.state != OrderState.Confirmed){
            revert OrderNotConfirmed();
        }

        order.state = OrderState.Cancelled;

        emit OrderCancelled(idToCancel, order.customer);

        // remove from current orders
        for (uint i = 0; i < profile.currentOrders.length; i++) {
            if (profile.currentOrders[i] == idToCancel) {
                profile.currentOrders[i] = profile.currentOrders[
                    profile.currentOrders.length - 1
                ];
                profile.currentOrders.pop();
                break;
            }
        }

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
