// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

// 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
interface IKitty {
    function getKitty(uint256 _id)
        external
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );
}