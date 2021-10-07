// Bank.sol
// SPDX-License-Identifier: BCO
pragma solidity >=0.8.0; // J'ai mis cette version malgré la préco dans l'intitulé de l'exercice car SafeMath.sol nécessite maintenant une version 0.8.0

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    

// Définition de la structure Voter
    struct Voter { 
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

 // Définition de la struture Proposal
    struct Proposal {
        string description;
        uint voteCount;
    }

 // Définition de l'énumération WorkflowStatus, qui contient l'ensemble des statuts du système de vote
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
 // Définition des events
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    

// ************** VARIABLES ************** 

    uint winningProposalId; // Variable dans laquelle est stockée l'id du gagnant
    mapping (address => Voter) private _Voter; // whitelist de voteurs
    
    WorkflowStatus currentStatus;
    WorkflowStatus constant defaultChoice = WorkflowStatus.RegisteringVoters; // Définition du statut par défaut du système de vote
    
    address[] public VotersList; // Définition du tableau des votants
    Proposal[] private proposals; // Définition du tableau de propositions
  
    uint256 maxVoteCount = 0; 
 
 // ************** FONCTIONS ************** 
 
 // Fonction pour ouvrir le système de vote
   function registerVoters() public onlyOwner {
       currentStatus = WorkflowStatus.RegisteringVoters;
   }   

// Fonction pour ouvrir l'enregistrement des propositions
   function openProposalRegistration() public onlyOwner {
       require(currentStatus==WorkflowStatus.RegisteringVoters, "La session doit d'abord etre dans l'etat RegisteringVoters");
       currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
       emit ProposalsRegistrationStarted();
       emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters,WorkflowStatus.ProposalsRegistrationStarted);
    }

// Fonction pour clôturer l'enregistrement des propositions
    function closeProposalRegistration() public onlyOwner { 
       require(currentStatus==WorkflowStatus.ProposalsRegistrationStarted, "La session doit d'abord etre dans l'etat ProposalsRegistrationStarted");
       currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
       emit ProposalsRegistrationEnded();
       emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.ProposalsRegistrationEnded);
    }

// Fonction pour démarrer la session de votes
    function startVotingSession() public onlyOwner { 
        require(currentStatus==WorkflowStatus.ProposalsRegistrationEnded, "La session doit d'abord etre dans l'etat ProposalsRegistrationEnded");
        currentStatus = WorkflowStatus.VotingSessionStarted;
        emit VotingSessionStarted();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded,WorkflowStatus.VotingSessionStarted);
    }

// Fonction pour clôturer la session de votes
    function endVotingSession() public onlyOwner {
        require(currentStatus==WorkflowStatus.VotingSessionStarted, "La session doit d'abord etre dans l'etat VotingSessionStarted");
        currentStatus = WorkflowStatus.VotingSessionEnded;
        emit VotingSessionEnded();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted,WorkflowStatus.VotingSessionEnded);
    }
   
// Fonction pour compter le nombre de votes   
    function tallyVotes() public onlyOwner returns (Proposal memory){ 
        require(currentStatus==WorkflowStatus.VotingSessionEnded, "La session doit d'abord etre dans l'etat VotingSessionEnded");
        currentStatus = WorkflowStatus.VotesTallied;
        emit VotesTallied();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded,WorkflowStatus.VotesTallied);
        return proposals[winningProposalId];
    }
   
// Fonction qui permet de récupérer le statut courant du système de vote    
    function getCurrentStatus() public view returns (uint) { 
        return uint(currentStatus);
    }
   
// Fonction pour ajouter un votant à la whitelist
    function addVoter(address _address) public onlyOwner {
        require(currentStatus==WorkflowStatus.RegisteringVoters, "La session doit d'abord etre dans l'etat RegisteringVoters");
        require(!_Voter[_address].isRegistered, "L'adresse est deja whitelistee");
        _Voter[_address].isRegistered=true; // ajout de l'adresse en whitelist
        VotersList.push(_address);
        emit VoterRegistered(_address); // déclenchement de l'event whitelisted
    }
    
// Fonction qui permet à un votant inscrit en whitelist d'enregistrer une proposition   
   function addProposal(string memory _description) public { 
        require(_Voter[msg.sender].isRegistered, "L'adresse n'est pas en whitelist"); // Nécessité que l'utilisateur soit whitelisté
        require(currentStatus==WorkflowStatus.ProposalsRegistrationStarted, "La session d'enregistrement n'est pas active");
        Proposal memory proposal = Proposal(_description,0);
        proposals.push(proposal); 
    }
   
// Fonction qui permet à un votant inscrit en whitelist de voter    
      function addVote(uint256 _proposalId) public { 
        require(_Voter[msg.sender].isRegistered, "L'adresse n'est pas en whitelist"); // Nécessité que l'utilisateur soit whitelisté
        require(!_Voter[msg.sender].hasVoted, "L'adresse a deja vote"); // Nécessité que l'utilisateur n'ait pas encore voté
        require(currentStatus==WorkflowStatus.VotingSessionStarted, "La session de vote n'est pas encore ouverte");
        
        _Voter[msg.sender].votedProposalId=_proposalId;
        _Voter[msg.sender].hasVoted=true;
        //séparer en 2 l'assignation de la variable et le changement de valeur
        uint256 _newVoteCount;
        _newVoteCount = proposals[_proposalId].voteCount++;
        
        if(_newVoteCount > maxVoteCount) {
                maxVoteCount=_newVoteCount;
                winningProposalId=_proposalId;
        } 
    }
   
   
// ************** FONCTIONS DE CONTRÔLE **************    

// Fonction qui permet de savoir si un votant est whitelisté ou non
    function voterIsRegistered(address _address) public view returns (string memory) {
       string memory answer=""; 
        if (_Voter[_address].isRegistered==false) {
            answer = "Cette adresse n'est pas en whitelist";
        }
        else if (_Voter[_address].isRegistered==true) {
            answer = "Cette adresse est en whitelist";
        }
        return answer;
     
    }

// Fonction qui permet de récupérer les informations d'une proposition
    function getProposal(uint256 _proposalId) public view returns (Proposal memory){
        require(proposals.length>=_proposalId, "La proposition que vous avez demandee n'existe pas");
        return proposals[_proposalId];
    }

// Fonction qui permet de récupérer les le vote d'une adresse
    function getVote(address _address) public view returns (uint){ // à refaire
        return _Voter[_address].votedProposalId;
    }

// Fonction qui permet de savoir si une adresse a déjà voté ou non  
   function getHasVoted() public view returns (bool){
      return _Voter[msg.sender].hasVoted;
   } 

    
}
