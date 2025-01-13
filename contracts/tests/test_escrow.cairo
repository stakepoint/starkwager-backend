use starknet::ContractAddress;

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};


use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};

fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn BOB() -> ContractAddress {
    'bob'.try_into().unwrap()
}


fn deploy_mock_erc20() -> IERC20Dispatcher {
    let contract = declare("MyToken").unwrap().contract_class();
    let mut calldata = array![];
    OWNER().serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    IERC20Dispatcher { contract_address }
}

fn deploy_escrow() -> (IEscrowDispatcher, IERC20Dispatcher) {
    let contract = declare("Escrow").unwrap().contract_class();
    let strk_dispatcher = deploy_mock_erc20();

    let mut calldata = array![];
    strk_dispatcher.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    (IEscrowDispatcher { contract_address }, strk_dispatcher)
}

#[test]
fn test_deposit_to_wallet() {
    let (escrow, strk_dispatcher) = deploy_escrow();

    let amount = 50_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet
    escrow.deposit_to_wallet(OWNER(), amount);

    assert(strk_dispatcher.balance_of(escrow.contract_address) == amount, 'wrong amount');
    assert(escrow.get_balance(OWNER()) == amount, 'wrong balance');
}

