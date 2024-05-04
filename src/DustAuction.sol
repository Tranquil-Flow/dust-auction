// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "MathLibrary.sol";

//TODO: Cleanup variable names to be unique
//TODO: Natspec
//TODO: Rename old Chainlink variables to be more relevant to protocol

contract DustAuction is ReentrancyGuard, OwnerIsCreator {
    using SafeERC20 for IERC20;

    // Errors
    error InvalidTokenAmount(uint256 amount);
    error InvalidTokenAddress(address addr);
    error TokenApprovalFailed();
    error TokenTransferFailed();
    error OfferInvalid();
    error NotOwnerOfOffer();

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
    error SourceChainNotAllowed(uint64 sourceChainSelector); // Used when the source chain has not been allowlisted by the contract owner.
    error SenderNotAllowed(address sender); // Used when the sender has not been allowlisted by the contract owner.
    error InvalidReceiverAddress(); // Used when the receiver address is 0.


    // State Variables
    struct Offer {
        uint offerID;
        address seller;
        address tokenSelling;
        uint sellAmount;
        address tokenBuying;
        uint offerStartTime;
        uint timeline;
        bool offerOpen;
    }

    Offer[] public offers;

    mapping(uint64 => bool) public allowlistedChains;
    IRouterClient private s_router;
    IERC20 private s_linkToken;

        // Mapping to keep track of allowlisted source chains.
    mapping(uint64 => bool) public allowlistedSourceChains;

    // Mapping to keep track of allowlisted senders.
    mapping(address => bool) public allowlistedSenders;

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
    event TokensTransferred(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );
    event CrossChainOfferAccepted(
        uint offerID,
        address buyer,
        address indexed tokenSelling,
        uint sellTokenAmount,
        address tokenBuying,
        uint buyTokenAmount,
        uint timeBought,
        uint receiveChain
    );

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    constructor(address _router, address _link) {
        s_router = IRouterClient(_router);
        s_linkToken = IERC20(_link);
    }

    /// @dev Modifier that checks if the chain with the given destinationChainSelector is allowlisted.
    /// @param _destinationChainSelector The selector of the destination chain.
    modifier onlyAllowlistedChain(uint64 _destinationChainSelector) {
        if (!allowlistedChains[_destinationChainSelector])
            revert DestinationChainNotAllowlisted(_destinationChainSelector);
        _;
    }

    /// @dev Modifier that checks the receiver address is not 0.
    /// @param _receiver The receiver address.
    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert InvalidReceiverAddress();
        _;
    }

    /// @dev Modifier that checks if the chain with the given sourceChainSelector is allowlisted and if the sender is allowlisted.
    /// @param _sourceChainSelector The selector of the destination chain.
    /// @param _sender The address of the sender.
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector])
            revert SourceChainNotAllowed(_sourceChainSelector);
        if (!allowlistedSenders[_sender]) revert SenderNotAllowed(_sender);
        _;
    }

    // Functions
    /**
    * @notice Make an offer to sell an asset.
    * @param tokenSelling The contract address of the token being sold.
    * @param tokenBuying The contract address of the token being bought.
    * @param sellAmount The amount of tokens being sold.
    * @param timeline The amount of time in seconds for ###minimum sell price to be achieved###.
    */
    function makeOffer(
        address tokenSelling,
        address tokenBuying,
        uint sellAmount,
        uint timeline
    ) external nonReentrant {
        if (sellAmount <= 0) {revert InvalidTokenAmount(sellAmount);}
        if (tokenSelling == address(0)) {revert InvalidTokenAddress(tokenSelling);}

        // Approve the contract to spend the tokens
        bool approvalSuccess = IERC20(tokenSelling).approve(address(this), sellAmount);
        if (!approvalSuccess) {revert TokenApprovalFailed();}

        // Transfer tokens to contract
        bool transferSuccess = IERC20(tokenSelling).transferFrom(msg.sender, address(this), sellAmount);
        if (!transferSuccess) {revert TokenTransferFailed();}

        // Store the offer for others to view
        offers.push(Offer(offers.length, msg.sender, tokenSelling, sellAmount, tokenBuying, block.timestamp, timeline, true));

        emit OfferMade(offers.length - 1, msg.sender, tokenSelling, sellAmount, block.timestamp, timeline);
    }

    // Given an input asset amount, returns the output amount of the other asset at current time.
    function getAmountOut(uint offerID, uint inputAmount,uint timeline) public returns (uint outAmount) {

        uint step_1=200000-pow_ratio((100000+inputAmount),1,timeline,1,1);
        uint step_2=pow_ratio(step_1,1,1,timeline)-1;
        return step_2;
    }

    // Returns the input amount required to buy the given output asset amount at current time.
    function getAmountIn(uint offerID) public returns (uint inAmount) {
        step_1=200000-pow_ratio((100000+inputAmount),1,timeline,1,1);
        step_2=pow_ratio(step_1,1,1,timeline)-1;
        return step_2;
    }

    function acceptOfferPartial(
        uint offerID,
        uint inputAmount
    ) external nonReentrant {
        if (offers[offerID].offerOpen == false) {revert OfferInvalid();}
        if (inputAmount <= 0) {revert InvalidTokenAmount(inputAmount);}

        // Check the amount of tokens the buyer will receive for inputAmount and at current time
        uint amountReceived = getAmountOut(offerID, inputAmount);

        // Update the offer
        offers[offerID].sellAmount -= amountReceived;

        // Transfer tokens to seller
        IERC20(offers[offerID].tokenBuying).transfer(offers[offerID].seller, inputAmount);

        // Transfer tokens to buyer
        IERC20(offers[offerID].tokenSelling).transfer(msg.sender, amountReceived);

        emit OfferAcceptedPartial(offerID, msg.sender, offers[offerID].tokenSelling, amountReceived, offers[offerID].tokenBuying, inputAmount, block.timestamp);

    }

    function acceptOfferFull(
        uint offerID
    ) external nonReentrant {
        if (offers[offerID].offerOpen == false) {revert OfferInvalid();}

        // Check the amount of tokens needed to buy the offer at current time
        uint amountNeeded = getAmountIn(offerID);

        // Close the offer
        offers[offerID].offerOpen = false;

        // Transfer tokens to seller
        IERC20(offers[offerID].tokenBuying).transfer(offers[offerID].seller, amountNeeded);

        // Transfer tokens to buyer
        IERC20(offers[offerID].tokenSelling).transfer(msg.sender, offers[offerID].sellAmount);

        emit OfferAccepted(offerID, msg.sender, offers[offerID].tokenSelling, offers[offerID].sellAmount, offers[offerID].tokenBuying, amountNeeded, block.timestamp);

    }

    function cancelOffer(
        uint offerID
    ) external nonReentrant {
        if (offers[offerID].seller != msg.sender) {revert NotOwnerOfOffer();}
        if (offers[offerID].offerOpen == false) {revert OfferInvalid();}

        // Close the offer
        offers[offerID].offerOpen = false;

        // Transfer tokens back to seller
        bool transferSuccess = IERC20(offers[offerID].tokenSelling).transfer(offers[offerID].seller, offers[offerID].sellAmount);
        if (!transferSuccess) {revert TokenTransferFailed();}

        emit OfferCancelled(offerID);
    }

    function acceptOfferFullCrossChain(
        uint offerID,
        address buyToken,
        uint buyAmount,
        address buyer,
        uint64 destinationChain
    ) public nonReentrant {
        if (offers[offerID].offerOpen == false) {revert OfferInvalid();} // Fix to send back tokens if offer invalid

        // Close the offer
        offers[offerID].offerOpen = false;

        // Transfer tokens to seller
        IERC20(offers[offerID].tokenBuying).transfer(offers[offerID].seller, buyAmount);

        // Transfer tokens to buyer
        transferTokensPayLINK(destinationChain, buyer, offers[offerID].tokenSelling, offers[offerID].sellAmount);

        emit CrossChainOfferAccepted(offerID, buyer, offers[offerID].tokenSelling, offers[offerID].sellAmount, buyToken, buyAmount, block.timestamp, destinationChain);
    }

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    )
        internal
        onlyAllowlisted(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        ) // Make sure source chain and sender are allowlisted
    {

        // Get info from message
        uint decodedOfferId = abi.decode(any2EvmMessage.data, (uint));
        address buyToken = any2EvmMessage.destTokenAmounts[0].token;
        uint buyAmount = any2EvmMessage.destTokenAmounts[0].amount;
        uint64 callerChain = any2EvmMessage.sourceChainSelector;
        address buyer = abi.decode(any2EvmMessage.sender, (address));

        acceptOfferFullCrossChain(decodedOfferId, buyToken, buyAmount, buyer, callerChain);
    }

    /// @dev Updates the allowlist status of a destination chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain to be updated.
    /// @param allowed The allowlist status to be set for the destination chain.
    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedChains[_destinationChainSelector] = allowed;
    }

    /// @notice Transfer tokens to receiver on the destination chain.
    /// @notice pay in LINK.
    /// @notice the token must be in the list of supported tokens.
    /// @notice This function can only be called by the owner.
    /// @dev Assumes your contract has sufficient LINK tokens to pay for the fees.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _receiver The address of the recipient on the destination blockchain.
    /// @param _token token address.
    /// @param _amount token amount.
    /// @return messageId The ID of the message that was sent.
    function transferTokensPayLINK(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    )
        public
        onlyOwner
        onlyAllowlistedChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        //  address(linkToken) means fees are paid in LINK
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            _token,
            _amount,
            address(s_linkToken)
        );

        // Get the fee required to send the message
        uint256 fees = s_router.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        s_linkToken.approve(address(s_router), fees);

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        IERC20(_token).approve(address(s_router), _amount);

        // Send the message through the router and store the returned message ID
        messageId = s_router.ccipSend(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            _token,
            _amount,
            address(s_linkToken),
            fees
        );

        // Return the message ID
        return messageId;
    }

    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
    /// @param _receiver The address of the receiver.
    /// @param _token The token to be transferred.
    /// @param _amount The amount of the token to be transferred.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: "", // No data
                tokenAmounts: tokenAmounts, // The amount and type of token being transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit to 0 as we are not sending any data
                    Client.EVMExtraArgsV1({gasLimit: 0})
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
    }

    // Returns the variables off an offer
    function viewOffer(uint offerID) public view returns (address, address, uint, uint, uint, bool) {
        return (
            offers[offerID].seller,
            offers[offerID].tokenSelling,
            offers[offerID].sellAmount,
            offers[offerID].offerStartTime,
            offers[offerID].timeline,
            offers[offerID].offerOpen
        );
    }

    function viewOffersLength() public view returns (uint) {
        return offers.length;
    }

}
