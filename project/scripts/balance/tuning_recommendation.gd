class_name TuningRecommendation extends RefCounted

## Represents a single tuning recommendation for game balance.
## This class encapsulates a proposed change to a game parameter,
## including the rationale, confidence level, and predicted effects.
##
## @tutorial: Create instance, populate fields, then use to_dictionary() for export

# Target identification
var target_id: String = ""
## Identifier for the target (e.g., "laser_rifle", "light_chassis")

var target_type: String = ""
## Type of target: "weapon", "chassis", "economy", "ability", "arena", "general"

var target_property: String = ""
## Specific property being tuned (e.g., "damage", "fire_rate", "health")

# Value information
var current_value: float = 0.0
## Current value of the parameter

var proposed_value: float = 0.0
## Proposed new value

var change_percent: float = 0.0
## Percentage change from current to proposed

var change_absolute: float = 0.0
## Absolute change value

# Recommendation details
var rationale: String = ""
## Explanation of why this change is recommended

var confidence: float = 0.0
## Confidence level from 0.0 to 1.0

var predicted_effect: String = ""
## Description of expected outcome

var priority: int = 0
## Priority level (1 = highest, 5 = lowest)

# Source information
var data_source: String = ""
## Source of the recommendation (e.g., "dps_analysis", "win_rate_analysis")

var sample_size: int = 0
## Number of data points supporting this recommendation

var related_metrics: Dictionary = {}
## Additional metrics that support this recommendation

# Implementation
var implementation_notes: String = ""
## Notes for implementing this change

var risk_level: String = "medium"
## Risk assessment: "low", "medium", "high"

var requires_testing: bool = true
## Whether this change should be validated with additional testing


## Converts the recommendation to a dictionary.
##
## @return: Dictionary representation of this recommendation
## @example:
##     var rec = TuningRecommendation.new()
##     rec.target_id = "laser_rifle"
##     rec.current_value = 15.0
##     rec.proposed_value = 12.0
##     var dict = rec.to_dictionary()
##     # dict = {"target_id": "laser_rifle", "current_value": 15.0, ...}
func to_dictionary() -> Dictionary:
	return {
		"target_id": target_id,
		"target_type": target_type,
		"target_property": target_property,
		"current_value": current_value,
		"proposed_value": proposed_value,
		"change_percent": change_percent,
		"change_absolute": change_absolute,
		"rationale": rationale,
		"confidence": confidence,
		"predicted_effect": predicted_effect,
		"priority": priority,
		"data_source": data_source,
		"sample_size": sample_size,
		"related_metrics": related_metrics,
		"implementation_notes": implementation_notes,
		"risk_level": risk_level,
		"requires_testing": requires_testing
	}


## Loads recommendation data from a dictionary.
##
## @param data: Dictionary containing recommendation data
## @return: This instance for method chaining
## @example:
##     var rec = TuningRecommendation.new()
##     rec.from_dictionary({"target_id": "rifle", "current_value": 10.0})
func from_dictionary(data: Dictionary) -> TuningRecommendation:
	target_id = data.get("target_id", "")
	target_type = data.get("target_type", "")
	target_property = data.get("target_property", "")
	current_value = data.get("current_value", 0.0)
	proposed_value = data.get("proposed_value", 0.0)
	change_percent = data.get("change_percent", 0.0)
	change_absolute = data.get("change_absolute", 0.0)
	rationale = data.get("rationale", "")
	confidence = data.get("confidence", 0.0)
	predicted_effect = data.get("predicted_effect", "")
	priority = data.get("priority", 0)
	data_source = data.get("data_source", "")
	sample_size = data.get("sample_size", 0)
	related_metrics = data.get("related_metrics", {})
	implementation_notes = data.get("implementation_notes", "")
	risk_level = data.get("risk_level", "medium")
	requires_testing = data.get("requires_testing", true)
	
	return self


## Computes the change values from current and proposed.
##
## @return: This instance for method chaining
## @example:
##     var rec = TuningRecommendation.new()
##     rec.current_value = 100.0
##     rec.proposed_value = 110.0
##     rec.compute_change()
##     # rec.change_percent = 10.0, rec.change_absolute = 10.0
func compute_change() -> TuningRecommendation:
	change_absolute = proposed_value - current_value
	
	if current_value != 0:
		change_percent = (change_absolute / current_value) * 100.0
	else:
		change_percent = 0.0
	
	return self


## Sets the change values and updates proposed value.
##
## @param percent: Percentage change
## @return: This instance for method chaining
## @example:
##     var rec = TuningRecommendation.new()
##     rec.current_value = 100.0
##     rec.set_percent_change(-10.0)
##     # rec.proposed_value = 90.0
func set_percent_change(percent: float) -> TuningRecommendation:
	change_percent = percent
	proposed_value = current_value * (1.0 + percent / 100.0)
	change_absolute = proposed_value - current_value
	
	return self


## Gets a human-readable summary of the recommendation.
##
## @return: Formatted string summary
## @example:
##     print(rec.get_summary())
##     # Output: "[HIGH] weapon:laser_rifle - Reduce damage from 15.0 to 12.0 (-20.0%)"
func get_summary() -> String:
	var priority_str: String
	match priority:
		1: priority_str = "[CRITICAL]"
		2: priority_str = "[HIGH]"
		3: priority_str = "[MEDIUM]"
		4: priority_str = "[LOW]"
		_: priority_str = "[INFO]"
	
	var change_direction: String = "Increase" if change_percent > 0 else "Reduce"
	
	return "%s %s:%s - %s %s from %.2f to %.2f (%.1f%%)" % [
		priority_str,
		target_type,
		target_id,
		change_direction,
		target_property,
		current_value,
		proposed_value,
		change_percent
	]


## Checks if this recommendation is significant enough to implement.
##
## @param min_confidence: Minimum confidence threshold (default 0.5)
## @param min_change_percent: Minimum change percentage (default 5.0)
## @return: true if recommendation is significant
## @example:
##     if rec.is_significant():
##         implement_change(rec)
func is_significant(min_confidence: float = 0.5, min_change_percent: float = 5.0) -> bool:
	if confidence < min_confidence:
		return false
	
	if abs(change_percent) < min_change_percent:
		return false
	
	return true


## Gets a formatted string for the confidence level.
##
## @return: Human-readable confidence string
## @example:
##     rec.confidence = 0.85
##     print(rec.get_confidence_string())  # "High (85%)"
func get_confidence_string() -> String:
	if confidence >= 0.9:
		return "Very High (%.0f%%)" % (confidence * 100)
	elif confidence >= 0.7:
		return "High (%.0f%%)" % (confidence * 100)
	elif confidence >= 0.5:
		return "Medium (%.0f%%)" % (confidence * 100)
	elif confidence >= 0.3:
		return "Low (%.0f%%)" % (confidence * 100)
	else:
		return "Very Low (%.0f%%)" % (confidence * 100)


## Creates a recommendation from statistical analysis.
##
## @param target_id: Target identifier
## @param target_type: Type of target
## @param current: Current value
## @param target: Target/desired value
## @param z_score: Statistical z-score
## @param data_points: Number of data points
## @return: Configured TuningRecommendation
## @example:
##     var rec = TuningRecommendation.from_statistical_analysis(
##         "rifle", "weapon", 15.0, 12.0, 2.5, 1000
##     )
static func from_statistical_analysis(
	target_id: String,
	target_type: String,
	current: float,
	target: float,
	z_score: float,
	data_points: int
) -> TuningRecommendation:
	var rec := TuningRecommendation.new()
	rec.target_id = target_id
	rec.target_type = target_type
	rec.current_value = current
	rec.proposed_value = target
	rec.compute_change()
	
	# Confidence based on z-score and sample size
	var z_confidence: float = clampf(abs(z_score) / 3.0, 0.0, 1.0)
	var sample_confidence: float = clampf(data_points / 1000.0, 0.0, 1.0)
	rec.confidence = (z_confidence + sample_confidence) / 2.0
	
	rec.sample_size = data_points
	rec.data_source = "statistical_analysis"
	
	# Priority based on z-score
	if abs(z_score) > 3.0:
		rec.priority = 1
	elif abs(z_score) > 2.0:
		rec.priority = 2
	elif abs(z_score) > 1.5:
		rec.priority = 3
	else:
		rec.priority = 4
	
	# Risk based on change magnitude
	if abs(rec.change_percent) > 30:
		rec.risk_level = "high"
	elif abs(rec.change_percent) > 15:
		rec.risk_level = "medium"
	else:
		rec.risk_level = "low"
	
	return rec


## Creates a nerf recommendation (reduce value).
##
## @param target_id: Target identifier
## @param target_type: Type of target
## @param current: Current value
## @param reduction_percent: Percentage to reduce
## @return: Configured TuningRecommendation
static func create_nerf(
	target_id: String,
	target_type: String,
	current: float,
	reduction_percent: float
) -> TuningRecommendation:
	var rec := TuningRecommendation.new()
	rec.target_id = target_id
	rec.target_type = target_type
	rec.current_value = current
	rec.set_percent_change(-abs(reduction_percent))
	rec.rationale = "Overperforming - reducing to bring in line with targets"
	rec.predicted_effect = "Will reduce effectiveness and improve balance"
	return rec


## Creates a buff recommendation (increase value).
##
## @param target_id: Target identifier
## @param target_type: Type of target
## @param current: Current value
## @param increase_percent: Percentage to increase
## @return: Configured TuningRecommendation
static func create_buff(
	target_id: String,
	target_type: String,
	current: float,
	increase_percent: float
) -> TuningRecommendation:
	var rec := TuningRecommendation.new()
	rec.target_id = target_id
	rec.target_type = target_type
	rec.current_value = current
	rec.set_percent_change(abs(increase_percent))
	rec.rationale = "Underperforming - increasing to meet target performance"
	rec.predicted_effect = "Will improve effectiveness and competitive viability"
	return rec


## Compares two recommendations by priority and confidence.
##
## @param a: First recommendation
## @param b: Second recommendation
## @return: true if a should come before b
static func sort_by_priority(a: TuningRecommendation, b: TuningRecommendation) -> bool:
	# First sort by priority (lower number = higher priority)
	if a.priority != b.priority:
		return a.priority < b.priority
	
	# Then by confidence (higher = first)
	return a.confidence > b.confidence


## Gets a color code for this recommendation's priority.
##
## @return: Color string (for UI display)
## @example:
##     print(rec.get_priority_color())  # "#ff0000" for critical
func get_priority_color() -> String:
	match priority:
		1: return "#ff0000"  # Red - Critical
		2: return "#ff8800"  # Orange - High
		3: return "#ffcc00"  # Yellow - Medium
		4: return "#00cc00"  # Green - Low
		_: return "#888888"  # Gray - Info
