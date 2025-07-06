//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {DeployDAO} from "../script/DeployDAO.s.sol";
import {DAO} from "../src/DAO.sol";

contract TestDAO is Test {
    DAO public dao;
    address USER1;
    address USER2;

    function setUp() external {
        dao = new DAO();

        USER1 = makeAddr("user1");
        USER2 = makeAddr("user2");
    }

    function testOnlyExistingMemberCanAddNewMember() external {
        vm.prank(USER2);
        vm.expectRevert();
        dao.addMember(address(8));
        // assertTrue(dao.isMember(address(8)));
    }

    function testNewMemberIsNotAlreadyAdded() external {
        dao.isMember(USER2);
        dao.isMember(USER1);
        vm.prank(USER1);
        
        vm.expectRevert();
        dao.addMember(USER2);
    }

    function testNewMemberIsAddedToTheArray() external {
        dao.addMember(USER1);
        vm.prank(USER1);
        dao.addMember(USER2);

        assertTrue(dao.isMember(USER2));
    }

    function testOnlyMembersCanCreateProposal() external {
        assertTrue(!dao.isMember(USER2));
        vm.prank(USER2);
        vm.expectRevert();
        dao.createProposal("abcdefgh", 123456 seconds);
    }
}