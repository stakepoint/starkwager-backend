#[starknet::contract]
pub mod Escrow {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress, get_contract_address};

    use contracts::escrow::interface::IEscrow;
    // use core::zeroable::Zeroable;
    

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
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WithdrawEvent {
        user: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, strk_dispatcher: IERC20Dispatcher,) {
        self.strk_dispatcher.write(strk_dispatcher);
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
        fn deposit_to_wallet(ref self: ContractState, user: ContractAddress, amount: u256) {

            // Validate input
            //assert(!user.is_zero(), 'Invalid user address');
            assert(amount > 0, 'Amount must be positive');

            let strk_dispatcher = self.strk_dispatcher.read();

            // transfers funds to escrow
            strk_dispatcher.transfer_from(user, get_contract_address(), amount);
            self.user_balance.entry(user).write(amount + self.get_balance(user));
            self.emit(DepositEvent { user, amount });
           
        }

        fn withdraw_from_wallet(
            ref self: ContractState, 
            user: ContractAddress, 
            recipientWallet: ContractAddress, 
            amount: u256
        ) {
            let strk_dispatcher = self.strk_dispatcher.read();

            // Validate recipient address
            //assert(!recipient_wallet.is_zero(), 'Invalid recipient address');

            // checks if user has enough funds
            assert!(self.get_balance(user) >= amount, "Insufficient funds");

            // update balance first to prevent reentrancy
            self.user_balance.entry(user).write(self.get_balance(user) - amount);

            // transfers funds from escrow
            strk_dispatcher.transfer(recipientWallet, amount);
            self.emit(WithdrawEvent { user: user, recipient: recipientWallet, amount });
        }

        fn get_balance(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_balance.entry(user).read()
        }

        fn withdraw_from_wallet(ref self: ContractState, user: ContractAddress, amount: u256) {}
    }
}
