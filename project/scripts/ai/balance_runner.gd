extends RefCounted
class_name BalanceRunner
## Runs all weapon pair combinations and produces a structured balance report.
## Uses DuelSimulator for individual matchups.

# Imbalance thresholds
const WIN_RATE_THRESHOLD: float = 0.70
const TTK_VARIANCE_THRESHOLD: float = 50.0
const TTK_TOO_FAST: float = 3.0
const TTK_TOO_SLOW: float = 30.0


func run_full_balance(weapons: Array, runs_per_pair: int, base_seed: int) -> Dictionary:
	## Run all weapon pair combinations (n*(n-1)/2).
	## Returns structured report dictionary.
	var sim := DuelSimulator.new()
	var pairs: Array = []
	var weapon_wins: Dictionary = {}  # weapon_id -> total wins
	var weapon_losses: Dictionary = {}  # weapon_id -> total losses

	# Init counters
	for w in weapons:
		var wid: String = str(w.get("id", ""))
		weapon_wins[wid] = 0
		weapon_losses[wid] = 0

	# All unique pairs
	for i in range(weapons.size()):
		for j in range(i + 1, weapons.size()):
			var wa: Dictionary = weapons[i]
			var wb: Dictionary = weapons[j]
			var id_a: String = str(wa.get("id", ""))
			var id_b: String = str(wb.get("id", ""))

			# Skip repair beam in combat duels (it heals, doesn't fight)
			if wa.get("damage_per_shot", 0) < 0 or wb.get("damage_per_shot", 0) < 0:
				continue

			var batch: Dictionary = sim.run_batch(wa, wb, runs_per_pair, base_seed)

			var total: int = batch["weapon_a_wins"] + batch["weapon_b_wins"] + batch["draws"]
			var win_rate_a: float = float(batch["weapon_a_wins"]) / float(total) if total > 0 else 0.5
			var win_rate_b: float = float(batch["weapon_b_wins"]) / float(total) if total > 0 else 0.5

			pairs.append({
				"weapon_a": id_a,
				"weapon_b": id_b,
				"weapon_a_wins": batch["weapon_a_wins"],
				"weapon_b_wins": batch["weapon_b_wins"],
				"draws": batch["draws"],
				"win_rate_a": win_rate_a,
				"win_rate_b": win_rate_b,
				"avg_ttk_winner": batch["avg_ttk_winner"],
				"avg_ttk_loser": batch["avg_ttk_loser"],
				"ttk_variance": batch["ttk_variance"],
				"outlier_count": batch["outlier_ticks"].size(),
			})

			# Track totals
			weapon_wins[id_a] = weapon_wins.get(id_a, 0) + batch["weapon_a_wins"]
			weapon_wins[id_b] = weapon_wins.get(id_b, 0) + batch["weapon_b_wins"]
			weapon_losses[id_a] = weapon_losses.get(id_a, 0) + batch["weapon_b_wins"]
			weapon_losses[id_b] = weapon_losses.get(id_b, 0) + batch["weapon_a_wins"]

	# Detect imbalances
	var flags: Array = detect_imbalance({"pairs": pairs})

	# Summary
	var most_wins_id: String = ""
	var most_wins_count: int = 0
	var most_losses_id: String = ""
	var most_losses_count: int = 0
	for wid in weapon_wins:
		if weapon_wins[wid] > most_wins_count:
			most_wins_count = weapon_wins[wid]
			most_wins_id = wid
	for wid in weapon_losses:
		if weapon_losses[wid] > most_losses_count:
			most_losses_count = weapon_losses[wid]
			most_losses_id = wid

	var total_duels: int = pairs.size() * runs_per_pair

	return {
		"meta": {
			"generated_at": "",
			"runs_per_pair": runs_per_pair,
			"base_seed": base_seed,
			"total_duels": total_duels,
		},
		"pairs": pairs,
		"imbalance_flags": flags,
		"summary": {
			"most_wins": most_wins_id,
			"most_losses": most_losses_id,
			"flagged_pairs": flags.size(),
		},
	}


func detect_imbalance(report: Dictionary) -> Array:
	## Analyze pairs and return array of imbalance flags.
	## Flags: win_rate > 70%, ttk_variance > 50, avg_ttk < 3.0s, avg_ttk > 30.0s
	var flags: Array = []
	var pairs: Array = report.get("pairs", [])

	for pair in pairs:
		var pair_name: String = str(pair.get("weapon_a", "")) + " vs " + str(pair.get("weapon_b", ""))
		var win_rate_a: float = pair.get("win_rate_a", 0.5)
		var win_rate_b: float = pair.get("win_rate_b", 0.5)
		var avg_ttk_w: float = pair.get("avg_ttk_winner", 10.0)
		var ttk_var: float = pair.get("ttk_variance", 0.0)

		if win_rate_a > WIN_RATE_THRESHOLD:
			flags.append({
				"pair": pair_name,
				"flag": "IMBALANCED",
				"value": win_rate_a,
				"threshold": WIN_RATE_THRESHOLD,
				"detail": str(pair.get("weapon_a", "")) + " dominates",
			})
		if win_rate_b > WIN_RATE_THRESHOLD:
			flags.append({
				"pair": pair_name,
				"flag": "IMBALANCED",
				"value": win_rate_b,
				"threshold": WIN_RATE_THRESHOLD,
				"detail": str(pair.get("weapon_b", "")) + " dominates",
			})
		if ttk_var > TTK_VARIANCE_THRESHOLD:
			flags.append({
				"pair": pair_name,
				"flag": "HIGH_VARIANCE",
				"value": ttk_var,
				"threshold": TTK_VARIANCE_THRESHOLD,
			})
		if avg_ttk_w > 0.0 and avg_ttk_w < TTK_TOO_FAST:
			flags.append({
				"pair": pair_name,
				"flag": "TOO_FAST",
				"value": avg_ttk_w,
				"threshold": TTK_TOO_FAST,
			})
		if avg_ttk_w > TTK_TOO_SLOW:
			flags.append({
				"pair": pair_name,
				"flag": "TOO_SLOW",
				"value": avg_ttk_w,
				"threshold": TTK_TOO_SLOW,
			})

	return flags
