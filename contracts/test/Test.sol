//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
contract ConstantImmutable{
    //编译后不能再修改
    string constant name ="Biden";
    //部署合约后不能再修改，而且必须在构造函数里面初始化
    uint immutable age;
    constructor(){
        age = 80;
    }
    //获取constant 变量方法必须使用 pure 修饰符
    function getName() public pure returns(string memory){
        return name;
    }

    function getAge() public view returns(uint){
        return age;
    }
}

