// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Crowdfunding {
    // Struct to represent a campaign
    struct Campaign {
        string title;
        string description;
        address payable benefactor;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        bool ended;
    }

    // Array to store all campaigns
    Campaign[] public campaigns;

    // Contract owner
    address public owner;

    // Events
    event CampaignCreated(uint256 campaignId, string title, address benefactor, uint256 goal);
    event DonationReceived(uint256 campaignId, address donor, uint256 amount);
    event CampaignEnded(uint256 campaignId, uint256 amountRaised, bool goalReached);

    // Modifier to restrict access to only the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to create a new campaign
    function createCampaign(
        string memory _title,
        string memory _description,
        address payable _benefactor,
        uint256 _goal,
        uint256 _duration
    ) public {
        require(_goal > 0, "Goal must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");

        uint256 deadline = block.timestamp + _duration;
        
        campaigns.push(Campaign({
            title: _title,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            ended: false
        }));

        emit CampaignCreated(campaigns.length - 1, _title, _benefactor, _goal);
    }

    // Function to donate to a campaign
    function donate(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Donation amount must be greater than zero");
        require(!campaign.ended, "Campaign has already ended");

        campaign.amountRaised += msg.value;

        emit DonationReceived(_campaignId, msg.sender, msg.value);

        if (campaign.amountRaised >= campaign.goal) {
            endCampaign(_campaignId);
        }
    }

    // Function to end a campaign and transfer funds
    function endCampaign(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline || campaign.amountRaised >= campaign.goal, "Campaign cannot be ended yet");
        require(!campaign.ended, "Campaign has already ended");

        campaign.ended = true;
        bool goalReached = campaign.amountRaised >= campaign.goal;

        // Transfer funds to the benefactor
        (bool success, ) = campaign.benefactor.call{value: campaign.amountRaised}("");
        require(success, "Transfer to benefactor failed");

        emit CampaignEnded(_campaignId, campaign.amountRaised, goalReached);
    }

    // Function to get campaign details
    function getCampaign(uint256 _campaignId) public view returns (
        string memory title,
        string memory description,
        address benefactor,
        uint256 goal,
        uint256 deadline,
        uint256 amountRaised,
        bool ended
    ) {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.title,
            campaign.description,
            campaign.benefactor,
            campaign.goal,
            campaign.deadline,
            campaign.amountRaised,
            campaign.ended
        );
    }

    // Function to get the total number of campaigns
    function getCampaignCount() public view returns (uint256) {
        return campaigns.length;
    }

    // Function for the contract owner to withdraw any leftover funds
    function withdrawLeftoverFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
