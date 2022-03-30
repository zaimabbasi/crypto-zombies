// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IKitty.sol";


contract CryptoZombies is ERC721, Ownable {
    // state variables
    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint cooldownTime = 1 minutes;  // later: change that to 1 days
    struct Zombie {
        string name;
        uint dna;
        uint level;
        uint readyTime;
        uint winCount;
        uint lossCount;
    }
    Zombie[] public zombies;
    IKitty kittyContract;
    uint zombieAttackWinProbability = 70;
    uint randomNonce = 0;
    uint levelUpFee = 0.001 ether;

    // constructor
    constructor(address _kittyAddress) ERC721("CryptoZombies", "CRZO") {
        kittyContract = IKitty(_kittyAddress);
    }

    // events
    event ZombieCreated(uint id, string name, uint dna);
    event Withdrawn(uint amount);

    // modifiers
    modifier aboveLevel(uint _level, uint _zombieId) {
        require(zombies[_zombieId].level >= _level);
        _;
    }

    // external functions
    function setKittyContractAddress(address _kittyAddress) external onlyOwner {
        kittyContract = IKitty(_kittyAddress);
    }

    function setLevelUpFee(uint _fee) external onlyOwner {
        levelUpFee = _fee;
    }

    function getLevelUpFee() external view returns (uint) {
        return levelUpFee;
    }

    function withdraw() external payable onlyOwner {
        uint amount = address(this).balance;
        payable(owner()).transfer(amount);
        emit Withdrawn(amount);
    }

    function viewBalance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function levelUp(uint _zombieId) external payable {
        require(msg.value == levelUpFee);
        zombies[_zombieId].level++;
    }

    function changeName(uint _zombieId, string memory _newName) external aboveLevel(2, _zombieId) {
        require(msg.sender == ownerOf(_zombieId));
        zombies[_zombieId].name = _newName;
    }

    function changDna(uint _zombieId, uint _newDna) external aboveLevel(20, _zombieId) {
        require(msg.sender == ownerOf(_zombieId));
        _newDna = _newDna % dnaModulus;
        zombies[_zombieId].dna = _newDna;
    }

    function getZombiesByOwner(address _owner) external view returns (uint[] memory) {
        uint[] memory ownerZombies = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < zombies.length; i++) {
            if (_owner == ownerOf(i)) {
                ownerZombies[counter] = i;
                counter++;
            }
        }
        return ownerZombies;
    }

    // public functions
    function createRandomZombie(string memory _name) public {
        require(balanceOf(msg.sender) == 0);
        uint randomDna = _generateRandomDna(_name);
        _createZombie(_name, randomDna);
    }

    function feedOnKitty(uint _zombieId, uint _kittyId) public {
        uint genes;
        (,,,,,,,,,genes) = kittyContract.getKitty(_kittyId);
        _feedAndMultiply(_zombieId, genes, "kitty");
    }

    function attack(uint _zombieId, uint _targetId) public {
        require(msg.sender == ownerOf(_zombieId));
        require(msg.sender != ownerOf(_targetId));
        Zombie storage ownerZombie = zombies[_zombieId];
        Zombie storage enemyZombie = zombies[_targetId];
        uint randomMod = _generateRandomMod(100);
        if (randomMod <= zombieAttackWinProbability) {
            _feedAndMultiply(_zombieId, enemyZombie.dna, "zombie");
            ownerZombie.level++;
            ownerZombie.winCount++;
            enemyZombie.lossCount++;
        }
        else {
            _triggerCooldown(ownerZombie);
            enemyZombie.winCount++;
            ownerZombie.lossCount++;
        }
    }

    // internal functions
    function _createZombie(string memory _name, uint _dna) internal {
        Zombie memory newZombie = Zombie(_name, _dna, 0, block.timestamp + cooldownTime, 0, 0);
        zombies.push(newZombie);
        uint zombieId = zombies.length - 1;
        _safeMint(msg.sender, zombieId);
        emit ZombieCreated(zombieId, _name, _dna);
    }

    function _feedAndMultiply(uint _zombieId, uint _targetDna, string memory _species) internal {
        require(msg.sender == ownerOf(_zombieId));
        require(_isReady(_zombieId));
        _targetDna = _targetDna % dnaModulus;
        Zombie storage zombie = zombies[_zombieId];
        uint newDna = (zombie.dna + _targetDna) / 2;
        if (keccak256(abi.encodePacked(_species)) == keccak256(abi.encodePacked("kitty"))) {
            newDna = newDna - newDna % 100 + 99;
        }
        _createZombie("NoName", newDna);
        _triggerCooldown(zombie);
    }

    function _triggerCooldown(Zombie storage _zombie) internal {
        _zombie.readyTime = block.timestamp + cooldownTime;
    }

    // private functions
    function _generateRandomDna(string memory _str) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(_str))) % dnaModulus;
    }

    function _isReady(uint _zombieId) private view returns (bool) {
        return (zombies[_zombieId].readyTime <= block.timestamp);
    }

    function _generateRandomMod(uint _modulus) private returns (uint) {
        randomNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce))) % _modulus;
    }
}
