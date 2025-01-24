use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait,
};


use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};

pub fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

pub fn BOB() -> ContractAddress {
    'bob'.try_into().unwrap()
}

pub fn deploy_mock_erc20() -> IERC20Dispatcher {
    let contract = declare("MyToken").unwrap().contract_class();
    let mut calldata = array![];
    OWNER().serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    IERC20Dispatcher { contract_address }
}

pub fn deploy_escrow() -> (IEscrowDispatcher, IERC20Dispatcher) {
    let contract = declare("Escrow").unwrap().contract_class();
    let strk_dispatcher = deploy_mock_erc20();

    let mut calldata = array![];
    strk_dispatcher.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    (IEscrowDispatcher { contract_address }, strk_dispatcher)
}
