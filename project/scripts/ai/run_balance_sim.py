#!/usr/bin/env python3
"""
IronCore Arena -- Balance Simulation Runner (Python mirror of duel_simulator.gd)

Implements the EXACT same xorshift32 RNG and combat resolution logic as the
GDScript DuelSimulator, so results are cross-verifiable.

Usage: python run_balance_sim.py [runs_per_pair] [base_seed]
Output: writes balance_report.json to the same directory
"""

import json
import math
import os
import sys
from datetime import datetime, timezone
from itertools import combinations

# ---------------------------------------------------------------------------
# xorshift32 RNG -- must match DeterministicRng.gd exactly
# ---------------------------------------------------------------------------
U32_MASK = 0xFFFFFFFF
U32_MAX = 4294967296  # 2^32


class Xorshift32:
    """Deterministic RNG matching the GDScript DeterministicRng implementation."""

    def __init__(self, seed: int):
        self._state = (seed & U32_MASK) if seed != 0 else 1

    def next_u32(self) -> int:
        x = self._state
        x = x ^ ((x << 13) & U32_MASK)
        x = x ^ ((x >> 17) & U32_MASK)
        x = x ^ ((x << 5) & U32_MASK)
        self._state = x & U32_MASK
        return self._state

    def next_float01(self) -> float:
        return self.next_u32() / U32_MAX

    def next_float_range(self, min_val: float, max_val: float) -> float:
        return min_val + self.next_float01() * (max_val - min_val)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
TIMESTEP = 1.0 / 60.0
MAX_TICKS = 3600  # 60 seconds
DEFAULT_HP = 100.0
DEFAULT_ARMOR = 10.0

# Imbalance thresholds
WIN_RATE_THRESHOLD = 0.70
TTK_VARIANCE_THRESHOLD = 50.0
TTK_TOO_FAST = 3.0
TTK_TOO_SLOW = 30.0


# ---------------------------------------------------------------------------
# Bot creation
# ---------------------------------------------------------------------------
def make_bot(sim_id: int, weapon: dict) -> dict:
    return {
        "sim_id": sim_id,
        "hp": DEFAULT_HP,
        "max_hp": DEFAULT_HP,
        "armor": DEFAULT_ARMOR,
        "is_alive": True,
        "heat": 0.0,
        "overheated": False,
        "overheat_end_tick": 0,
        "next_fire_tick": 0,
        "burst_remaining": 0,
        "burst_ready": True,
        "next_burst_tick": 0,
        "status_effects": [],
        "resist_ballistic": 0.1,
        "resist_energy": 0.1,
        "resist_explosive": 0.1,
        "armor_break_magnitude": 0.0,
    }


# ---------------------------------------------------------------------------
# Status effects
# ---------------------------------------------------------------------------
def apply_effect(bot: dict, effect_def: dict, tick: int):
    effects = bot["status_effects"]
    etype = effect_def.get("type", "")
    stacking = effect_def.get("stacking", "refresh")
    new_effect = {
        "type": etype,
        "magnitude": effect_def.get("magnitude", 0.0),
        "remaining_ticks": effect_def.get("duration_ticks", 60),
        "tick_interval": effect_def.get("tick_interval", 0),
        "last_tick_at": tick,
        "applied_tick": tick,
        "stack_count": 1,
    }

    found = -1
    for i, e in enumerate(effects):
        if e.get("type", "") == etype:
            found = i
            break

    if found >= 0:
        if stacking == "replace":
            effects[found] = new_effect
        elif stacking == "refresh":
            effects[found]["remaining_ticks"] = new_effect["remaining_ticks"]
            effects[found]["applied_tick"] = tick
        elif stacking == "stack":
            max_stacks = effect_def.get("max_stacks", 3)
            stack_count = effects[found].get("stack_count", 1)
            if stack_count < max_stacks:
                effects[found]["magnitude"] += new_effect["magnitude"]
                effects[found]["stack_count"] = stack_count + 1
            effects[found]["remaining_ticks"] = new_effect["remaining_ticks"]
    else:
        effects.append(new_effect)


def tick_status_effects(bot: dict, tick: int):
    effects = bot["status_effects"]
    to_remove = []

    for i, e in enumerate(effects):
        e["remaining_ticks"] -= 1

        # Periodic burn
        interval = e.get("tick_interval", 0)
        if interval > 0 and e.get("type", "") == "burn":
            if (tick - e.get("applied_tick", 0)) % interval == 0:
                burn_dmg = e.get("magnitude", 0.0)
                bot["hp"] = max(0.0, bot["hp"] - burn_dmg)
                if bot["hp"] <= 0:
                    bot["is_alive"] = False

        # Armor break
        if e.get("type", "") == "armor_break":
            bot["armor_break_magnitude"] = e.get("magnitude", 0.0)

        if e.get("remaining_ticks", 0) <= 0:
            to_remove.append(i)
            if e.get("type", "") == "armor_break":
                bot["armor_break_magnitude"] = 0.0

    for idx in reversed(to_remove):
        effects.pop(idx)


def is_stunned(bot: dict) -> bool:
    for e in bot["status_effects"]:
        if e.get("type", "") == "stun":
            return True
    return False


# ---------------------------------------------------------------------------
# Heat / cooldown
# ---------------------------------------------------------------------------
def dissipate_heat(bot: dict, weapon: dict, tick: int):
    diss = weapon.get("heat_dissipation_per_tick", 0.3)
    bot["heat"] = max(0.0, bot["heat"] - diss)

    # Burst readiness
    if bot.get("burst_remaining", 0) > 0:
        burst_delay = weapon.get("burst_delay_ticks", 0)
        if burst_delay == 0 or tick >= bot.get("next_burst_tick", 0):
            bot["burst_ready"] = True


# ---------------------------------------------------------------------------
# Shot resolution
# ---------------------------------------------------------------------------
def resolve_shot(attacker: dict, defender: dict, weapon: dict, distance: float,
                 rng: Xorshift32, tick: int):
    ptype = weapon.get("projectile_type", "ballistic")
    accuracy = weapon.get("accuracy", 0.7)

    # Accuracy check (beams/melee always hit)
    if ptype not in ("beam", "melee"):
        range_optimal = weapon.get("range_optimal", 100.0)
        range_max = weapon.get("range_max", 200.0)
        if distance > range_optimal and range_max > range_optimal:
            range_ratio = (distance - range_optimal) / (range_max - range_optimal)
            accuracy *= (1.0 - min(max(range_ratio, 0.0), 1.0) * 0.5)
        accuracy = min(max(accuracy, 0.0), 1.0)
        roll = rng.next_float01()
        if roll >= accuracy:
            return  # Miss

    # Base damage
    base_dmg = weapon.get("damage_per_shot", 10.0)
    if base_dmg <= 0:
        return  # Repair beam

    # Range falloff
    range_min = weapon.get("range_min", 0.0)
    range_optimal = weapon.get("range_optimal", 100.0)
    range_max = weapon.get("range_max", 200.0)
    if distance < range_min:
        base_dmg = 0.0
    elif distance > range_optimal and range_max > range_optimal:
        falloff = 1.0 - (distance - range_optimal) / (range_max - range_optimal)
        base_dmg *= max(min(falloff, 1.0), 0.1)

    # Crit
    crit_chance = weapon.get("crit_chance", 0.0)
    if crit_chance > 0.0:
        crit_roll = rng.next_float01()
        if crit_roll < crit_chance:
            base_dmg *= weapon.get("crit_multiplier", 1.5)

    # Resistance
    resist_key = "resist_" + weapon.get("damage_type", "ballistic")
    resistance = defender.get(resist_key, 0.0)
    armor_break = defender.get("armor_break_magnitude", 0.0)
    resistance = max(0.0, resistance - armor_break)
    resistance = min(max(resistance, 0.0), 0.9)

    final_dmg = base_dmg * (1.0 - resistance)
    final_dmg = max(min(final_dmg, 9999.0), 0.0)

    defender["hp"] = max(0.0, defender["hp"] - final_dmg)
    if defender["hp"] <= 0:
        defender["is_alive"] = False

    # Status effects
    for effect_def in weapon.get("effects", []):
        apply_chance = effect_def.get("apply_chance", 1.0)
        effect_roll = rng.next_float01()
        if effect_roll < apply_chance:
            apply_effect(defender, effect_def, tick)


# ---------------------------------------------------------------------------
# Firing logic
# ---------------------------------------------------------------------------
def try_fire(attacker: dict, defender: dict, weapon: dict, distance: float,
             rng: Xorshift32, tick: int):
    # Check overheat
    if attacker.get("overheated", False):
        if tick >= attacker.get("overheat_end_tick", 0) and attacker.get("heat", 0.0) <= 0.0:
            attacker["overheated"] = False
        else:
            return

    # Check cooldown
    if tick < attacker.get("next_fire_tick", 0):
        return

    # Range check
    range_max = weapon.get("range_max", 200.0)
    if distance > range_max:
        return

    # Burst handling
    burst_count = weapon.get("burst_count", 1)
    is_new_burst = attacker.get("burst_remaining", 0) <= 0

    if is_new_burst:
        attacker["burst_remaining"] = burst_count

    if not is_new_burst and not attacker.get("burst_ready", True):
        return

    # Fire
    resolve_shot(attacker, defender, weapon, distance, rng, tick)

    # Advance burst
    attacker["burst_remaining"] -= 1
    attacker["burst_ready"] = False

    if attacker["burst_remaining"] <= 0:
        fire_rate = weapon.get("fire_rate", 1.0)
        cooldown = round(60.0 / fire_rate) if fire_rate > 0 else 9999
        attacker["next_fire_tick"] = tick + cooldown
    else:
        burst_delay = weapon.get("burst_delay_ticks", 0)
        attacker["next_burst_tick"] = tick + burst_delay
        if burst_delay == 0:
            attacker["burst_ready"] = True

    # Heat
    heat_per = weapon.get("heat_per_shot", 2.0)
    attacker["heat"] = attacker.get("heat", 0.0) + heat_per
    threshold = weapon.get("overheat_threshold", 40.0)
    if attacker["heat"] >= threshold:
        attacker["overheated"] = True
        lockout = weapon.get("overheat_lockout_ticks", 120)
        attacker["overheat_end_tick"] = tick + lockout


# ---------------------------------------------------------------------------
# Single duel
# ---------------------------------------------------------------------------
def run_duel(weapon_a: dict, weapon_b: dict, seed_val: int) -> dict:
    rng = Xorshift32(seed_val)

    bot_a = make_bot(1, weapon_a)
    bot_b = make_bot(2, weapon_b)

    # Engagement range: average of optimal ranges, clamped to both max ranges
    range_a = weapon_a.get("range_optimal", 100.0)
    range_b = weapon_b.get("range_optimal", 100.0)
    engagement_range = (range_a + range_b) / 2.0
    max_range_a = weapon_a.get("range_max", 200.0)
    max_range_b = weapon_b.get("range_max", 200.0)
    engagement_range = min(engagement_range, min(max_range_a, max_range_b))
    engagement_range = max(engagement_range, 30.0)
    distance = engagement_range

    ttk_a = -1.0
    ttk_b = -1.0

    for tick in range(MAX_TICKS):
        # Heat dissipation
        dissipate_heat(bot_a, weapon_a, tick)
        dissipate_heat(bot_b, weapon_b, tick)

        # Bot A fires
        if bot_a["hp"] > 0 and bot_b["hp"] > 0:
            if not is_stunned(bot_a):
                try_fire(bot_a, bot_b, weapon_a, distance, rng, tick)

        # Bot B fires
        if bot_a["hp"] > 0 and bot_b["hp"] > 0:
            if not is_stunned(bot_b):
                try_fire(bot_b, bot_a, weapon_b, distance, rng, tick)

        # Status effects
        tick_status_effects(bot_a, tick)
        tick_status_effects(bot_b, tick)

        # Check kills
        if bot_b["hp"] <= 0 and ttk_a < 0:
            ttk_a = (tick + 1) * TIMESTEP
        if bot_a["hp"] <= 0 and ttk_b < 0:
            ttk_b = (tick + 1) * TIMESTEP

        if bot_a["hp"] <= 0 or bot_b["hp"] <= 0:
            break

    id_a = weapon_a.get("id", "weapon_a")
    id_b = weapon_b.get("id", "weapon_b")

    if bot_b["hp"] <= 0 and bot_a["hp"] > 0:
        winner = id_a
    elif bot_a["hp"] <= 0 and bot_b["hp"] > 0:
        winner = id_b
    elif bot_a["hp"] <= 0 and bot_b["hp"] <= 0:
        winner = id_a  # First processed wins tie
    else:
        winner = "draw"

    return {
        "winner": winner,
        "ttk_a": ttk_a,
        "ttk_b": ttk_b,
        "ticks": tick + 1,
    }


# ---------------------------------------------------------------------------
# Batch runner
# ---------------------------------------------------------------------------
def run_batch(weapon_a: dict, weapon_b: dict, num_runs: int, base_seed: int) -> dict:
    id_a = weapon_a.get("id", "weapon_a")
    id_b = weapon_b.get("id", "weapon_b")

    a_wins = 0
    b_wins = 0
    draws = 0
    winner_ttks = []
    loser_ttks = []
    outlier_ticks = []

    for i in range(num_runs):
        result = run_duel(weapon_a, weapon_b, base_seed + i)
        w = result["winner"]
        if w == id_a:
            a_wins += 1
            if result["ttk_a"] >= 0:
                winner_ttks.append(result["ttk_a"])
            if result["ttk_b"] >= 0:
                loser_ttks.append(result["ttk_b"])
        elif w == id_b:
            b_wins += 1
            if result["ttk_b"] >= 0:
                winner_ttks.append(result["ttk_b"])
            if result["ttk_a"] >= 0:
                loser_ttks.append(result["ttk_a"])
        else:
            draws += 1
        if result["ticks"] > 2700:
            outlier_ticks.append(result["ticks"])

    avg_ttk_w = sum(winner_ttks) / len(winner_ttks) if winner_ttks else 0.0
    avg_ttk_l = sum(loser_ttks) / len(loser_ttks) if loser_ttks else 0.0
    ttk_var = 0.0
    if len(winner_ttks) > 1:
        mean = avg_ttk_w
        ttk_var = sum((v - mean) ** 2 for v in winner_ttks) / len(winner_ttks)

    return {
        "weapon_a_wins": a_wins,
        "weapon_b_wins": b_wins,
        "draws": draws,
        "avg_ttk_winner": round(avg_ttk_w, 3),
        "avg_ttk_loser": round(avg_ttk_l, 3),
        "ttk_variance": round(ttk_var, 3),
        "outlier_count": len(outlier_ticks),
    }


# ---------------------------------------------------------------------------
# Imbalance detection
# ---------------------------------------------------------------------------
def detect_imbalance(pairs: list) -> list:
    flags = []
    for pair in pairs:
        pair_name = f"{pair['weapon_a']} vs {pair['weapon_b']}"
        wr_a = pair.get("win_rate_a", 0.5)
        wr_b = pair.get("win_rate_b", 0.5)
        avg_ttk_w = pair.get("avg_ttk_winner", 10.0)
        ttk_var = pair.get("ttk_variance", 0.0)

        if wr_a > WIN_RATE_THRESHOLD:
            flags.append({
                "pair": pair_name,
                "flag": "IMBALANCED",
                "value": round(wr_a, 4),
                "threshold": WIN_RATE_THRESHOLD,
                "detail": f"{pair['weapon_a']} dominates",
            })
        if wr_b > WIN_RATE_THRESHOLD:
            flags.append({
                "pair": pair_name,
                "flag": "IMBALANCED",
                "value": round(wr_b, 4),
                "threshold": WIN_RATE_THRESHOLD,
                "detail": f"{pair['weapon_b']} dominates",
            })
        if ttk_var > TTK_VARIANCE_THRESHOLD:
            flags.append({
                "pair": pair_name,
                "flag": "HIGH_VARIANCE",
                "value": round(ttk_var, 3),
                "threshold": TTK_VARIANCE_THRESHOLD,
            })
        if 0 < avg_ttk_w < TTK_TOO_FAST:
            flags.append({
                "pair": pair_name,
                "flag": "TOO_FAST",
                "value": round(avg_ttk_w, 3),
                "threshold": TTK_TOO_FAST,
            })
        if avg_ttk_w > TTK_TOO_SLOW:
            flags.append({
                "pair": pair_name,
                "flag": "TOO_SLOW",
                "value": round(avg_ttk_w, 3),
                "threshold": TTK_TOO_SLOW,
            })

    return flags


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    runs_per_pair = 10000
    base_seed = 12345

    if len(sys.argv) > 1:
        runs_per_pair = int(sys.argv[1])
    if len(sys.argv) > 2:
        base_seed = int(sys.argv[2])

    # Load weapons
    script_dir = os.path.dirname(os.path.abspath(__file__))
    weapons_path = os.path.join(script_dir, "..", "..", "data", "weapons", "weapons.json")
    weapons_path = os.path.normpath(weapons_path)

    print(f"Loading weapons from: {weapons_path}")
    with open(weapons_path, "r") as f:
        weapons = json.load(f)

    print(f"Loaded {len(weapons)} weapons")

    # Filter out repair beam (negative damage)
    combat_weapons = [w for w in weapons if w.get("damage_per_shot", 0) > 0]
    print(f"Combat weapons (excluding repair beam): {len(combat_weapons)}")

    # Generate all unique pairs
    weapon_pairs = list(combinations(range(len(combat_weapons)), 2))
    total_pairs = len(weapon_pairs)
    total_duels = total_pairs * runs_per_pair
    print(f"Pairs: {total_pairs}, Duels per pair: {runs_per_pair}, Total duels: {total_duels}")

    # Track per-weapon stats
    weapon_wins = {w["id"]: 0 for w in combat_weapons}
    weapon_losses = {w["id"]: 0 for w in combat_weapons}

    pairs_data = []
    for idx, (i, j) in enumerate(weapon_pairs):
        wa = combat_weapons[i]
        wb = combat_weapons[j]
        id_a = wa["id"]
        id_b = wb["id"]

        if (idx + 1) % 10 == 0 or idx == 0:
            print(f"  Pair {idx + 1}/{total_pairs}: {id_a} vs {id_b}...")

        batch = run_batch(wa, wb, runs_per_pair, base_seed)

        total = batch["weapon_a_wins"] + batch["weapon_b_wins"] + batch["draws"]
        wr_a = batch["weapon_a_wins"] / total if total > 0 else 0.5
        wr_b = batch["weapon_b_wins"] / total if total > 0 else 0.5

        pair_result = {
            "weapon_a": id_a,
            "weapon_b": id_b,
            "weapon_a_wins": batch["weapon_a_wins"],
            "weapon_b_wins": batch["weapon_b_wins"],
            "draws": batch["draws"],
            "win_rate_a": round(wr_a, 4),
            "win_rate_b": round(wr_b, 4),
            "avg_ttk_winner": batch["avg_ttk_winner"],
            "avg_ttk_loser": batch["avg_ttk_loser"],
            "ttk_variance": batch["ttk_variance"],
            "outlier_count": batch["outlier_count"],
        }
        pairs_data.append(pair_result)

        weapon_wins[id_a] += batch["weapon_a_wins"]
        weapon_wins[id_b] += batch["weapon_b_wins"]
        weapon_losses[id_a] += batch["weapon_b_wins"]
        weapon_losses[id_b] += batch["weapon_a_wins"]

    # Detect imbalances
    flags = detect_imbalance(pairs_data)

    # Summary
    most_wins_id = max(weapon_wins, key=weapon_wins.get) if weapon_wins else ""
    most_losses_id = max(weapon_losses, key=weapon_losses.get) if weapon_losses else ""

    report = {
        "meta": {
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "runs_per_pair": runs_per_pair,
            "base_seed": base_seed,
            "total_duels": total_duels,
            "combat_weapons": len(combat_weapons),
            "total_pairs": total_pairs,
        },
        "pairs": pairs_data,
        "imbalance_flags": flags,
        "summary": {
            "most_wins": most_wins_id,
            "most_wins_count": weapon_wins.get(most_wins_id, 0),
            "most_losses": most_losses_id,
            "most_losses_count": weapon_losses.get(most_losses_id, 0),
            "flagged_pairs": len(flags),
            "weapon_win_totals": {k: v for k, v in sorted(weapon_wins.items(), key=lambda x: -x[1])},
            "weapon_loss_totals": {k: v for k, v in sorted(weapon_losses.items(), key=lambda x: -x[1])},
        },
    }

    # Write report
    output_path = os.path.join(script_dir, "balance_report.json")
    with open(output_path, "w") as f:
        json.dump(report, f, indent=2)

    print(f"\n{'='*60}")
    print(f"Balance report written to: {output_path}")
    print(f"Total duels simulated: {total_duels}")
    print(f"Flagged issues: {len(flags)}")
    print(f"Most wins: {most_wins_id} ({weapon_wins.get(most_wins_id, 0)} wins)")
    print(f"Most losses: {most_losses_id} ({weapon_losses.get(most_losses_id, 0)} losses)")

    if flags:
        print(f"\n--- IMBALANCE FLAGS ---")
        for f_item in flags:
            detail = f_item.get("detail", "")
            detail_str = f" ({detail})" if detail else ""
            print(f"  [{f_item['flag']}] {f_item['pair']}: {f_item['value']:.4f} (threshold: {f_item['threshold']}){detail_str}")
    else:
        print("\nNo imbalance flags detected -- all pairs within thresholds.")

    print(f"\n--- PER-WEAPON WIN TOTALS ---")
    for wid, wins in sorted(weapon_wins.items(), key=lambda x: -x[1]):
        losses = weapon_losses.get(wid, 0)
        total_games = wins + losses
        wr = wins / total_games if total_games > 0 else 0
        print(f"  {wid:20s}: {wins:6d} wins / {losses:6d} losses (overall WR: {wr:.3f})")


if __name__ == "__main__":
    main()
