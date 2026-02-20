extends Node
class_name BalanceManager
## BalanceManager — centralizes all game balance values.
## Makes it easy to tweak numbers without digging through code.

const BALANCE_VERSION: String = "0.1.0"

# ============================================================================
# COMBAT BALANCE
# ============================================================================

class CombatBalance:
	# Base HP values
	static var BASE_BOT_HP: int = 100
	static var HP_PER_TIER: int = 50
	
	# Damage scaling
	static var BASE_WEAPON_DAMAGE: int = 20
	static var DAMAGE_PER_TIER: float = 1.2  # 20% increase per tier
	
	# Speed values
	static var BASE_BOT_SPEED: float = 100.0
	static var SPEED_PER_TIER: float = 15.0
	
	# Accuracy falloff
	static var OPTIMAL_RANGE_MULTIPLIER: float = 1.0
	static var MAX_RANGE_MULTIPLIER: float = 0.5
	
	# Cooldowns (in ticks, at 60 ticks/sec)
	static var BASE_FIRE_COOLDOWN: int = 30  # 0.5 seconds
	static var FIRE_COOLDOWN_PER_TIER: int = -3  # Gets faster
	
	# Movement
	static var BASE_ACCELERATION: float = 50.0
	static var TURN_RATE: float = 180.0  # degrees/sec


# ============================================================================
# ECONOMY BALANCE
# ============================================================================

class EconomyBalance:
	# Starting values
	static var STARTING_CREDITS: int = 500
	static var STARTING_TIER: int = 0
	
	# Reward scaling
	static var BASE_ARENA_REWARD: int = 100
	static var REWARD_PER_TIER: int = 50
	static var PAR_TIME_BONUS_PERCENT: int = 50
	
	# Grade bonuses
	static var GRADE_S_MULTIPLIER: float = 2.0
	static var GRADE_A_MULTIPLIER: float = 1.5
	static var GRADE_B_MULTIPLIER: float = 1.25
	static var GRADE_C_MULTIPLIER: float = 1.0
	static var GRADE_D_MULTIPLIER: float = 0.75
	
	# Shop prices
	static var COST_PER_TIER: Dictionary = {
		0: 200,  # Tier 1
		1: 400,  # Tier 2
		2: 800,  # Tier 3
		3: 1500  # Tier 4
	}
	
	# Selling components (if implemented)
	static var SELL_BACK_PERCENT: int = 50


# ============================================================================
# PROGRESSION BALANCE
# ============================================================================

class ProgressionBalance:
	# Arena requirements
	static var ARENAS_PER_TIER: int = 2
	static var BOT_SLOTS_PER_TIER: int = 1
	
	# Weight limits
	static var BASE_WEIGHT_LIMIT: int = 120
	static var WEIGHT_LIMIT_PER_TIER: int = 30
	
	# Par times (seconds)
	static var BASE_PAR_TIME: int = 120
	static var PAR_TIME_PER_TIER: int = 30


# ============================================================================
# AI BALANCE
# ============================================================================

class AIBalance:
	# AI difficulty per tier
	static var AI_ACCURACY_PER_TIER: float = 0.05
	static var AI_REACTION_TIME_TICKS: int = 30
	
	# AI profiles
	static var AGGRESSIVE_HP_MULTIPLIER: float = 0.8
	static var AGGRESSIVE_DAMAGE_MULTIPLIER: float = 1.2
	
	static var DEFENSIVE_HP_MULTIPLIER: float = 1.3
	static var DEFENSIVE_DAMAGE_MULTIPLIER: float = 0.8


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

static func get_component_cost(tier: int) -> int:
	## Get base cost for a component tier
	return EconomyBalance.COST_PER_TIER.get(tier, 200)


static func get_arena_reward(arena_tier: int) -> int:
	## Calculate arena reward
	return EconomyBalance.BASE_ARENA_REWARD + (EconomyBalance.REWARD_PER_TIER * arena_tier)


static func get_grade_multiplier(grade: String) -> float:
	## Get reward multiplier for a grade
	match grade:
		"S": return EconomyBalance.GRADE_S_MULTIPLIER
		"A": return EconomyBalance.GRADE_A_MULTIPLIER
		"B": return EconomyBalance.GRADE_B_MULTIPLIER
		"C": return EconomyBalance.GRADE_C_MULTIPLIER
		"D": return EconomyBalance.GRADE_D_MULTIPLIER
		_: return 0.0


static func get_par_time(arena_tier: int) -> int:
	## Calculate par time for arena
	return ProgressionBalance.BASE_PAR_TIME + (ProgressionBalance.PAR_TIME_PER_TIER * arena_tier)


static func get_weight_limit(player_tier: int) -> int:
	## Calculate weight limit for player tier
	return ProgressionBalance.BASE_WEIGHT_LIMIT + (ProgressionBalance.WEIGHT_LIMIT_PER_TIER * player_tier)


static func get_scaled_hp(base_hp: int, tier: int) -> int:
	## Calculate scaled HP for tier
	return base_hp + (CombatBalance.HP_PER_TIER * tier)


static func get_scaled_damage(base_damage: int, tier: int) -> int:
	## Calculate scaled damage for tier
	return int(base_damage * pow(CombatBalance.DAMAGE_PER_TIER, tier))


static func get_ai_accuracy(tier: int) -> float:
	## Get AI accuracy for tier
	return 0.7 + (AIBalance.AI_ACCURACY_PER_TIER * tier)


# ============================================================================
# BALANCE REPORT
# ============================================================================

static func generate_balance_report() -> Dictionary:
	## Generate a report of all balance values
	return {
		"version": BALANCE_VERSION,
		"combat": {
			"base_hp": CombatBalance.BASE_BOT_HP,
			"hp_per_tier": CombatBalance.HP_PER_TIER,
			"base_damage": CombatBalance.BASE_WEAPON_DAMAGE,
			"damage_multiplier_per_tier": CombatBalance.DAMAGE_PER_TIER
		},
		"economy": {
			"starting_credits": EconomyBalance.STARTING_CREDITS,
			"base_reward": EconomyBalance.BASE_ARENA_REWARD,
			"reward_per_tier": EconomyBalance.REWARD_PER_TIER,
			"tier_costs": EconomyBalance.COST_PER_TIER
		},
		"progression": {
			"arenas_per_tier": ProgressionBalance.ARENAS_PER_TIER,
			"base_weight_limit": ProgressionBalance.BASE_WEIGHT_LIMIT,
			"base_par_time": ProgressionBalance.BASE_PAR_TIME
		}
	}


static func print_balance_report() -> void:
	## Print balance report to console
	var report: Dictionary = generate_balance_report()
	print("=== IRONCORE ARENA BALANCE REPORT ===")
	print("Version: ", report["version"])
	print("\nCombat:")
	for key in report["combat"]:
		print("  %s: %s" % [key, report["combat"][key]])
	print("\nEconomy:")
	for key in report["economy"]:
		print("  %s: %s" % [key, report["economy"][key]])
	print("\nProgression:")
	for key in report["progression"]:
		print("  %s: %s" % [key, report["progression"][key]])
	print("=====================================")
