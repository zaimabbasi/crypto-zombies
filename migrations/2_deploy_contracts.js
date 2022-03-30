const CryptoZombies = artifacts.require("CryptoZombies");

module.exports = (deployer) => {
    deployer.deploy(
        CryptoZombies,
        "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"
    );
};
