#[starknet::contract]
pub mod Escrow {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::access::accesscontrol::AccessControlComponent; // Import AccessControl
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
        access_control: AccessControlComponent::Storage, // Add AccessControl storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposit: DepositEvent,
        Withdraw: WithdrawEvent,
        RoleGranted: RoleGrantedEvent, // Event for role granting
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

    #[derive(Drop, starknet::Event)]
    pub struct RoleGrantedEvent {
        role: felt252,
        account: ContractAddress,
    }

    // Define the WAGER_ROLE as a constant felt252 value
    const WAGER_ROLE: felt252 = 0x57414745525f524f4c45; // Unique identifier for the role

    #[constructor]
    fn constructor(ref self: ContractState, strk_dispatcher: IERC20Dispatcher, wager_contract: ContractAddress) {
        self.strk_dispatcher.write(strk_dispatcher);

        // Initialize AccessControl
        AccessControlComponent::initializer(ref self.access_control);

        // Grant WAGER_ROLE to the Wager Contract
        AccessControlComponent::grant_role(ref self.access_control, WAGER_ROLE, wager_contract);

        // Emit RoleGranted event
        self.emit(RoleGrantedEvent { role: WAGER_ROLE, account: wager_contract });
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
        // Restrict to WAGER_ROLE
        fn deposit_to_wallet(ref self: ContractState, from: ContractAddress, amount: u256) {
            // Ensure only Wager Contract can call this function
            AccessControlComponent::assert_only_role(ref self.access_control, WAGER_ROLE);

            // Validate input
            assert(!from.is_zero(), 'Invalid address');
            assert(amount > 0, 'Amount must be positive');

            let strk_dispatcher = self.strk_dispatcher.read();

            // Transfers funds to escrow
            strk_dispatcher.transfer_from(from, get_contract_address(), amount);
            self.user_balance.entry(from).write(amount + self.get_balance(from));
            self.emit(DepositEvent { from, amount });
        }

        // Restrict to WAGER_ROLE
        fn withdraw_from_wallet(ref self: ContractState, to: ContractAddress, amount: u256) {
            // Ensure only Wager Contract can call this function
            AccessControlComponent::assert_only_role(ref self.access_control, WAGER_ROLE);

            let strk_dispatcher = self.strk_dispatcher.read();

            // Validate recipient address
            assert(!to.is_zero(), 'Invalid address');

            // Check if the address has enough funds
            assert(self.get_balance(to) >= amount, 'Insufficient funds');

            // Update balance first to prevent reentrancy
            self.user_balance.entry(to).write(self.get_balance(to) - amount);

            // Transfers funds from escrow
            strk_dispatcher.transfer(to, amount);
            self.emit(WithdrawEvent { to, amount });
        }

        // Restrict to WAGER_ROLE
        fn get_balance(self: @ContractState, address: ContractAddress) -> u256 {
            // Ensure only Wager Contract can call this function
            AccessControlComponent::assert_only_role(ref self.access_control, WAGER_ROLE);

            self.user_balance.entry(address).read()
        }
    }
}
