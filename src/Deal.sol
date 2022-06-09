// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
import "./interfaces/Deps.sol";

contract Deal is Ownable{
    using SafeERC20 for IERC20;
    address secondaryParty;

    struct Offer {
        address[] tokens;
        uint[] amounts;
        address party;
    }
    
    Offer[] offers;
    uint[] accepted;//0 = no , else = yes
    uint sent;

    Offer listing;

    constructor(address[] memory _tokens, uint[] memory _amounts) {
        require(_tokens.length == _amounts.length);
        listing = Offer(_tokens, _amounts, msg.sender);
        for(uint i = 0; i < listing.tokens.length; i++){
            IERC20(listing.tokens[i]).safeTransferFrom(msg.sender,address(this),listing.amounts[i]); //get safetransfer
        }
        //unnecessary check i think
        sent = 0;
        _ensureOfferReceived(listing);
    }

    //might be entirely unnecessary
    function _ensureOfferReceived(Offer memory offer) internal view {
        for(uint i = 0; i < offer.tokens.length; i++){
            //need to make this take into account if both users have sent the same token
            require(IERC20(offer.tokens[i]).balanceOf(address(this)) == offer.amounts[i]);
        }
    }

    function makeOffer(Offer calldata offer) external {
        //kek
        //think about logic security hereee
        accepted.push(0);
        offers.push(offer);
    }

    function acceptOffer(uint offerId) external onlyOwner{
        accepted[offerId] = 1;
        secondaryParty = offers[offerId].party;
    }

    function send(uint offerId) external {
        require(msg.sender == secondaryParty);
        for(uint i = 0; i < offers[offerId].tokens.length; i++){
            IERC20(offers[offerId].tokens[i]).safeTransferFrom(msg.sender,address(this),offers[offerId].amounts[i]);
        }
        sent = 1;
    }

    function confirm(uint offerId) external onlyOwner {
        require(sent == 1);
        require(accepted[offerId] == 1);
        //transfer offer from escrow to owner
        for(uint i = 0; i < offers[offerId].tokens.length; i++){
            IERC20(offers[offerId].tokens[i]).safeTransferFrom(address(this),Ownable(this).owner(),offers[offerId].amounts[i]);
        }
        //transfer listing from escrow to winning bidder
        for(uint i = 0; i < listing.tokens.length; i++){
            IERC20(listing.tokens[i]).safeTransferFrom(address(this),secondaryParty,listing.amounts[i]); //get safetransfer
        }

    }    
}
