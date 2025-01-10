#[starknet::contract]
pub mod Escrow {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use contracts::escrow::interface::IEscrow;

    #[storage]
    struct Storage {
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
    }
}