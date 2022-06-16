import { expect } from 'chai';
import { ethers, } from 'hardhat';
import {Contract,providers,Wallet} from 'ethers';
import {STKLP__factory,STKR__factory} from '../typechain'
describe("TOKENS", async () => {
   
    const STKLP_addr:string = '0x8E629Bd6406a01c3A1d1f8E1c13BaAB29441D3e8';
    const STKR_addr:string = '0x0BC7150abA29562C8B09F49A9E0D2F85B71e2D8d';
    // const STAKING_addr:string = '0xA8C028eaD6E91326FE28476Ee502ab14aC31dA6B';
    const pool_addr = '0x39178007cCb2701C3b740aB23D3ecc7Af7E989fe';


    const provider:any = new ethers.providers.JsonRpcProvider(process.env.TESTNET_URL);
    const wallet:Wallet = new ethers.Wallet(`${process.env.PRIVATE_KEY}`,provider);

    const STKLP:Contract = STKLP__factory.connect(STKLP_addr,wallet);
    const STKR:Contract = STKR__factory.connect(STKR_addr,wallet);

    beforeEach(async function () {
        // Get the ContractFactory and Signers here.

        // const  [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        // console.log('================ wallet address =================');
        // console.log("current owner is:",wallet.address);
        // console.log('=================================');

    });
    it("get tokens balanceOf", async function () {
        const balanceOf = await STKLP.balanceOf(wallet.address)/10**18;
        console.log('owner STKLP  balanceOf is:',balanceOf);

        const balanceOf2 = await STKR.balanceOf(wallet.address)/10**18;
        console.log('owner STKR balanceOf is:',balanceOf2);

        
        // expect(balanceOf).to.equal(totalSupply);
    });
    // it("transfer STKLP to pool", async function () {
    //     const amount = ethers.utils.parseEther('100000');
    //     const tx = await STKLP.transfer(pool_addr,amount);
    //     console.log('STKLP token transtion hash:',tx.hash);
    //     await tx.wait();

    //     const STKLP_balanceOf_pool = await STKLP.balanceOf(pool_addr)/10**18;
    //     console.log('STKLP token STKLP_balanceOf_pool balance of is:',STKLP_balanceOf_pool);

    //     expect(STKLP_balanceOf_pool).to.equal(amount);
       
    // });

    // it("transfer STKR to pool", async function () {
    //     const amount = ethers.utils.parseEther('100000');
    //     const tx = await STKR.transfer(pool_addr,amount);
    //     await tx.wait();
    //     console.log('STKR token transtion hash:',tx.hash);

    //     let balanceOf_pool = await STKR.balanceOf(pool_addr);
    //     balanceOf_pool /=10**18;

    //     console.log('STKR token balanceOf_pool balance of is:',balanceOf_pool);

    //     expect(balanceOf_pool).to.equal(amount);
       
    // });
    it("approve to pool contract",async ()=>{

        console.log('address wallet :',wallet.address);
        
        
        const amount = ethers.utils.parseEther('1000000000000');
        const tx = await STKLP.approve(pool_addr,amount);
        await tx.wait();
        const allowance = await STKLP.allowance(wallet.address,pool_addr);
        console.log('allowance amount is:',allowance);
        
        expect(amount).to.equal(allowance);
    
    })
    
})