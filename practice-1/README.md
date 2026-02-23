Task 1. Open Remix and implement a Counter contract:
- pass the initial value through the constructor
- implement increment() and decrement() functions
- implement a getter function
- test different visibility and mutability types

Task 2. In Remix, implement an Ownable contract:
- the deployer must be the initial owner
- implement a transferOwnership(address newOwner) function
- add an onlyOwner modifier

Task 3. Modify your Counter contract from Task 1 to inherit from the Ownable contract implemented in Task 2. Deploy the updated contract to the Virtual EVM. Test your contract using different addresses.
