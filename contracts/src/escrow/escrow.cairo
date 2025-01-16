#[starknet::contract]
pub mod Escrow {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress, get_contract_address};

    use contracts::escrow::interface::IEscrow;
    use core::num::traits::Zero;

    #[storage]
    struct Storage {
        strk_dispatcher: IERC20Dispatcher,
        user_balance: Map::<ContractAddress, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposit: DepositEvent,
        Withdraw: WithdrawEvent,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DepositEvent {
        from: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WithdrawEvent {
        to: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, strk_dispatcher: IERC20Dispatcher,) {
        self.strk_dispatcher.write(strk_dispatcher);
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
        fn deposit_to_wallet(ref self: ContractState, from: ContractAddress, amount: u256) {
            // Validate input
            assert(!from.is_zero(), 'Invalid address');
            assert(amount > 0, 'Amount must be positive');

            let strk_dispatcher = self.strk_dispatcher.read();

            // transfers funds to escrow
            strk_dispatcher.transfer_from(from, get_contract_address(), amount);
            self.user_balance.entry(from).write(amount + self.get_balance(from));
            self.emit(DepositEvent { from, amount });
        }

        fn withdraw_from_wallet(ref self: ContractState, to: ContractAddress, amount: u256) {
            let strk_dispatcher = self.strk_dispatcher.read();

            // Validate recipient address
            assert(!to.is_zero(), 'Invalid address');

            // checks if to address has enough funds
            assert(self.get_balance(to) >= amount, 'Insufficient funds');

            // update balance first to prevent reentrancy
            self.user_balance.entry(to).write(self.get_balance(to) - amount);

            // transfers funds from escrow
            strk_dispatcher.transfer(to, amount);
            self.emit(WithdrawEvent { to, amount });
        }

        fn get_balance(self: @ContractState, address: ContractAddress) -> u256 {
            self.user_balance.entry(address).read()
        }
    }
}
