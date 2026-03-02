class_name TacticalScorer extends RefCounted

## Evaluates tactical positions based on multiple factors.
## Provides a weighted scoring system for position evaluation in combat scenarios.

# Default weights for scoring factors
const DEFAULT_COVER_WEIGHT: float = 1.0
const DEFAULT_FLANK_WEIGHT: float = 0.8
const DEFAULT_DISTANCE_WEIGHT: float = 0.6
const DEFAULT_LINE_OF_SIGHT_WEIGHT: float = 1.2
const DEFAULT_COHESION_WEIGHT: float = 0.5
const DEFAULT_KITE_WEIGHT: float = 0.7

# Scoring constants
const MAX_COVER_SCORE: float = 1.0
const MAX_FLANK_SCORE: float = 1.0
const MAX_DISTANCE_SCORE: float = 1.0
const MAX_LOS_SCORE: float = 1.0
const MAX_COHESION_SCORE: float = 1.0
const MAX_KITE_SCORE: float = 1.0

const IDEAL_COHESION_DISTANCE: float = 150.0
const MIN_COHESION_DISTANCE: float = 50.0
const MAX_COHESION_DISTANCE: float = 400.0

const FLANK_ANGLE_THRESHOLD: float = 45.0  # Degrees
const FLANK_OPTIMAL_ANGLE: float = 90.0    # Side angle

const KITE_OPTIMAL_RANGE_RATIO: float = 0.8  # 80% of weapon range

# Configurable weights
var cover_weight: float = DEFAULT_COVER_WEIGHT
var flank_weight: float = DEFAULT_FLANK_WEIGHT
var distance_weight: float = DEFAULT_DISTANCE_WEIGHT
var line_of_sight_weight: float = DEFAULT_LINE_OF_SIGHT_WEIGHT
var cohesion_weight: float = DEFAULT_COHESION_WEIGHT
var kite_weight: float = DEFAULT_KITE_WEIGHT


## Sets all weights at once for role-specific configurations.
func set_weights(
    cover: float,
    flank: float,
    distance: float,
    los: float,
    cohesion: float,
    kite: float
) -> void:
    cover_weight = cover
    flank_weight = flank
    distance_weight = distance
    line_of_sight_weight = los
    cohesion_weight = cohesion
    kite_weight = kite


## Scores a candidate position for a bot.
## Higher score = better position.
## Returns a score in range [0, total_weights] approximately.
func score_position(
    bot_pos: Vector2,
    candidate_pos: Vector2,
    enemy_positions: PackedVector2Array,
    ally_positions: PackedVector2Array,
    cover_points: PackedVector2Array,
    preferred_distance: float = 200.0,
    weapon_range: float = 300.0
) -> float:
    var total_score: float = 0.0
    
    # Calculate individual scores
    var cover_score: float = _calculate_cover_score(candidate_pos, enemy_positions, cover_points)
    var flank_score: float = _calculate_flank_score(candidate_pos, enemy_positions)
    var distance_score: float = _calculate_distance_score(candidate_pos, enemy_positions, preferred_distance)
    var los_score: float = _calculate_los_score(candidate_pos, enemy_positions, weapon_range)
    var cohesion_score: float = _calculate_cohesion_score(candidate_pos, ally_positions)
    var kite_score: float = _calculate_kite_score(candidate_pos, enemy_positions, weapon_range)
    
    # Apply weights
    total_score += cover_score * cover_weight
    total_score += flank_score * flank_weight
    total_score += distance_score * distance_weight
    total_score += los_score * line_of_sight_weight
    total_score += cohesion_score * cohesion_weight
    total_score += kite_score * kite_weight
    
    return total_score


## Calculates cover score based on proximity to cover points and enemy LOS blocking.
## Returns score in range [0, MAX_COVER_SCORE].
func _calculate_cover_score(
    pos: Vector2,
    enemy_positions: PackedVector2Array,
    cover_points: PackedVector2Array
) -> float:
    var score: float = 0.0
    
    # Score based on nearby cover points
    var nearest_cover_dist: float = 999999.0
    for cover_point: Vector2 in cover_points:
        var dist: float = pos.distance_to(cover_point)
        if dist < nearest_cover_dist:
            nearest_cover_dist = dist
    
    # Closer to cover = better (inverse relationship)
    if nearest_cover_dist < 999999.0:
        var cover_proximity: float = 1.0 - clampf(nearest_cover_dist / 200.0, 0.0, 1.0)
        score += cover_proximity * 0.5
    
    # Score based on enemy LOS being blocked
    var los_blocked_count: int = 0
    for enemy_pos: Vector2 in enemy_positions:
        # Check if position is behind cover relative to enemy
        # Simplified: assume cover blocks if we're close to a cover point
        if nearest_cover_dist < 100.0:
            los_blocked_count += 1
    
    if enemy_positions.size() > 0:
        var los_block_ratio: float = float(los_blocked_count) / float(enemy_positions.size())
        score += los_block_ratio * 0.5
    
    return clampf(score, 0.0, MAX_COVER_SCORE)


## Calculates flank advantage (side/back angles to enemies).
## Returns score in range [0, MAX_FLANK_SCORE].
func _calculate_flank_score(pos: Vector2, enemy_positions: PackedVector2Array) -> float:
    if enemy_positions.is_empty():
        return MAX_FLANK_SCORE * 0.5  # Neutral when no enemies
    
    var total_flank_score: float = 0.0
    
    for enemy_pos: Vector2 in enemy_positions:
        # Calculate angle from enemy to position
        var to_pos: Vector2 = (pos - enemy_pos).normalized()
        # Assume enemy faces right (1, 0) for simplicity, or use their facing
        var enemy_facing: Vector2 = Vector2.RIGHT
        var angle: float = rad_to_deg(absf(to_pos.angle_to(enemy_facing)))
        
        # Side angles (around 90 degrees) are best for flanking
        var flank_quality: float = 0.0
        if angle >= FLANK_ANGLE_THRESHOLD and angle <= 135.0:
            # Side flank - optimal
            flank_quality = 1.0 - absf(angle - FLANK_OPTIMAL_ANGLE) / 90.0
        elif angle > 135.0:
            # Behind enemy - also good
            flank_quality = 0.8
        else:
            # Frontal approach - poor
            flank_quality = 0.2
        
        total_flank_score += flank_quality
    
    return clampf(total_flank_score / float(enemy_positions.size()), 0.0, MAX_FLANK_SCORE)


## Calculates distance score based on proximity to preferred distance from enemies.
## Returns score in range [0, MAX_DISTANCE_SCORE].
func _calculate_distance_score(
    pos: Vector2,
    enemy_positions: PackedVector2Array,
    preferred_distance: float
) -> float:
    if enemy_positions.is_empty():
        return MAX_DISTANCE_SCORE * 0.5
    
    # Find average distance to enemies
    var total_dist: float = 0.0
    for enemy_pos: Vector2 in enemy_positions:
        total_dist += pos.distance_to(enemy_pos)
    var avg_dist: float = total_dist / float(enemy_positions.size())
    
    # Score based on how close we are to preferred distance
    var dist_diff: float = absf(avg_dist - preferred_distance)
    var score: float = 1.0 - clampf(dist_diff / preferred_distance, 0.0, 1.0)
    
    return clampf(score, 0.0, MAX_DISTANCE_SCORE)


## Calculates line of sight score (can we shoot enemies).
## Returns score in range [0, MAX_LOS_SCORE].
func _calculate_los_score(
    pos: Vector2,
    enemy_positions: PackedVector2Array,
    weapon_range: float
) -> float:
    if enemy_positions.is_empty():
        return MAX_LOS_SCORE * 0.5
    
    var enemies_in_range: int = 0
    var enemies_in_los: int = 0
    
    for enemy_pos: Vector2 in enemy_positions:
        var dist: float = pos.distance_to(enemy_pos)
        if dist <= weapon_range:
            enemies_in_range += 1
            # Simplified LOS check - in real implementation, use raycast
            enemies_in_los += 1
    
    var range_ratio: float = float(enemies_in_range) / float(enemy_positions.size())
    var los_ratio: float = float(enemies_in_los) / float(enemy_positions.size())
    
    var score: float = range_ratio * 0.5 + los_ratio * 0.5
    return clampf(score, 0.0, MAX_LOS_SCORE)


## Calculates cohesion score (near allies but not too near).
## Returns score in range [0, MAX_COHESION_SCORE].
func _calculate_cohesion_score(pos: Vector2, ally_positions: PackedVector2Array) -> float:
    if ally_positions.is_empty():
        return MAX_COHESION_SCORE * 0.5  # Neutral when no allies
    
    var total_score: float = 0.0
    
    for ally_pos: Vector2 in ally_positions:
        var dist: float = pos.distance_to(ally_pos)
        
        var ally_score: float = 0.0
        if dist < MIN_COHESION_DISTANCE:
            # Too close - penalty
            ally_score = 0.0
        elif dist >= MIN_COHESION_DISTANCE and dist <= MAX_COHESION_DISTANCE:
            # Good distance
            if dist <= IDEAL_COHESION_DISTANCE:
                # Approaching ideal
                ally_score = dist / IDEAL_COHESION_DISTANCE
            else:
                # Past ideal but still acceptable
                ally_score = 1.0 - (dist - IDEAL_COHESION_DISTANCE) / (MAX_COHESION_DISTANCE - IDEAL_COHESION_DISTANCE)
        else:
            # Too far
            ally_score = 0.2
        
        total_score += ally_score
    
    return clampf(total_score / float(ally_positions.size()), 0.0, MAX_COHESION_SCORE)


## Calculates kite score (maintain distance if range advantage).
## Returns score in range [0, MAX_KITE_SCORE].
func _calculate_kite_score(
    pos: Vector2,
    enemy_positions: PackedVector2Array,
    weapon_range: float
) -> float:
    if enemy_positions.is_empty():
        return MAX_KITE_SCORE * 0.5
    
    var optimal_kite_dist: float = weapon_range * KITE_OPTIMAL_RANGE_RATIO
    var total_score: float = 0.0
    
    for enemy_pos: Vector2 in enemy_positions:
        var dist: float = pos.distance_to(enemy_pos)
        
        # Ideal: at weapon range but enemy can't reach us
        var dist_diff: float = absf(dist - optimal_kite_dist)
        var score: float = 1.0 - clampf(dist_diff / weapon_range, 0.0, 1.0)
        
        # Bonus for being at max range
        if dist >= weapon_range * 0.9:
            score *= 1.2
        
        total_score += score
    
    return clampf(total_score / float(enemy_positions.size()), 0.0, MAX_KITE_SCORE)
