// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
contract CryptolatinsMarket {

    // Se puede ocupar este hash para comprobar las imágenes
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = 'Latinos';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextLatinIndexToAssign = 0;

    bool public allLatinsAssigned = false;
    uint public latinsRemainingToAssign = 0;

    //mapping (address => uint) public addressToLatinIndex;
    mapping (uint => address) public latinIndexToAddress;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint latinIndex;
        address seller;
        uint minValue;          // in Matic´s
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint latinIndex;
        address bidder;
        uint value;
    }

    // A record of latinos that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public latinOfferedForSale;

    // A record of the highest latin bid
    mapping (uint => Bid) public latinBids;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 latinIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event LatinTransfer(address indexed from, address indexed to, uint256 latinIndex);
    event LatinOffered(uint indexed latinIndex, uint minValue, address indexed toAddress);
    event LatinBidEntered(uint indexed latinIndex, uint value, address indexed fromAddress);
    event LatinBidWithdrawn(uint indexed latinIndex, uint value, address indexed fromAddress);
    event LatinBought(uint indexed latinIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event LatinNoLongerForSale(uint indexed latinIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoLatinsMarket() payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 1000;                        // Update total supply
        latinsRemainingToAssign = totalSupply;
        name = "LATINTHINGS";                                   // Set the name for display purposes
        symbol = "O_o";                               // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint latinIndex) {
        revert (msg.sender == owner);
        revert (allLatinsAssigned);
        if (latinIndex >= 10000);
        // Avance Miércoles 1/09/2021 a las 10:31     
        
        if (latinIndexToAddress[latinIndex] != to) {
            if (latinIndexToAddress[latinIndex] != 0x0) {
                balanceOf[latinIndexToAddress[latinIndex]]--;
            } else {
                latinsRemainingToAssign--;
            }
            latinIndexToAddress[latinIndex] = to;
            balanceOf[to]++;
            Assign(to, latinIndex);
        }
    }

    function setInitialOwners(address[] addresses, uint[] indices) {
        if (msg.sender != owner) throw;
        uint n = addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() {
        if (msg.sender != owner) throw;
        alllatinsAssigned = true;
    }

    function getlatin(uint latinIndex) {
        if (!alllatinsAssigned) throw;
        if (latinsRemainingToAssign == 0) throw;
        if (latinIndexToAddress[latinIndex] != 0x0) throw;
        if (latinIndex >= 10000) throw;
        latinIndexToAddress[latinIndex] = msg.sender;
        balanceOf[msg.sender]++;
        latinsRemainingToAssign--;
        Assign(msg.sender, latinIndex);
    }

    // Transfer ownership of a latin to another user without requiring payment
    function transferlatin(address to, uint latinIndex) {
        if (!alllatinsAssigned) throw;
        if (latinIndexToAddress[latinIndex] != msg.sender) throw;
        if (latinIndex >= 10000) throw;
        if (latinsOfferedForSale[latinIndex].isForSale) {
            latinNoLongerForSale(latinIndex);
        }
        latinIndexToAddress[latinIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        latinTransfer(msg.sender, to, latinIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = latinBids[latinIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            latinBids[latinIndex] = Bid(false, latinIndex, 0x0, 0);
        }
    }

    function latinNoLongerForSale(uint latinIndex) {
        if (!alllatinsAssigned) throw;
        if (latinIndexToAddress[latinIndex] != msg.sender) throw;
        if (latinIndex >= 10000) throw;
        latinsOfferedForSale[latinIndex] = Offer(false, latinIndex, msg.sender, 0, 0x0);
        latinNoLongerForSale(latinIndex);
    }

    function offerlatinForSale(uint latinIndex, uint minSalePriceInWei) {
        if (!alllatinsAssigned) throw;
        if (latinIndexToAddress[latinIndex] != msg.sender) throw;
        if (latinIndex >= 10000) throw;
        latinsOfferedForSale[latinIndex] = Offer(true, latinIndex, msg.sender, minSalePriceInWei, 0x0);
        latinOffered(latinIndex, minSalePriceInWei, 0x0);
    }

    function offerlatinForSaleToAddress(uint latinIndex, uint minSalePriceInWei, address toAddress) {
        if (!alllatinsAssigned) throw;
        if (latinIndexToAddress[latinIndex] != msg.sender) throw;
        if (latinIndex >= 10000) throw;
        latinsOfferedForSale[latinIndex] = Offer(true, latinIndex, msg.sender, minSalePriceInWei, toAddress);
        latinOffered(latinIndex, minSalePriceInWei, toAddress);
    }

    function buylatin(uint latinIndex) payable {
        if (!alllatinsAssigned) throw;
        Offer offer = latinsOfferedForSale[latinIndex];
        if (latinIndex >= 10000) throw;
        if (!offer.isForSale) throw;                // latin not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw;  // latin not supposed to be sold to this user
        if (msg.value < offer.minValue) throw;      // Didn't send enough ETH
        if (offer.seller != latinIndexToAddress[latinIndex]) throw; // Seller no longer owner of latin

        address seller = offer.seller;

        latinIndexToAddress[latinIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        latinNoLongerForSale(latinIndex);
        pendingWithdrawals[seller] += msg.value;
        latinBought(latinIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = latinBids[latinIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            latinBids[latinIndex] = Bid(false, latinIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!alllatinsAssigned) throw;
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForlatin(uint latinIndex) payable {
        if (latinIndex >= 10000) throw;
        if (!alllatinsAssigned) throw;                
        if (latinIndexToAddress[latinIndex] == 0x0) throw;
        if (latinIndexToAddress[latinIndex] == msg.sender) throw;
        if (msg.value == 0) throw;
        Bid existing = latinBids[latinIndex];
        if (msg.value <= existing.value) throw;
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        latinBids[latinIndex] = Bid(true, latinIndex, msg.sender, msg.value);
        latinBidEntered(latinIndex, msg.value, msg.sender);
    }

    function acceptBidForlatin(uint latinIndex, uint minPrice) {
        if (latinIndex >= 10000) throw;
        if (!alllatinsAssigned) throw;                
        if (latinIndexToAddress[latinIndex] != msg.sender) throw;
        address seller = msg.sender;
        Bid bid = latinBids[latinIndex];
        if (bid.value == 0) throw;
        if (bid.value < minPrice) throw;

        latinIndexToAddress[latinIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        latinsOfferedForSale[latinIndex] = Offer(false, latinIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        latinBids[latinIndex] = Bid(false, latinIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        latinBought(latinIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForlatin(uint latinIndex) {
        if (latinIndex >= 10000) throw;
        if (!alllatinsAssigned) throw;                
        if (latinIndexToAddress[latinIndex] == 0x0) throw;
        if (latinIndexToAddress[latinIndex] == msg.sender) throw;
        Bid bid = latinBids[latinIndex];
        if (bid.bidder != msg.sender) throw;
        latinBidWithdrawn(latinIndex, bid.value, msg.sender);
        uint amount = bid.value;
        latinBids[latinIndex] = Bid(false, latinIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}