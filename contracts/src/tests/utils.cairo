use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};

pub fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

pub fn BOB() -> ContractAddress {
    'bob'.try_into().unwrap()
}

pub fn MOCK_WAGER() -> ContractAddress {
    'mock_wager'.try_into().unwrap()
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
    strk_dispatcher.contract_address.serialize(ref calldata);
    MOCK_WAGER().serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    (IEscrowDispatcher { contract_address }, strk_dispatcher)

fn deploy_escrow() -> (IEscrowDispatcher, IERC20Dispatcher) {
    let mock_erc20 = deploy_mock_erc20();
    let mock_wager_address = contract_address_const::<0x123>();

    let escrow = declare('Escrow');
    let escrow_address = escrow
        .deploy(@array![mock_erc20.contract_address.into(), mock_wager_address.into()])
        .unwrap();

    (IEscrowDispatcher { contract_address: escrow_address }, mock_erc20)
}
}
