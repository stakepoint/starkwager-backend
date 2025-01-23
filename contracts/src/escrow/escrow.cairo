#[starknet::contract]
pub mod Escrow {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress, get_contract_address};

    use contracts::escrow::interface::IEscrow;
    use core::num::traits::Zero;

    const WAGER_ROLE: felt252 = selector!("WAGER_ROLE");

    component!(path: AccessControlComponent, storage: access_control, event: AccessControlEvent);

    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;

    #[storage]
    struct Storage {
        strk_dispatcher: IERC20Dispatcher,
        user_balance: Map::<ContractAddress, u256>,
        #[substorage(v0)]
        access_control: AccessControlComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposit: DepositEvent,
        Withdraw: WithdrawEvent,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event
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
    fn constructor(ref self: ContractState, strk_dispatcher: IERC20Dispatcher, wager_contract: ContractAddress) {
        self.strk_dispatcher.write(strk_dispatcher);
        self.access_control.initializer();
        self.access_control._grant_role(WAGER_ROLE, wager_contract);
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
        fn deposit_to_wallet(ref self: ContractState, from: ContractAddress, amount: u256) {
            self.access_control.assert_only_role(WAGER_ROLE);
            
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
            self.access_control.assert_only_role(WAGER_ROLE);

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
            self.access_control.assert_only_role(WAGER_ROLE);
            self.user_balance.entry(address).read()
        }
    }
}

