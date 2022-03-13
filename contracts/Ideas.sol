//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Ideas {

    struct Idea {
        string title;
        string concept;
        address owner;
        uint favour;
        uint against; 
        bool isPublished;
        bool closed;
    }
    mapping (uint => Idea) ideas;
    uint private ideaCount;

    modifier isIdeaOwner(uint _ideaId) {
        require(ideas[_ideaId].owner == msg.sender);
        _;
    }

    function createIdea(string memory _title, string memory _concept, bool _status) external {
        require(ideaCount <= 50, "Ideas cant exceed 50");
        ideas[ideaCount].title = _title;
        ideas[ideaCount].concept = _concept;
        ideas[ideaCount].owner = msg.sender;
        ideas[ideaCount].closed = _status;
        ideaCount += 1;
    }

    function getIdeas(uint _index) external view returns (Idea memory _idea){
        _idea = ideas[_index];
    }

    function getAllIdeas() external view returns (Idea[] memory _ideas) {
        for(uint i = 0; i < ideaCount; i++) {
            if(ideas[i].isPublished) {
                _ideas[i] = ideas[i];
            }
        }
    }
    function updateIdeaStatus(uint _ideaIndex) external isIdeaOwner(_ideaIndex) returns (bool){
        ideas[_ideaIndex].isPublished = !ideas[_ideaIndex].isPublished;
        return ideas[_ideaIndex].isPublished;
    } 
}
