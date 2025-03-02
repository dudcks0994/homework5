// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/Logic.sol";
import "../src/uups.sol";

contract Ether is ERC20 {
    constructor() ERC20("Ether", "ETH") {
        _mint(msg.sender, 1000000000);
    }
}

contract test is Script {
    address mine = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    bytes32 root = 0x75ee49781530add7ff9a93ad3b5ce2551a34f4c56dd9f449c605005e5ab3ecc8;
    Ether public token;
    UUPS public proxy;
    Airdrop public logic;
    function setUp() public {
    }
    function run() public {
        vm.startBroadcast();
        token = new Ether();
        logic = new Airdrop();
        Airdrop temp = new Airdrop();
        proxy = new UUPS(address(logic), "");
        bytes32[] memory proof = new bytes32[](2);
        address to = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        proof[0] = 0xadb63e3973c8474ca4f611474245689a3bc54cff6f60776b615514b95f818aa5;
        proof[1] = 0xab48f697fbff04bded82ae6ea6b0590422e6f056c924e128408e4e4dc738db48;
        bytes4 selector = bytes4(keccak256("claim(address,uint256,bytes32[])"));
        bytes32[] memory proof2 = new bytes32[](2);
        proof2[0] = 0x33ff5cf71dd603e43c706db094451914e4ae09f917978dcd55469bff6945c0a1;
        proof2[1] = 0x474be321111d7f2fe6f213c57fb8cc5c5dbcc875326de414f741db356bb987bd;
        address to2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(
            bytes4(keccak256("claim(address,uint256,bytes32[])")),
            to,
            1024,
            proof
        );
        data[1] = abi.encodeWithSelector(
            bytes4(keccak256("claim(address,uint256,bytes32[])")),
            to2,
            1000,
            proof2
        );
        // data[0] = abi.encodePacked(selector, abi.encodePacked(to, uint(1024), proof));
        // data[1] = abi.encodePacked(selector, to2, uint(1000), proof2);
        token.approve(address(proxy), 1000000);
        address(proxy).call(abi.encodeWithSignature("initialize(address,bytes32,uint256,uint256)", address(token), root, block.timestamp + 24 hours, 10000));
        // address(proxy).call(abi.encodeWithSignature("emergencyStop()"));
        // (bool b, ) = address(proxy).call(abi.encodeWithSignature("claim(address,uint256,bytes32[])", to, 1024, proof));
        (bool success, bytes memory result) = address(proxy).call(
            abi.encodeWithSelector(
                bytes4(keccak256("mulltiCall(bytes[])")),
                data
            )
        );
        vm.stopBroadcast();
    }
}
