use starknet::ContractAddress;

#[starknet::interface]
pub trait IEscrow<TContractState> {
    fn deposit_to_wallet(ref self: TContractState, from: ContractAddress, amount: u256);
    fn get_balance(self: @TContractState, address: ContractAddress) -> u256;
    fn withdraw_from_wallet(ref self: TContractState, to: ContractAddress, amount: u256);
    fn set_escrow_address(ref self: TContractState, new_address: ContractAddress);
    fn get_escrow_address(self: @TContractState) -> ContractAddress;
}
