import { ethers } from "hardhat";

async function main() {

    const [deployer] = await ethers.getSigners();
    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );
    console.log("Account balance:", (await deployer.getBalance()).toString());
    
    const amount = ethers.utils.parseEther('10000000000');//100亿

    const STKLP = await ethers.getContractFactory("STKLP");
    const tSTKLP = await STKLP.deploy(amount);

    console.log("STKLP deployed to:", tSTKLP.address);

    const balance = await tSTKLP.balanceOf(deployer.address);
    console.log("tSTKLP balanceOf is :",balance);
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
