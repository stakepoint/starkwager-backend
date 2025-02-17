use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait, cheat_caller_address, CheatSpan,
    stop_cheat_block_timestamp
};

use contracts::wager::wager::StrkWager;
use contracts::wager::types::{Mode, Category};

use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};
use contracts::wager::interface::{IStrkWagerDispatcher, IStrkWagerDispatcherTrait};

pub fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

pub fn ADMIN() -> ContractAddress {
    'admin'.try_into().unwrap()
}

pub fn WAGER_ADDRESS() -> ContractAddress {
    'wager'.try_into().unwrap()
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

pub fn deploy_escrow(wager_address: ContractAddress) -> (IEscrowDispatcher, IERC20Dispatcher) {
    let contract = declare("Escrow").unwrap().contract_class();
    let strk_dispatcher = deploy_mock_erc20();

    let mut calldata = array![];
    strk_dispatcher.serialize(ref calldata);
    wager_address.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    (IEscrowDispatcher { contract_address }, strk_dispatcher)
}

pub fn deploy_wager(admin_address: ContractAddress) -> (IStrkWagerDispatcher, ContractAddress) {
    let contract = declare("StrkWager").unwrap().contract_class();
    let mut calldata = array![];
    admin_address.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IStrkWagerDispatcher { contract_address };

    (dispatcher, contract_address)
}

pub fn create_wager(deposit: u256, stake: u256, admin_address: ContractAddress) -> u64 {
    let (wager, wager_contract) = deploy_wager(admin_address);
    let (escrow, strk_dispatcher) = deploy_escrow(wager_contract);
    let creator = OWNER();
    let mut spy = spy_events();

    start_cheat_caller_address(wager.contract_address, admin_address);
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    cheat_caller_address(strk_dispatcher.contract_address, creator, CheatSpan::TargetCalls(1));
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_block_timestamp(strk_dispatcher.contract_address);

    start_cheat_caller_address(escrow.contract_address, wager_contract); // Simulate Wager Contract
    escrow.deposit_to_wallet(creator, deposit);

    assert(strk_dispatcher.balance_of(escrow.contract_address) == deposit, 'wrong amount');

    assert(escrow.get_balance(creator) == deposit, 'wrong balance');

    let title = "My Wager";
    let terms = "My terms";
    let category = Category::Sports;
    let mode = Mode::HeadToHead;

    println!("Creator's balance: {}", escrow.get_balance(creator));
    println!("Creator's stake: {}", stake);

    cheat_caller_address(wager_contract, creator, CheatSpan::TargetCalls(1));
    let wager_id = wager.create_wager(category, title.clone(), terms.clone(), stake, mode);
    let expected_event = StrkWager::Event::WagerCreated(
        StrkWager::WagerCreatedEvent { wager_id, category, title, terms, creator, stake, mode },
    );

    spy.assert_emitted(@array![(wager_contract, expected_event)]);

    wager_id
}
