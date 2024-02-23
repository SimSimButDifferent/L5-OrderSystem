## To run locally

```bash
git clone https://github.com/SimSimButDifferent/L5-OrderSystem.git

yarn
```

```bash
yarn hardhat node
yarn hardhat run scripts/deploy.js --network localhost
yarn hardhat test
```

**To play around with a front end, paste into Remix IDE ---> remix.ethereum.org**

## Lesson 5: Advanced Data Types in Solidity

**Objective:** Dive into advanced data types available in Solidity, focusing on their use cases, limitations, and how they can enhance the functionality and efficiency of smart contracts.

#### Part 1: Enums

-   **Understanding Enums**:
    -   Enums (enumerated types) allow for the creation of custom types with a limited set of 'constant values'. They are useful for representing state, choices, or categories within contracts.
-   **Example of Using Enums**:

```solidity
pragma solidity ^0.8.0;

contract Example {
    enum State { Waiting, Ready, Active }
    State public state;

    constructor() {
        state = State.Waiting;
    }

    function activate() public {
        state = State.Active;
    }

    function isReady() public view returns(bool) {
        return state == State.Ready;
    }
}
```

#### Part 2: Structs

-   **Introduction to Structs**:
    -   Structs allow for the grouping of related properties into a single type, facilitating the management of complex data.
-   **Using Structs in Solidity**:
    -   Declaring structs and creating instances within contracts.
-   **Example: Structs for Storing User Data**:

```solidity
pragma solidity ^0.8.0;

contract Users {
    struct User {
        string name;
        uint age;
    }

    User[] public users;

    function addUser(string memory _name, uint _age) public {
        users.push(User(_name, _age));
    }
}
```

#### Part 3: Mappings

-   **Purpose and Functionality of Mappings**:
    -   Mappings are key-value stores for efficiently storing and retrieving data based on keys. They are one of the most used data types for managing state in contracts.
-   **Example: Using Mappings**:

```solidity
pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint) public accountBalances;

    function deposit() public payable {
        accountBalances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public {
        require(accountBalances[msg.sender] >= _amount, "Insufficient funds");
        payable(msg.sender).transfer(_amount);
        accountBalances[msg.sender] -= _amount;
    }
}
```

#### Part 4: Arrays

-   **Understanding Dynamic and Fixed-size Arrays**:
    -   Solidity supports both dynamic arrays (whose length can change) and fixed-size arrays. Each type has its use cases and limitations.
-   **Example: Dynamic Arrays for Storing Data**:

```solidity
pragma solidity ^0.8.0;

contract MyContract {
    uint[] public dynamicArray;
    uint[10] public fixedArray;

    function addElement(uint _element) public {
        dynamicArray.push(_element);
    }

    function getElement(uint _index) public view returns (uint) {
        return dynamicArray[_index];
    }

    function getFixedElement(uint _index) public view returns (uint) {
        return fixedArray[_index];
    }
}
```

#### Assignments and Practical Exercises

**Assignment 1**:

-   Write a brief essay on how and why to use structs and mappings together in Solidity contracts to manage complex data.

**Exercise 1**:

-   Implement a smart contract using enums to manage the state of a simple process, like an order system.

**Exercise 2**:

-   Create a contract utilizing structs to store user profiles and mappings to efficiently look up profiles by Ethereum addresses.

---

These advanced data types are fundamental in developing robust and functional smart contracts. They enable developers to represent complex data structures and relationships, manage contract state efficiently, and implement sophisticated logic within contracts. Through the practical exercises, you'll gain hands-on experience in utilizing these data types effectively.
