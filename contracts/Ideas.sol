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
    }
    struct Vote {
        address voter;
        uint favour;
        uint against; 
        uint total;
    }
    struct Comment {
        address user;
        // string category;
        string content;
        uint256 created_at;
    }
    mapping(uint => Comment[]) private commentsByIdeaId;
    mapping(uint => Vote) votes;
    mapping (uint => Idea) ideas;
    uint32 private commentCount;
    uint private ideaCount;
    uint private voteCount;
    address[] private whitelistPlaceholder;
    // Notify users that a comment was added 
    event CommentAdded(Comment comment);
    modifier isIdeaOwner(uint _ideaId) {
        require(ideas[_ideaId].owner == msg.sender);
        _;
    }

    function createIdea(string memory _title, string memory _concept, bool _status) external {
        require(ideaCount <= 50, "Ideas cant exceed 50");
        ideas[ideaCount].title = _title;
        ideas[ideaCount].concept = _concept;
        ideas[ideaCount].owner = msg.sender;
        ideas[ideaCount].restricted = _status;
        ideaCount += 1;
    }

    function getIdea(uint _index) external view returns (Idea memory _idea){
        _idea = ideas[_index];
    }

    function getAllIdeas() external view returns (Idea[] memory _ideas) {
        for(uint i = 0; i < ideaCount; i++) {
            if(ideas[i].isPublished && !ideas[i].restricted) {
                _ideas[i] = ideas[i];
            }
        }
    }
    function updateIdeaStatus(uint _ideaIndex) external isIdeaOwner(_ideaIndex) returns (bool){
        ideas[_ideaIndex].isPublished = !ideas[_ideaIndex].isPublished;
        return ideas[_ideaIndex].isPublished;
    } 

    function vote(uint _ideaIndex, bool _vote) external {
        if(_vote) {
            
            votes[_ideaIndex].voter = msg.sender;
            votes[_ideaIndex].favour += 1;
        } else {
            votes[_ideaIndex].voter = msg.sender;
            votes[_ideaIndex].against += 1;
        }
    }

    function grantAccess(uint _ideaIndex, address _user) external isIdeaOwner(_ideaIndex) {
        ideas[_ideaIndex].whilteList.push(_user);
    }

    function revokeAccess(uint _ideaIndex, address _user) external isIdeaOwner(_ideaIndex) {
        address[] memory emptyWhitelist;
        for(uint i = 0; i < ideas[_ideaIndex].whilteList.length; i++) {
            if(ideas[_ideaIndex].whilteList[i] != _user) {
                emptyWhitelist[i] = ideas[_ideaIndex].whilteList[i];
            }
        }
        ideas[_ideaIndex].whilteList = emptyWhitelist;
    }

    function getWhitelist(uint _ideaIndex) external view returns (address[] memory _whitelist) {
        _whitelist = ideas[_ideaIndex].whilteList;
    }

    function getVotes(uint _ideaIndex) external view returns (Vote[] memory _votes) {
        for(uint i = 0; i < votes[_ideaIndex].total; i++) {
                _votes[i] = votes[i];
            
        }
    }
    // Get comments on an idea
    function getComments(uint _ideaIndex) public view returns(Comment[] memory) {
        return commentsByIdeaId[_ideaIndex];
    }

    // Persist a new comment
    function addComment(uint _ideaIndex, string calldata _content) public {
      Comment memory comment = Comment({
        user: msg.sender,
        content: _content,
        created_at: block.timestamp
    });
    commentsByIdeaId[_ideaIndex].push(comment);
    commentCount += 1;
    emit CommentAdded(comment);
  }
}
