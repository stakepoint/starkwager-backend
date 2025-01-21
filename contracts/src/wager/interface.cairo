use starknet::ContractAddress;
use contracts::wager::types::{Wager, Category};

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
        stake: u256
    ) -> u64;
    fn join_wager(ref self: TContractState, wager_id: u64);
    fn get_wager(self: @TContractState, wager_id: u64) -> Wager;
    fn get_wager_participants(self: @TContractState, wager_id: u64) -> Span<ContractAddress>;
}
