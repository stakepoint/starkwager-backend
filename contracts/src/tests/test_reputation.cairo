use starknet::{ContractAddress, get_block_timestamp};

use contracts::wager::wager::StrkWager;
use contracts::wager::types::{Category, Mode, Claim, WagerState, AchievementType, UserStats};
use contracts::wager::interface::{IStrkWagerDispatcherTrait};
use contracts::escrow::interface::IEscrowDispatcherTrait;
use contracts::tests::utils::{OWNER, ADMIN, ALICE, BOB, setup, create_head_to_head_wager};
use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;

use snforge_std::{
    EventSpyAssertionsTrait, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    start_cheat_block_timestamp, stop_cheat_block_timestamp, cheat_caller_address, CheatSpan
};

#[test]
fn test_get_user_stats_new_user() {
    let (wager, _, _) = setup();

    let stats = wager.get_user_stats(ALICE());

    // New user should have all stats at zero
    assert(stats.total_wagers_created == 0, 'Wrong created count');
    assert(stats.total_wagers_joined == 0, 'Wrong joined count');
    assert(stats.total_wins == 0, 'Wrong wins count');
    assert(stats.total_losses == 0, 'Wrong losses count');
    assert(stats.current_win_streak == 0, 'Wrong current streak');
    assert(stats.best_win_streak == 0, 'Wrong best streak');
    assert(stats.total_volume_wagered == 0, 'Wrong volume');
    assert(stats.total_winnings == 0, 'Wrong winnings');
    assert(stats.accuracy_percentage == 0, 'Wrong accuracy');
}

#[test]
fn test_create_wager_updates_stats() {
    let (wager, escrow, strk_dispatcher) = setup();
    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let resolution_time = get_block_timestamp() + 100;

    // Create wager
    let _wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, stake, stake, resolution_time
    );

    let stats = wager.get_user_stats(OWNER());
    assert(stats.total_wagers_created == 1, 'Wrong created count');
    assert(stats.total_volume_wagered == stake, 'Wrong volume');

    // Check StatsUpdatedEvent was emitted
    spy
        .assert_emitted(
            @array![
                (
                    wager.contract_address,
                    StrkWager::Event::StatsUpdated(
                        StrkWager::StatsUpdatedEvent { user: OWNER(), new_stats: stats }
                    )
                )
            ]
        );
}

#[test]
fn test_join_wager_updates_stats() {
    let (wager, escrow, strk_dispatcher) = setup();
    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let resolution_time = get_block_timestamp() + 100;

    // Create wager
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, stake, stake, resolution_time
    );

    let bob = BOB();

    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the wallet of the participant
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, bob);
    wager.join_wager(wager_id, Claim::No);
    stop_cheat_caller_address(wager.contract_address);

    let stats = wager.get_user_stats(bob);
    assert(stats.total_wagers_joined == 1, 'Wrong joined count');
    assert(stats.total_volume_wagered == stake, 'Wrong volume');
}

#[test]
fn test_first_wager_achievement() {
    let (wager, escrow, strk_dispatcher) = setup();
    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let resolution_time = get_block_timestamp() + 100;

    // Create wager
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, stake, stake, resolution_time
    );

    // Check FirstWager achievement was earned
    assert(wager.has_achievement(OWNER(), AchievementType::FirstWager), 'FirstWager not earned');

    let achievements = wager.get_user_achievements(OWNER());
    assert(achievements.len() == 1, 'Wrong achievement count');

    // Check AchievementEarnedEvent was emitted
    spy
        .assert_emitted(
            @array![
                (
                    wager.contract_address,
                    StrkWager::Event::AchievementEarned(
                        StrkWager::AchievementEarnedEvent {
                            user: OWNER(),
                            achievement_type: AchievementType::FirstWager,
                            wager_id,
                            earned_at: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_first_join_achievement() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let resolution_time = get_block_timestamp() + 100;

    // Create wager
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, stake, stake, resolution_time
    );

    let bob = BOB();

    // Setup BOB to join
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    wager.join_wager(wager_id, Claim::No);
    stop_cheat_caller_address(wager.contract_address);

    // Check FirstJoin achievement was earned
    assert(wager.has_achievement(bob, AchievementType::FirstJoin), 'FirstJoin not earned');
}

#[test]
fn test_high_staker_achievement() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // High stake (1000+ STRK)
    let high_stake = 1000_u256;
    let resolution_time = get_block_timestamp() + 100;

    // Create high-stake wager
    let _wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, high_stake, high_stake, resolution_time
    );

    // Check HighStaker achievement was earned
    assert(wager.has_achievement(OWNER(), AchievementType::HighStaker), 'HighStaker not earned');
}

#[test]
fn test_win_resolution_updates_stats() {
    let (wager, escrow, strk_dispatcher) = setup();

    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let resolution_time = get_block_timestamp() + 100;
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, stake, stake, resolution_time
    );

    let bob = BOB();

    // Setup BOB to join
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    wager.join_wager(wager_id, Claim::No);
    stop_cheat_caller_address(wager.contract_address);

    // Simulate consensus outcome resolution
    start_cheat_block_timestamp(wager.contract_address, resolution_time + 1);

    start_cheat_caller_address(wager.contract_address, bob);
    wager.submit_outcome(wager_id, false); // Bob votes false (matches his claim)
    stop_cheat_caller_address(wager.contract_address);

    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.submit_outcome(wager_id, false); // Owner also votes false (consensus)
    stop_cheat_caller_address(wager.contract_address);

    stop_cheat_block_timestamp(wager.contract_address);

    // Check BOB's stats (winner)
    let bob_stats = wager.get_user_stats(bob);
    assert(bob_stats.total_wins == 1, 'Wrong wins count');
    assert(bob_stats.current_win_streak == 1, 'Wrong win streak');
    assert(bob_stats.best_win_streak == 1, 'Wrong best streak');
    assert(bob_stats.total_winnings == stake * 2, 'Wrong winnings'); // Gets both stakes
    assert(bob_stats.accuracy_percentage == 100, 'Wrong accuracy'); // 1 win, 0 losses = 100%

    // Check OWNER's stats (loser)
    let owner_stats = wager.get_user_stats(OWNER());
    assert(owner_stats.total_losses == 1, 'Wrong losses count');
    assert(owner_stats.current_win_streak == 0, 'Win streak not reset');
    assert(owner_stats.accuracy_percentage == 0, 'Wrong accuracy'); // 0 wins, 1 loss = 0%

    // Check FirstWin achievement for BOB
    assert(wager.has_achievement(bob, AchievementType::FirstWin), 'FirstWin not earned');
}

#[test]
fn test_win_streak_achievements() {
    let (wager, escrow, strk_dispatcher) = setup();

    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let alice = ALICE();

    // Create multiple wagers and have ALICE win them all to build a streak
    let mut i = 0;
    while i < 5 {
        let resolution_time = get_block_timestamp() + 100 + i;

        // Create wager with OWNER
        let wager_id = create_head_to_head_wager(
            wager, escrow, strk_dispatcher, stake, stake, resolution_time
        );

        // Setup ALICE to join
        start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
        strk_dispatcher.transfer(alice, stake);
        stop_cheat_caller_address(strk_dispatcher.contract_address);

        start_cheat_caller_address(strk_dispatcher.contract_address, alice);
        strk_dispatcher.approve(escrow.contract_address, stake);
        stop_cheat_caller_address(strk_dispatcher.contract_address);

        start_cheat_caller_address(wager.contract_address, alice);
        wager.fund_wallet(stake);
        wager.join_wager(wager_id, Claim::No);
        stop_cheat_caller_address(wager.contract_address);

        // Resolve in ALICE's favor
        start_cheat_block_timestamp(wager.contract_address, resolution_time + 1);

        start_cheat_caller_address(wager.contract_address, alice);
        wager.submit_outcome(wager_id, false);
        stop_cheat_caller_address(wager.contract_address);

        start_cheat_caller_address(wager.contract_address, OWNER());
        wager.submit_outcome(wager_id, false);
        stop_cheat_caller_address(wager.contract_address);

        stop_cheat_block_timestamp(wager.contract_address);

        i += 1;
    };

    // Check ALICE earned WinStreak5 achievement
    assert(wager.has_achievement(alice, AchievementType::WinStreak5), 'WinStreak5 not earned');

    let alice_stats = wager.get_user_stats(alice);
    assert(alice_stats.current_win_streak == 5, 'Wrong win streak');
    assert(alice_stats.best_win_streak == 5, 'Wrong best streak');
}

#[test]
fn test_quick_winner_achievement() {
    let (wager, escrow, strk_dispatcher) = setup();

    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let resolution_time = get_block_timestamp() + 3600; // 1 hour from now
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, stake, stake, resolution_time
    );

    let bob = BOB();

    // Setup BOB to join
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    wager.join_wager(wager_id, Claim::No);
    stop_cheat_caller_address(wager.contract_address);

    // Resolve quickly (within 24 hours of creation)
    start_cheat_block_timestamp(wager.contract_address, resolution_time + 1);

    start_cheat_caller_address(wager.contract_address, bob);
    wager.submit_outcome(wager_id, false);
    stop_cheat_caller_address(wager.contract_address);

    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.submit_outcome(wager_id, false);
    stop_cheat_caller_address(wager.contract_address);

    stop_cheat_block_timestamp(wager.contract_address);

    // Check QuickWinner achievement for BOB
    assert(wager.has_achievement(bob, AchievementType::QuickWinner), 'QuickWinner not earned');
}

// TODO: Fix prediction achievement
// #[test]
// fn test_accurate_prediction_achievement() {
//     let (wager, escrow, strk_dispatcher) = setup();

//     start_cheat_caller_address(wager.contract_address, ADMIN());
//     wager.set_escrow_address(escrow.contract_address);
//     stop_cheat_caller_address(wager.contract_address);

//     let stake = 100_u256;
//     let alice = ALICE();

//     // Create 10 wagers, ALICE wins 8 (80% accuracy)
//     let mut i = 0;
//     while i < 10 {
//         let resolution_time = get_block_timestamp() + 100 + i;

//         let wager_id = create_head_to_head_wager(
//             wager, escrow, strk_dispatcher, stake, stake, resolution_time
//         );

//         // Setup ALICE to join
//         start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
//         strk_dispatcher.transfer(alice, stake);
//         stop_cheat_caller_address(strk_dispatcher.contract_address);

//         start_cheat_caller_address(strk_dispatcher.contract_address, alice);
//         strk_dispatcher.approve(escrow.contract_address, stake);
//         stop_cheat_caller_address(strk_dispatcher.contract_address);

//         start_cheat_caller_address(wager.contract_address, alice);
//         wager.fund_wallet(stake);
//         wager.join_wager(wager_id, Claim::No);
//         stop_cheat_caller_address(wager.contract_address);

//         start_cheat_block_timestamp(wager.contract_address, resolution_time + 1);

//         // ALICE wins first 8, loses last 2
//         let alice_wins = i < 8;
//         let outcome = if alice_wins {
//             false
//         } else {
//             true
//         };

//         start_cheat_caller_address(wager.contract_address, alice);
//         wager.submit_outcome(wager_id, outcome);
//         stop_cheat_caller_address(wager.contract_address);

//         start_cheat_caller_address(wager.contract_address, OWNER());
//         wager.submit_outcome(wager_id, outcome);
//         stop_cheat_caller_address(wager.contract_address);

//         stop_cheat_block_timestamp(wager.contract_address);

//         let alice_stats = wager.get_user_stats(alice);
//         println!(
//             "Wager {}: Wins={}, Losses={}, Accuracy={}%",
//             i + 1,
//             alice_stats.total_wins,
//             alice_stats.total_losses,
//             alice_stats.accuracy_percentage
//         );

//         i += 1;
//     };

//     // Final check
//     let alice_stats = wager.get_user_stats(alice);
//     println!(
//         "Final stats: Wins={}, Losses={}, Accuracy={}%",
//         alice_stats.total_wins,
//         alice_stats.total_losses,
//         alice_stats.accuracy_percentage
//     );

//     // Verify the stats are correct (8 wins, 2 losses = 80%)
//     assert(alice_stats.total_wins == 8, 'Wrong wins count');
//     assert(alice_stats.total_losses == 2, 'Wrong losses count');
//     assert(alice_stats.accuracy_percentage == 80, 'Wrong accuracy percentage');

//     // Check ALICE earned AccuratePrediction achievement (80% accuracy over 10 wagers)
//     assert(
//         wager.has_achievement(alice, AchievementType::AccuratePrediction),
//         'AccuratePrediction not earned'
//     );

//     let alice_stats = wager.get_user_stats(alice);
//     assert(alice_stats.accuracy_percentage == 80, 'Wrong accuracy percentage');
// }

#[test]
fn test_has_achievement_false_for_unearned() {
    let (wager, _, _) = setup();

    // New user should not have any achievements
    assert(
        !wager.has_achievement(ALICE(), AchievementType::FirstWager), 'Should not have achievement'
    );
    assert(
        !wager.has_achievement(ALICE(), AchievementType::WinStreak5), 'Should not have achievement'
    );
}

#[test]
fn test_get_user_achievements_empty() {
    let (wager, _, _) = setup();

    let achievements = wager.get_user_achievements(ALICE());
    assert(achievements.len() == 0, 'Should have no achievements');
}

#[test]
fn test_multiple_achievements_single_user() {
    let (wager, escrow, strk_dispatcher) = setup();

    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // High stake to trigger HighStaker achievement
    let high_stake = 1000_u256;
    let resolution_time = get_block_timestamp() + 100;

    // Create high-stake wager (should earn FirstWager + HighStaker)
    let _wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, high_stake, high_stake, resolution_time
    );

    // Check both achievements were earned
    assert(wager.has_achievement(OWNER(), AchievementType::FirstWager), 'FirstWager not earned');
    assert(wager.has_achievement(OWNER(), AchievementType::HighStaker), 'HighStaker not earned');

    let achievements = wager.get_user_achievements(OWNER());
    assert(achievements.len() == 2, 'Should have 2 achievements');
}

#[test]
fn test_admin_resolve_updates_reputation() {
    let (wager, escrow, strk_dispatcher) = setup();

    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let resolution_time = get_block_timestamp() + 100;
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, stake, stake, resolution_time
    );

    let bob = BOB();

    // Setup BOB to join
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    wager.join_wager(wager_id, Claim::No);
    stop_cheat_caller_address(wager.contract_address);

    // Admin resolves in favor of OWNER
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.resolve_wager(wager_id, OWNER());
    stop_cheat_caller_address(wager.contract_address);

    // Check OWNER's stats were updated (winner)
    let owner_stats = wager.get_user_stats(OWNER());
    assert(owner_stats.total_wins == 1, 'Wrong wins count');
    assert(owner_stats.current_win_streak == 1, 'Wrong win streak');

    // Check BOB's stats were updated (loser)
    let bob_stats = wager.get_user_stats(bob);
    assert(bob_stats.total_losses == 1, 'Wrong losses count');
    assert(bob_stats.current_win_streak == 0, 'Win streak not reset');
}
