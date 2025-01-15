use starknet::ContractAddress;

#[starknet::interface]
pub trait IEscrow<TContractState> {
    fn deposit_to_wallet(ref self: TContractState, user: ContractAddress, amount: u256);
    fn get_balance(self: @TContractState, user: ContractAddress) -> u256;
    fn withdraw_from_wallet(ref self: TContractState, user: ContractAddress, amount: u256);
}
