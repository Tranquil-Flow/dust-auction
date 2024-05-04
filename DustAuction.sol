pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//TODO: Add token being accepted for offers
//TODO: Cleanup variable names to be unique
//TODO: Natspec

contract DustAuction is ReentrancyGuard {

    // Errors
    error InvalidTokenAmount(uint256 amount);
    error InvalidTokenAddress(address addr);
    error TokenTransferFailed();
    error OfferInvalid();
    error NotOwnerOfOffer();

    // State Variables
    struct Offer {
        uint offerID;
        address seller;
        address tokenSelling;
        uint tokenAmount;
        uint offerStartTime;
        uint timeline;
        bool offerOpen;
    }

    Offer[] public offers;

    // Events
    event OfferMade(
        uint offerID,
        address seller,
        address indexed tokenSelling,
        uint sellTokenAmount,
        uint offerStartTime,
        uint timeline
    );
    event OfferAcceptedPartial(
        uint offerID,
        address buyer,
        address indexed tokenSelling,
        uint sellTokenAmount,
        address tokenBuying,
        uint buyTokenAmount,
        uint timeBought
    );
    event OfferAccepted(
        uint offerID,
        address buyer,
        address indexed tokenSelling,
        uint sellTokenAmount,
        address tokenBuying,
        uint buyTokenAmount,
        uint timeBought
    );
    event OfferCancelled(uint offerID);

    /**
    * @notice Make an offer to sell an asset.
    * @param tokenSelling The contract address of the token being sold.
    * @param tokenBuying The contract address of the token being bought.
    * @param tokenAmount The amount of tokens being sold.
    * @param timeline The amount of time in seconds for ###minimum sell price to be achieved###.
    */
    function makeOffer(
        address tokenSelling,
        address tokenBuying,
        uint tokenAmount,
        uint timeline
    ) external reentrancyGuard returns (uint) {
        if (tokenAmount <= 0) {revert InvalidTokenAmount(tokenAmount);}
        if (tokenSelling == address(0)) {revert InvalidTokenAddress(tokenSelling);}

        // Approve the contract to spend the tokens
        bool approvalSuccess = IERC20(tokenSelling).approve(address(this), tokenAmount);
        if (!approvalSuccess) {revert TokenApprovalFailed();}

        // Transfer tokens to contract
        bool transferSuccess = IERC20(tokenSelling).transferFrom(msg.sender, address(this), tokenAmount);
        if (!transferSuccess) {revert TokenTransferFailed();}

        // Store the offer for others to view
        offers.push(Offer(offers.length, msg.sender, tokenSelling, tokenAmount, block.timestamp, timeline, true));

        return offers.length - 1;

        emit OfferMade(offers.length - 1, msg.sender, tokenSelling, tokenAmount, block.timestamp, timeline);
        
    }

    // Given an input asset amount, returns the output amount of the other asset at current time.
    function getAmountOut(uint offerID, uint inputAmount) public returns (uint) {

    }

    // Returns the input amount required to buy the given output asset amount at current time.
    function getAmountIn(uint offerID) public returns (uint) {

    }

    function acceptOfferPartial(
        uint offerID,
        uint inputAmount
    ) external reentrancyGuard {
        if (offers[offerID].offerOpen == false) {revert OfferInvalid();}
        if (inputAmount <= 0) {revert InvalidTokenAmount(inputAmount);}

        // Check the amount of tokens the buyer will receive for inputAmount and at current time
        uint amountReceived = getAmountOut(offerID, inputAmount);

        // Update the offer
        offers[offerID].tokenAmount -= amountReceived;

        // Transfer tokens to seller
        IERC20(offers[offerID].tokenBuying).transfer(offers[offerID].seller, inputAmount);

        // Transfer tokens to buyer
        IERC20(offers[offerID].tokenSelling).transfer(msg.sender, amountReceived);

        emit OfferAcceptedPartial(offerID, msg.sender, offers[offerID].tokenSelling, amountReceived, offers[offerID].tokenBuying, inputAmount, block.timestamp);

    }

    function acceptOfferFull(
        uint offerID
    ) external reentrancyGuard {
        if (offers[offerID].offerOpen == false) {revert OfferInvalid();}

        // Check the amount of tokens needed to buy the offer at current time
        uint amountNeeded = getAmountIn(offerID);

        // Close the offer
        offers.offerID.offerOpen = false;

        // Transfer tokens to seller
        IERC20(offers[offerID].tokenBuying).transfer(offers[offerID].seller, amountNeeded);

        // Transfer tokens to buyer
        IERC20(offers[offerID].tokenSelling).transfer(msg.sender, offers[offerID].tokenAmount);

        emit OfferAccepted(offerID, msg.sender, offers[offerID].tokenSelling, offers[offerID].tokenAmount, offers[offerID].tokenBuying, amountNeeded, block.timestamp);

    }

    function cancelOffer(
        uint offerID
    ) external reentrancyGuard {
        if (offers[offerID].seller != msg.sender) {revert NotOwnerOfOffer();}
        if (offers[offerID].offerOpen == false) {revert OfferInvalid();}

        // Close the offer
        offers.offerID.offerOpen = false;

        // Transfer tokens back to seller
        bool transferSuccess = IERC20(offers[offerID].tokenSelling).transfer(offers[offerID].seller, offers[offerID].tokenAmount);
        if (!transferSuccess) {revert TokenTransferFailed();}

        emit OfferCancelled(offerID);
    }

    // Returns the variables off an offer
    function viewOffer(uint offerID) public view returns (address, address, uint, uint, uint, bool) {
        return (
            offers[offerID].seller,
            offers[offerID].tokenSelling,
            offers[offerID].tokenAmount,
            offers[offerID].offerStartTime,
            offers[offerID].timeline,
            offers[offerID].offerOpen
        );
    }

}
