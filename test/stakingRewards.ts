import { expect } from 'chai';
import { ethers, } from 'hardhat';
import {Contract,providers,Wallet} from 'ethers';
import {StakingRewards__factory} from '../typechain'
describe("Staking", async () => {
   
 
    const pool_addr = '0x27397833aa781d0E4479855C2cF3A7C3E014CCd7';


    const provider:any = new ethers.providers.JsonRpcProvider(process.env.TESTNET_URL);
    const wallet:Wallet = new ethers.Wallet(`${process.env.PRIVATE_KEY}`,provider);

    const POOL:Contract = StakingRewards__factory.connect(pool_addr,wallet);

    beforeEach(async function () {
        // Get the ContractFactory and Signers here.

        // const  [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        // console.log('================ wallet address =================');
        // console.log("current owner is:",wallet.address);
        // console.log('=================================');

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
    // it("approve to pool contract",async ()=>{
    //     const amount = ethers.utils.parseEther('1000000000000');
    //     const tx = await STKLP.approve(pool_addr,amount);
    //     await tx.wait();
    //     const allowance = await STKLP.allowance(wallet.address,pool_addr);
    //     console.log('allowance amount is:',allowance);
        
    //     expect(amount).to.equal(allowance);
    
    // })

    it("get getStakedLPBlanceOf", async function () {
          const balance = await POOL.getStakedLPBlanceOf()/10**18;
          console.log(balance);
          
          expect(balance).to.equal(325);
           
        });
    
})