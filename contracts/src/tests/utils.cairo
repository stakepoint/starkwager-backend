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

pub fn ALICE() -> ContractAddress {
    'alice'.try_into().unwrap()
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

pub fn deploy_escrow(
    wager_address: ContractAddress, strk_dispatcher: IERC20Dispatcher
) -> (IEscrowDispatcher, IERC20Dispatcher) {
    let contract = declare("Escrow").unwrap().contract_class();

    let mut calldata = array![];
    strk_dispatcher.serialize(ref calldata);
    wager_address.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    (IEscrowDispatcher { contract_address }, strk_dispatcher)
}

pub fn deploy_wager(
    admin_address: ContractAddress, strk_dispatcher: IERC20Dispatcher
) -> (IStrkWagerDispatcher, ContractAddress) {
    let contract = declare("StrkWager").unwrap().contract_class();
    let mut calldata = array![];
    let strk_address = strk_dispatcher.contract_address;
    admin_address.serialize(ref calldata);
    strk_address.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IStrkWagerDispatcher { contract_address };

    (dispatcher, contract_address)
}

pub fn setup() -> (IStrkWagerDispatcher, IEscrowDispatcher, IERC20Dispatcher) {
    let strk_dispatcher = deploy_mock_erc20();

    let (wager, wager_contract) = deploy_wager(ADMIN(), strk_dispatcher);
    let (escrow, strk_dispatcher) = deploy_escrow(wager_contract, strk_dispatcher);

    (wager, escrow, strk_dispatcher)
}

pub fn create_wager(
    wager: IStrkWagerDispatcher,
    escrow: IEscrowDispatcher,
    strk_dispatcher: IERC20Dispatcher,
    deposit: u256,
    stake: u256,
) -> u64 {
    let creator = OWNER();
    let mut spy = spy_events();

    cheat_caller_address(strk_dispatcher.contract_address, creator, CheatSpan::TargetCalls(1));
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(
        escrow.contract_address, wager.contract_address
    ); // Simulate Wager Contract
    escrow.deposit_to_wallet(creator, deposit);
    stop_cheat_caller_address(escrow.contract_address);

    // Create the wager
    let title = "My Wager";
    let terms = "My terms";
    let category = Category::Sports;
    let mode = Mode::HeadToHead;

    cheat_caller_address(wager.contract_address, creator, CheatSpan::TargetCalls(1));
    let wager_id = wager.create_wager(category, title.clone(), terms.clone(), stake, mode);
    stop_cheat_caller_address(wager.contract_address);

    spy
        .assert_emitted(
            @array![
                (
                    wager.contract_address,
                    StrkWager::Event::WagerCreated(
                        StrkWager::WagerCreatedEvent {
                            wager_id, category, title, terms, creator, stake, mode,
                        }
                    )
                )
            ]
        );

    wager_id
}
