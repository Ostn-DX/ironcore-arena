## @file shared/constants.gd
## @brief Global simulation constants for the deterministic AI combat simulation.
## @description
## This file contains all shared constants used across the simulation system.
## All magic numbers must be defined here to ensure consistency and maintainability.
## Use SimConstants.TIMESTEP instead of hardcoded 0.0166667 everywhere.

class_name SimConstants
extends RefCounted

# =============================================================================
# SIMULATION TIMING CONSTANTS
# =============================================================================

## Fixed timestep for deterministic simulation (60 FPS)
## All physics and game logic runs at this fixed rate.
const TIMESTEP: float = 1.0 / 60.0

## Number of simulation ticks per second
const TICKS_PER_SECOND: int = 60

## Maximum delta time allowed before clamping (prevents spiral of death on lag)
const MAX_DELTA_TIME: float = 0.25

## Number of physics substeps per frame (for collision precision)
const PHYSICS_SUBSTEPS: int = 1

# =============================================================================
# BOT CONFIGURATION CONSTANTS
# =============================================================================

## Maximum number of bots allowed in a single simulation
const MAX_BOTS: int = 100

## Default bot movement speed in units per second
const BOT_MOVE_SPEED: float = 200.0

## Default bot rotation speed in radians per second
const BOT_ROTATION_SPEED: float = 5.0

## Default bot health
const BOT_DEFAULT_HEALTH: float = 100.0

## Default bot max health
const BOT_DEFAULT_MAX_HEALTH: float = 100.0

## Bot collision radius
const BOT_COLLISION_RADIUS: float = 16.0

## Bot vision range (how far they can see enemies)
const BOT_VISION_RANGE: float = 500.0

## Bot vision cone angle in radians (full angle, not half-angle)
const BOT_VISION_ANGLE: float = PI * 0.75  # 135 degrees

# =============================================================================
# TEAM IDENTIFIERS
# =============================================================================

## Team ID for neutral/observer entities
const TEAM_NONE: int = 0

## Team ID for the first faction (typically blue/player)
const TEAM_ALPHA: int = 1

## Team ID for the second faction (typically red/enemy)
const TEAM_BETA: int = 2

## Maximum number of teams supported
const MAX_TEAMS: int = 4

# =============================================================================
# WEAPON/PROJECTILE CONSTANTS
# =============================================================================

## Default projectile speed
const PROJECTILE_SPEED: float = 800.0

## Default projectile damage
const PROJECTILE_DAMAGE: float = 25.0

## Default projectile lifetime in seconds
const PROJECTILE_LIFETIME: float = 2.0

## Default fire cooldown in seconds
const FIRE_COOLDOWN: float = 0.25

## Maximum projectiles active at once (performance limit)
const MAX_PROJECTILES: int = 500

# =============================================================================
# ARENA/MAP CONSTANTS
# =============================================================================

## Default arena width
const ARENA_WIDTH: float = 2048.0

## Default arena height
const ARENA_HEIGHT: float = 2048.0

## Minimum valid X coordinate (inclusive)
const ARENA_MIN_X: float = -1024.0

## Maximum valid X coordinate (inclusive)
const ARENA_MAX_X: float = 1024.0

## Minimum valid Y coordinate (inclusive)
const ARENA_MIN_Y: float = -1024.0

## Maximum valid Y coordinate (inclusive)
const ARENA_MAX_Y: float = 1024.0

## Wall thickness for arena boundaries
const ARENA_WALL_THICKNESS: float = 64.0

# =============================================================================
# AI DECISION CONSTANTS
# =============================================================================

## AI decision update interval in ticks (how often AI re-evaluates)
const AI_DECISION_INTERVAL: int = 5

## Maximum AI decision time in milliseconds (performance constraint)
const AI_MAX_DECISION_TIME_MS: float = 2.0

## AI memory duration in seconds (how long bot remembers unseen enemies)
const AI_MEMORY_DURATION: float = 3.0

## AI threat evaluation range
const AI_THREAT_RANGE: float = 600.0

## AI ally support range
const AI_SUPPORT_RANGE: float = 400.0

# =============================================================================
# PERFORMANCE CONSTRAINTS
# =============================================================================

## Target frame time in milliseconds (for 60 FPS)
const TARGET_FRAME_TIME_MS: float = 16.667

## Maximum allowed frame time before warnings
const MAX_FRAME_TIME_MS: float = 33.333

## Maximum spatial hash cell size
const SPATIAL_HASH_CELL_SIZE: float = 128.0

## Maximum entities per spatial hash cell before subdivision warning
const SPATIAL_HASH_MAX_ENTITIES: int = 20

# =============================================================================
# DETERMINISM CONSTANTS
# =============================================================================

## Default RNG seed for reproducible simulations
const DEFAULT_RNG_SEED: int = 42

## Epsilon for float comparisons (deterministic equality checks)
const FLOAT_EPSILON: float = 0.0001

## Maximum significant digits for float serialization
const FLOAT_PRECISION_DIGITS: int = 6

## Hash iteration order seed (for deterministic dictionary iteration)
const DICTIONARY_SEED: int = 12345

# =============================================================================
# DEBUG/TESTING CONSTANTS
# =============================================================================

## Enable verbose logging (set to false in production)
const DEBUG_VERBOSE: bool = true

## Enable performance profiling
const DEBUG_PROFILING: bool = true

## Enable determinism validation checksums
const DEBUG_CHECKSUMS: bool = true

## Checksum validation interval in ticks
const CHECKSUM_INTERVAL_TICKS: int = 60

## Maximum recorded history size for replay (in ticks)
const MAX_REPLAY_HISTORY: int = 3600  # 1 minute at 60 FPS

# =============================================================================
# ENUMERATIONS
# =============================================================================

## Bot role types for tactical AI
enum BotRole {
	ASSAULT,      ## Front-line combat unit
	SNIPER,       ## Long-range precision unit
	SUPPORT,      ## Ally assistance and suppression
	SCOUT,        ## Fast reconnaissance unit
	HEAVY,        ## Slow, high-health tank unit
	CUSTOM        ## User-defined role
}

## Bot AI states
enum BotState {
	IDLE,         ## No current objective
	MOVING,       ## Moving to position
	ATTACKING,    ## Engaging enemy
	FLEEING,      ## Retreating from combat
	PATROLLING,   ## Following patrol path
	DEAD          ## Destroyed, awaiting cleanup
}

## Projectile types
enum ProjectileType {
	BULLET,       ## Standard hitscan projectile
	MISSILE,      ## Homing projectile
	LASER,        ## Instant beam
	EXPLOSIVE     ## Area damage projectile
}

## Game phase for match flow
enum GamePhase {
	SETUP,        ## Initial configuration
	WARMUP,       ## Pre-match countdown
	ACTIVE,       ## Match in progress
	OVERTIME,     ## Sudden death
	FINISHED      ## Match complete
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

## Checks if a team ID is valid
## @param team_id The team ID to validate
## @return true if team_id is a valid team identifier
static func is_valid_team(team_id: int) -> bool:
	return team_id >= TEAM_NONE and team_id < MAX_TEAMS


## Gets the enemy team ID for a given team
## @param team_id The friendly team ID
## @return The enemy team ID, or TEAM_NONE if invalid input
static func get_enemy_team(team_id: int) -> int:
	match team_id:
		TEAM_ALPHA:
			return TEAM_BETA
		TEAM_BETA:
			return TEAM_ALPHA
		_:
			return TEAM_NONE


## Clamps a position to valid arena bounds
## @param position The position to clamp
## @return Position clamped to arena boundaries
static func clamp_to_arena(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, ARENA_MIN_X, ARENA_MAX_X),
		clampf(position.y, ARENA_MIN_Y, ARENA_MAX_Y)
	)


## Checks if a position is within arena bounds
## @param position The position to check
## @return true if position is within valid arena boundaries
static func is_in_arena(position: Vector2) -> bool:
	return position.x >= ARENA_MIN_X and position.x <= ARENA_MAX_X \
		and position.y >= ARENA_MIN_Y and position.y <= ARENA_MAX_Y


## Converts ticks to seconds
## @param ticks Number of simulation ticks
## @return Equivalent time in seconds
static func ticks_to_seconds(ticks: int) -> float:
	return float(ticks) * TIMESTEP


## Converts seconds to ticks
## @param seconds Time in seconds
## @return Equivalent number of simulation ticks
static func seconds_to_ticks(seconds: float) -> int:
	return int(seconds * TICKS_PER_SECOND)


## Compares two floats for deterministic equality
## @param a First float value
## @param b Second float value
## @return true if floats are equal within epsilon
static func floats_equal(a: float, b: float) -> bool:
	return absf(a - b) <= FLOAT_EPSILON
