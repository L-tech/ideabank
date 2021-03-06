//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Ideas {

    struct Idea {
        string title;
        string concept;
        address owner;
        bool isPublished;
        bool restricted;
        address[] whilteList;
        string[] tags;
        address[] favour;
        address[] against;
        address[] collaborators;
        uint tip;
    }
    enum Vote {
        For,
        Against
    }
    Vote public vote;
    struct Review {
        address user;
        // string category;
        string content;
        uint256 created_at;
    }
    struct QnA {
        uint _ideaIndex;
        address user;
        string question;
        uint256 created_at;
        string answer;
    }
    mapping(uint => QnA) public qnas;
    mapping(uint => Review[]) private reviewsByIdeaId;
    mapping(uint => Vote) votes;
    mapping (uint => Idea) ideas;
    uint32 private reviewsCount;
    uint private ideaCount;
    uint private qnaCount;
    address[] private whitelistPlaceholder;
    // Notify users that a Review was added 
    event ReviewAdded(Review Review);
    event ideaTipped(uint indexed _ideaIndex, address indexed _sender, uint _amount);

    modifier isIdeaOwner(uint _ideaId) {
        require(ideas[_ideaId].owner == msg.sender);
        _;
    }
    modifier onlyCollaborator(uint _ideaId) {
        bool isCollaborator = false;
        for(uint i = 0; i < ideas[_ideaId].collaborators.length; i++) {
            if(ideas[_ideaId].collaborators[i] == msg.sender) {
                isCollaborator = true;
            }
        }
        require(isCollaborator, "Only collaborators can perform this action");
        _;

    }

    // Create a new idea
    function createIdea(string memory _title, string memory _concept, string[] memory _tags, bool _status) external {
        require(ideaCount <= 50, "Ideas cant exceed 50");
        ideas[ideaCount].title = _title;
        ideas[ideaCount].concept = _concept;
        ideas[ideaCount].owner = msg.sender;
        ideas[ideaCount].restricted = _status;
        ideas[ideaCount].tags = _tags;
        ideas[ideaCount].collaborators.push(msg.sender);
        ideaCount += 1;
    }

    // Fetch a given idea
    function getIdea(uint _index) external view returns (Idea memory _idea){
        _idea = ideas[_index];
    }

    // Fetch all ideas
    function getAllIdeas() external view returns (Idea[] memory _ideas) {
        for(uint i = 0; i < ideaCount; i++) {
            if(ideas[i].isPublished && !ideas[i].restricted) {
                _ideas[i] = ideas[i];
            }
        }
    }

    // Moved idea from draft to published

    function updateIdeaStatus(uint _ideaIndex) external isIdeaOwner(_ideaIndex) returns (bool){
        ideas[_ideaIndex].isPublished = !ideas[_ideaIndex].isPublished;
        return ideas[_ideaIndex].isPublished;
    }

    // Vote on an idea
    function voteIdea(uint _ideaIndex, Vote _vote) external {
        if(_vote == Vote.For) {
            ideas[_ideaIndex].favour.push(msg.sender);
        } else if(_vote == Vote.Against) {
            ideas[_ideaIndex].against.push(msg.sender);
        }

    }

    // Get Votes on an idea
    function getVotes(uint _ideaIndex) external view returns (uint _for, uint _against) {
        _for = ideas[_ideaIndex].favour.length;
        _against = ideas[_ideaIndex].against.length;
    }

    // Whitelist idea contributors
    function grantAccess(uint _ideaIndex, address _user) external isIdeaOwner(_ideaIndex) {
        ideas[_ideaIndex].whilteList.push(_user);
    }

    // Add Colloborator

    function addCollaborator(uint _ideaIndex, address _user) external isIdeaOwner(_ideaIndex) {
        ideas[_ideaIndex].collaborators.push(_user);
    }

    // Revoke whitelist 
    function revokeAccess(uint _ideaIndex, address _user) external isIdeaOwner(_ideaIndex) {
        address[] memory emptyWhitelist;
        for(uint i = 0; i < ideas[_ideaIndex].whilteList.length; i++) {
            if(ideas[_ideaIndex].whilteList[i] != _user) {
                emptyWhitelist[i] = ideas[_ideaIndex].whilteList[i];
            }
        }
        ideas[_ideaIndex].whilteList = emptyWhitelist;
    }

    // Get all whitelisted users
    function getWhitelist(uint _ideaIndex) external view returns (address[] memory _whitelist) {
        _whitelist = ideas[_ideaIndex].whilteList;
    }

    // Get reviews on an idea
    function getReviews(uint _ideaIndex) public view returns(Review[] memory) {
        return reviewsByIdeaId[_ideaIndex];
    }

    // Add a new Review
    function addReview(uint _ideaIndex, string calldata _content) public {
        Review memory review = Review({
            user: msg.sender,
            content: _content,
            created_at: block.timestamp
        });
        reviewsByIdeaId[_ideaIndex].push(review);
        reviewsCount += 1;
        emit ReviewAdded(review);
    }
    // Ask a question
    function askQuestion(uint _ideaIndex, string memory _question) external isIdeaOwner(_ideaIndex) {
        QnA memory qna = QnA({
            _ideaIndex: _ideaIndex,
            user: msg.sender,
            question: _question,
            created_at: block.timestamp,
            answer: ""
        });
        qnaCount += 1;
        qnas[qnaCount] = qna;
    }
    // Answer a question
    function answerQuestion(uint _ideaIndex, uint _qnaIndex, string memory _answer) external onlyCollaborator(_ideaIndex) {
        qnas[_qnaIndex].answer = _answer;
    }
    // Get all questions and answers
    function getQnAs(uint _ideaIndex) external view returns (QnA[] memory _qnas) {
        for(uint i = 0; i < qnaCount; i++) {
            if(qnas[i]._ideaIndex == _ideaIndex) {
                _qnas[i] = qnas[i];
            }
        }
    }

    // tip an idea initiator
    function tipIdea(uint _ideaIndex) external payable {
        require(msg.value >= 0, "Amount must be greater than 0");
        address payable owner = payable(ideas[_ideaIndex].owner);
        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        ideas[_ideaIndex].tip += msg.value;
        emit ideaTipped(_ideaIndex, msg.sender, msg.value);
    }

}
