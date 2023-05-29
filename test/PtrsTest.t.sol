// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.14;

import "forge-std/Test.sol";

using Pointers for bytes32;

library Pointers {
    function $(bytes32 offset) internal pure returns (bytes32 ret) {
        assembly {
            mstore(0x00, offset)
            ret := keccak256(0x00, 0x20)
        }
    }

    function $(bytes32 base, bytes32 offset) internal pure returns (bytes32 ret) {
        assembly {
            mstore(0x00, base)
            mstore(0x20, offset)
            ret := keccak256(0x00, 0x40)
        }
        ret = keccak256(abi.encodePacked(base, $(offset)));
    }

    function store(bytes32 loc, uint256 value) internal returns (bytes32) {
        assembly {
            sstore(loc, value)
        }
        return loc;
    }

    function store(bytes32 loc, bytes32 value) internal returns (bytes32) {
        assembly {
            sstore(loc, value)
        }
        return loc;
    }

    function load(bytes32 loc) internal view returns (uint256 value) {
        assembly {
            value := sload(loc)
        }
    }

    // function load(bytes32 key) internal view returns (uint256 value) {
    //     bytes32 loc = key.ptr();
    //     value = load_ptr(loc);
    // }

}

function $(bytes32 offset) pure returns (bytes32 ret) {
    return Pointers.$(offset);
}

function str2ptr(bytes memory str) pure returns (bytes32 ptr) {
    uint256 i = 0;
    uint256 j = 0;
    uint256 neg1 = type(uint256).max;
    bytes32 token;
    uint256 len = bytes(str).length;

    while (true) {
        require(i - j < 0x20, "str2ptr: string too long");

        if (i == len || str[i] == '.') {
            assembly {
                token := and(
                    mload(add(add(str, 0x20), j)),
                    not(shr(shl(3, sub(i, j)), neg1))
                )
            }

            if (j == 0) {
                // it is the first base token
                ptr = $(token);
            } else {
                // it is offset token
                ptr = ptr.$(token);
            }

            if (i == len) {
                break;
            }

            j = i + 1;
        }

        i++;
    }
}
contract PtrsTest is Test {
    function setUp() external {
        bytes32 loc = $("root").store(55);
        bytes32 child = loc.$("child").$("leaf").store(66);
        console.log(loc.load());
        console.log(child.load());

        bytes32 test1 = $("storage").$("is").$("a").$("tree").store(123);
        bytes32 test2 = $("storage").$("is").$("a").$("tree").store(456);
        bytes32 test3 = str2ptr("storage.is.a.tree");
        console.log("%x => %d", uint256(test3), test3.load());
        require(test1 == test2 && test2 == test3, "ptr mismatch");
    }

    function testPtrs() public returns (bytes32) {
        console.log($("root").load());
        console.log($("root").$("child").$("leaf").load());
    }
}
