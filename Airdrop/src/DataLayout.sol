pragma solidity ^0.8.13;

contract DatalayoutLibrary{
    address public admin;
    address token_addr;
    address owner_addr;
    bytes32 merkle_root;
    uint    public expired_at;
    uint    public total_supply;
    mapping(address => bool) has_claimed;
    enum State {INIT, START, PAUSED} 
    State state;
}