const { expect } = require("chai");
const {
    BN,
    expectEvent,
    expectRevert,
    time,
    constants,
} = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const CryptoZombies = artifacts.require("CryptoZombies");

const toWei = (value, unit) => {
    return web3.utils.toWei(value, unit);
};

const fromWei = (value, unit) => {
    return web3.utils.fromWei(value, unit);
};

contract("CryptoZombies", ([owner, other]) => {
    beforeEach(async () => {
        this.contract = await CryptoZombies.new(
            "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"
        );
    });

    it("has a name and symbol", async () => {
        const name = await this.contract.name();
        const symbol = await this.contract.symbol();
        expect(name).to.equal("CryptoZombies");
        expect(symbol).to.equal("CRZO");
    });

    it("allows to create a random zombie only once", async () => {
        const receipt = await this.contract.createRandomZombie("ZombieName", {
            from: owner,
        });
        expectEvent(receipt, "Transfer", {
            from: constants.ZERO_ADDRESS,
            to: owner,
            tokenId: new BN(0),
        });
        expectEvent(receipt, "ZombieCreated", {
            id: new BN(0),
            name: "ZombieName",
        });
        await expectRevert.unspecified(
            this.contract.createRandomZombie("ZombieName2", {
                from: owner,
            })
        );
        const balance = await this.contract.balanceOf(owner);
        expect(balance.toString()).to.equal("1");
    });

    it("zombie can feed on a kitty", async () => {
        await this.contract.createRandomZombie("ZombieName", {
            from: owner,
        });
        await time.increase(time.duration.minutes(1));
        const receipt = await this.contract.feedOnKitty(0, 0, { from: owner });
        expectEvent(receipt, "Transfer", {
            from: constants.ZERO_ADDRESS,
            to: owner,
            tokenId: new BN(1),
        });
        expectEvent(receipt, "ZombieCreated", {
            id: new BN(1),
            name: "NoName",
        });
        const balance = await this.contract.balanceOf(owner);
        expect(balance.toString()).to.equal("2");
    });

    it("zombie can attack on other zombie", async () => {
        await this.contract.createRandomZombie("OwnerZombieName", {
            from: owner,
        });
        await this.contract.createRandomZombie("OtherZombieName", {
            from: other,
        });
        await time.increase(time.duration.minutes(1));
        await expectRevert.unspecified(
            this.contract.attack(0, 0, { from: owner })
        );
        const receipt = await this.contract.attack(0, 1);
        if (receipt.logs.length > 0) {
            expectEvent(receipt, "Transfer", {
                from: constants.ZERO_ADDRESS,
                to: owner,
                tokenId: new BN(2),
            });
            expectEvent(receipt, "ZombieCreated", {
                id: new BN(2),
                name: "NoName",
            });
            const balance = await this.contract.balanceOf(owner);
            expect(balance.toString()).to.equal("2");
        }
    });

    it("allows to level up a zombie for some fee", async () => {
        await this.contract.createRandomZombie("ZombieName", {
            from: other,
        });
        await this.contract.levelUp(0, {
            from: other,
            value: toWei("0.001", "ether"),
        });
        const zombie = await this.contract.zombies(0);
        expect(zombie.level.toString()).to.equal("1");
        await expectRevert.unspecified(
            this.contract.levelUp(0, {
                from: other,
                value: toWei("0.0005", "ether"),
            })
        );
    });

    it("allows owner to view available balance", async () => {
        const balance = await this.contract.viewBalance({ from: owner });
        await expectRevert.unspecified(
            this.contract.viewBalance({ from: other })
        );
    });

    it("allows owner to withdraw", async () => {
        const balance = await this.contract.viewBalance({ from: owner });
        const receipt = await this.contract.withdraw({ from: owner });
        expectEvent(receipt, "Withdrawn", { amount: balance });
        await expectRevert.unspecified(this.contract.withdraw({ from: other }));
    });
});
