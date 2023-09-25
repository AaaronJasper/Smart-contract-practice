// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract mutilSignWallet{
    //接收代幣
    event Deposit(address sender, uint amount, uint balance);
    //發起交易
    event SubmitTransaction(
        address owner,
        uint txIndex,
        address to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address owner, uint txIndex);
    event RevokeConfirmation(address owner, uint txIndex);
    event ExecuteTransaction(address owner, uint txIndex);
    //交易類型
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmation;
    }
    //交易列
    Transaction [] public transactions;
    //擁有者是否確認
    mapping(uint => mapping(address => bool)) public isConfirmed;
    //擁有者列
    address[] public owners;
    //確認是否為擁有者
    mapping(address => bool) public isOwner;
    //需要簽名數
    uint public numConfirmationRequired;
    //只有擁有者可以使用
    modifier onlyOwner(){
        require(isOwner[msg.sender] == true, "Only owner can use");
        _;
    }
    //交易未確認
    modifier unconfirmed(uint _id){
        require(isConfirmed[_id][msg.sender] == false,"Transaction already confirmed");
        _;
    }
    //交易確認
    modifier confirmed(uint _id){
        require(isConfirmed[_id][msg.sender] == true,"Transaction already confirmed");
        _;
    }
    //交易未執行
    modifier unexecute(uint _id){
        require(transactions[_id].executed == false,"Transaction already executed");
        _;
    }

    constructor(address[] memory _owners,uint _ownerNum){
        require(_owners.length < _ownerNum * 2 && _ownerNum <= _owners.length,"Number should more bigger");
        for(uint i = 0; i < _owners.length; i++){
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }
        numConfirmationRequired = _ownerNum;
    }
    //接收函數
    receive()external payable{
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    //發起交易
    function submit(address _to, uint _value, bytes memory _data) public onlyOwner{
        uint txId = transactions.length;
        isConfirmed[txId][msg.sender] = true;
        Transaction memory newone = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmation: 1
        });
        transactions.push(newone);
        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
    }
    //確認交易
    function comfirm(uint _id) public onlyOwner unconfirmed(_id) unexecute(_id){
        isConfirmed[_id][msg.sender] = true;
        transactions[_id].numConfirmation += 1;
        emit ConfirmTransaction(msg.sender, _id);
    }
    //取消確認交易
    function cancel(uint _id) public onlyOwner confirmed(_id) unexecute(_id){
        isConfirmed[_id][msg.sender] = false;
        transactions[_id].numConfirmation -= 1;
        emit RevokeConfirmation(msg.sender, _id);
    }
    //執行交易
    function executeTx(uint _id) public onlyOwner unexecute(_id){
        require(transactions[_id].numConfirmation >= numConfirmationRequired,"Not enough confirmation");
        (bool success,) = payable(transactions[_id].to).call{value:transactions[_id].value}("");
        if(!success){
            revert("Not success");
        }
        transactions[_id].executed = true;
        emit ExecuteTransaction(msg.sender, _id);
    }

}