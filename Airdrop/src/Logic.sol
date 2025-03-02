pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "./DataLayout.sol";
import {StorageSlot} from "openzeppelin-contracts/contracts/utils/StorageSlot.sol";


contract Airdrop is UUPSUpgradeable, DatalayoutLibrary{
    event Claimed(address indexed user, uint amount);
    event AirdropPaused(uint timestamp);
    event AirdropStart();

    modifier beforeStart(){
        require(state == State.INIT, "Airdrop already started");
        _;
    }

    modifier afterStart(){
        require(state == State.START, "Airdrop not started yet");
        _;
    }

    modifier checkExpired(){
        require(block.timestamp < expired_at, "Airdrop expired!");
        _;
    }

    modifier isEmergency(){
        require(state != State.PAUSED, "Service STOPPED..");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == admin, "Unauthorized");
        _;
    }

    function initialize(address _token_addr, bytes32 _merkle_root, uint _expired_at, uint _total_supply) public onlyProxy beforeStart{
        token_addr = _token_addr;
        owner_addr = msg.sender;
        require(ERC20(token_addr).allowance(msg.sender, address(this)) >= _total_supply, "Insufficient balance");
        merkle_root = _merkle_root;
        expired_at = _expired_at;
        total_supply = _total_supply;
        state = State.START;
        admin = msg.sender;
    }

    function claim(address _to, uint amount, bytes32[] calldata merkle_proof) public afterStart checkExpired isEmergency{
        require(!has_claimed[_to], "Already claimed");
        require(verifyProof(merkle_proof, merkle_root, keccak256(abi.encodePacked(_to, amount))), "Invalid data");
        has_claimed[msg.sender] = true;
        total_supply -= amount;
        require(ERC20(token_addr).transferFrom(owner_addr, _to, amount), "Transfer Failed");
        emit Claimed(msg.sender, amount);
    }

    function verifyProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf) public pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

    function mulltiCall(bytes[] calldata data) external onlyProxy returns (bytes[] memory results)  {
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) 
                results[i] = abi.encode(false);
            else
                results[i] = result;
        }
    }

    function emergencyStop() public onlyProxy onlyOwner() {
        state = State.PAUSED;
        emit AirdropPaused(block.timestamp);
    }
    function upgradeTo(address newImplementation) public {
        super.upgradeToAndCall(newImplementation, "");
    }
    function _authorizeUpgrade(address newImplementation) internal override {
        require(msg.sender == admin, "Unauthorized");
    }
    function transferOwnership(address newOwner) public onlyProxy {
        require(msg.sender == admin, "Unauthorized");
        admin = newOwner;
    }
}