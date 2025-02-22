use starknet::ContractAddress;
use contracts::wager::types::{Wager, Category, Mode};

#[starknet::interface]
pub trait IStrkWager<TContractState> {
    fn fund_wallet(ref self: TContractState, amount: u256);
    fn withdraw_from_wallet(ref self: TContractState, amount: u256);
    fn get_balance(self: @TContractState, address: ContractAddress) -> u256;

    fn create_wager(
        ref self: TContractState,
        category: Category,
        title: ByteArray,
        terms: ByteArray,
        stake: u256,
        mode: Mode,
    ) -> u64;
    fn join_wager(ref self: TContractState, wager_id: u64);
    fn get_wager(self: @TContractState, wager_id: u64) -> Wager;
    fn get_wager_participants(self: @TContractState, wager_id: u64) -> Span<ContractAddress>;
    fn set_escrow_address(ref self: TContractState, new_address: ContractAddress);
    fn get_escrow_address(self: @TContractState) -> ContractAddress;
    fn resolve_wager(ref self: TContractState, wager_id: u64, winner: ContractAddress);
    fn is_wager_participant(self: @TContractState, wager_id: u64, caller: ContractAddress) -> bool;
}
