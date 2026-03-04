class_name AssetVariantPolicy extends RefCounted

## Determines which asset variant to use based on settings and system capabilities.
## Supports manual tier selection or automatic detection based on hardware.
## Use this to configure quality settings for your game.

enum QualityTier {
    LOW,      ## Minimal quality, maximum performance
    MEDIUM,   ## Balanced quality and performance
    HIGH,     ## High quality, good performance
    ULTRA     ## Maximum quality, may impact performance
}

## Mapping from quality tiers to variant strings
const TIER_VARIANTS: Dictionary = {
    QualityTier.LOW: "low",
    QualityTier.MEDIUM: "medium",
    QualityTier.HIGH: "high",
    QualityTier.ULTRA: "ultra"
}

## Reverse mapping from variant strings to quality tiers
const VARIANT_TIERS: Dictionary = {
    "low": QualityTier.LOW,
    "medium": QualityTier.MEDIUM,
    "high": QualityTier.HIGH,
    "ultra": QualityTier.ULTRA
}

## Memory thresholds for auto-detection (in MB)
const MEMORY_THRESHOLD_LOW: int = 2048      ## 2GB
const MEMORY_THRESHOLD_MEDIUM: int = 4096   ## 4GB
const MEMORY_THRESHOLD_HIGH: int = 8192     ## 8GB

## Screen resolution thresholds for auto-detection
const RESOLUTION_THRESHOLD_LOW: Vector2i = Vector2i(1280, 720)
const RESOLUTION_THRESHOLD_MEDIUM: Vector2i = Vector2i(1920, 1080)
const RESOLUTION_THRESHOLD_HIGH: Vector2i = Vector2i(2560, 1440)

var _current_tier: QualityTier = QualityTier.HIGH
var _auto_detected: bool = false
var _custom_variant_overrides: Dictionary = {}  ## asset_key -> variant override


## Chooses the variant string based on current policy.
## @return The variant string (low/medium/high/ultra)
func choose_variant() -> String:
    return TIER_VARIANTS.get(_current_tier, "high")


## Chooses variant for a specific asset, respecting overrides.
## @param asset_key The asset to get variant for
## @return The variant string for the asset
func choose_variant_for_asset(asset_key: String) -> String:
    # Check for override first
    if _custom_variant_overrides.has(asset_key):
        return _custom_variant_overrides[asset_key]
    
    return choose_variant()


## Sets the quality tier directly.
## @param tier The quality tier to use
func set_tier(tier: QualityTier) -> void:
    _current_tier = tier
    _auto_detected = false
    print("AssetVariantPolicy: Quality tier set to ", _get_tier_name(tier))


## Gets the current quality tier.
## @return The current quality tier
func get_tier() -> QualityTier:
    return _current_tier


## Gets the current quality tier as a string.
## @return The tier name (low/medium/high/ultra)
func get_tier_name() -> String:
    return _get_tier_name(_current_tier)


## Sets variant by string name.
## @param variant The variant string (low/medium/high/ultra)
func set_variant(variant: String) -> void:
    if VARIANT_TIERS.has(variant):
        _current_tier = VARIANT_TIERS[variant]
        _auto_detected = false
        print("AssetVariantPolicy: Variant set to ", variant)
    else:
        push_warning("AssetVariantPolicy: Unknown variant '" + variant + "', keeping current tier")


## Auto-detects the appropriate tier based on system capabilities.
## Considers available memory, screen resolution, and rendering method.
func auto_detect() -> void:
    var detected_tier := QualityTier.MEDIUM
    
    # Check available memory
    var memory_score := _get_memory_score()
    
    # Check screen resolution
    var resolution_score := _get_resolution_score()
    
    # Check rendering method
    var rendering_score := _get_rendering_score()
    
    # Combine scores (take average)
    var combined_score := (memory_score + resolution_score + rendering_score) / 3.0
    
    # Map to tier
    if combined_score >= 3.0:
        detected_tier = QualityTier.ULTRA
    elif combined_score >= 2.5:
        detected_tier = QualityTier.HIGH
    elif combined_score >= 1.5:
        detected_tier = QualityTier.MEDIUM
    else:
        detected_tier = QualityTier.LOW
    
    _current_tier = detected_tier
    _auto_detected = true
    
    print("AssetVariantPolicy: Auto-detected tier '", _get_tier_name(detected_tier), 
          "' (memory:", memory_score, ", resolution:", resolution_score, ", rendering:", rendering_score, ")")


## Returns true if the current tier was auto-detected.
## @return true if auto-detected
func was_auto_detected() -> bool:
    return _auto_detected


## Sets a custom variant override for a specific asset.
## @param asset_key The asset to override
## @param variant The variant to use for this asset
func set_asset_override(asset_key: String, variant: String) -> void:
    _custom_variant_overrides[asset_key] = variant


## Clears a custom variant override.
## @param asset_key The asset to clear override for
func clear_asset_override(asset_key: String) -> void:
    if _custom_variant_overrides.has(asset_key):
        _custom_variant_overrides.erase(asset_key)


## Clears all custom variant overrides.
func clear_all_overrides() -> void:
    _custom_variant_overrides.clear()


## Gets the variant override for an asset if set.
## @param asset_key The asset to check
## @return The override variant or empty string if none
func get_asset_override(asset_key: String) -> String:
    return _custom_variant_overrides.get(asset_key, "")


## Checks if an asset has a variant override.
## @param asset_key The asset to check
## @return true if override exists
func has_asset_override(asset_key: String) -> bool:
    return _custom_variant_overrides.has(asset_key)


## Gets memory-based quality score (0-4 scale).
## Higher score = more memory = higher quality possible
func _get_memory_score() -> float:
    var static_memory := OS.get_static_memory_usage()
    var static_memory_mb := static_memory / (1024 * 1024)
    
    # Get available memory if possible
    var available_memory_mb := static_memory_mb
    
    # Map to score
    if available_memory_mb >= MEMORY_THRESHOLD_HIGH:
        return 4.0  # ULTRA
    elif available_memory_mb >= MEMORY_THRESHOLD_MEDIUM:
        return 3.0  # HIGH
    elif available_memory_mb >= MEMORY_THRESHOLD_LOW:
        return 2.0  # MEDIUM
    else:
        return 1.0  # LOW


## Gets resolution-based quality score (0-4 scale).
## Higher score = higher resolution = higher quality desired
func _get_resolution_score() -> float:
    var viewport_size := DisplayServer.window_get_size()
    var pixel_count := viewport_size.x * viewport_size.y
    
    # Calculate threshold pixel counts
    var low_pixels := RESOLUTION_THRESHOLD_LOW.x * RESOLUTION_THRESHOLD_LOW.y
    var medium_pixels := RESOLUTION_THRESHOLD_MEDIUM.x * RESOLUTION_THRESHOLD_MEDIUM.y
    var high_pixels := RESOLUTION_THRESHOLD_HIGH.x * RESOLUTION_THRESHOLD_HIGH.y
    
    # Map to score
    if pixel_count >= high_pixels:
        return 4.0  # ULTRA
    elif pixel_count >= medium_pixels:
        return 3.0  # HIGH
    elif pixel_count >= low_pixels:
        return 2.0  # MEDIUM
    else:
        return 1.0  # LOW


## Gets rendering method-based quality score (0-4 scale).
## Forward+ = higher score, Compatibility = lower score
func _get_rendering_score() -> float:
    var rendering_method := ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus")
    
    match rendering_method:
        "forward_plus":
            return 4.0  # ULTRA
        "mobile":
            return 3.0  # HIGH
        "gl_compatibility":
            return 2.0  # MEDIUM
        _:
            return 2.5  # Default to medium-high


## Gets the string name for a quality tier.
## @param tier The quality tier
## @return The tier name
func _get_tier_name(tier: QualityTier) -> String:
    match tier:
        QualityTier.LOW:
            return "low"
        QualityTier.MEDIUM:
            return "medium"
        QualityTier.HIGH:
            return "high"
        QualityTier.ULTRA:
            return "ultra"
        _:
            return "high"


## Gets a description of the current quality tier.
## @return Human-readable description
func get_tier_description() -> String:
    match _current_tier:
        QualityTier.LOW:
            return "Low quality - Maximum performance, minimal visual fidelity"
        QualityTier.MEDIUM:
            return "Medium quality - Balanced performance and visuals"
        QualityTier.HIGH:
            return "High quality - Excellent visuals with good performance"
        QualityTier.ULTRA:
            return "Ultra quality - Maximum visual fidelity"
        _:
            return "Unknown quality tier"


## Serializes the policy to a dictionary for saving.
## @return Dictionary with policy settings
func to_dict() -> Dictionary:
    return {
        "tier": get_tier_name(),
        "auto_detected": _auto_detected,
        "overrides": _custom_variant_overrides.duplicate()
    }


## Loads policy from a dictionary.
## @param data Dictionary with policy settings
func from_dict(data: Dictionary) -> void:
    if data.has("tier"):
        set_variant(data["tier"])
    
    if data.has("auto_detected"):
        _auto_detected = data["auto_detected"]
    
    if data.has("overrides"):
        _custom_variant_overrides = data["overrides"].duplicate()


## Gets all available tier names.
## @return PackedStringArray of tier names
func get_all_tier_names() -> PackedStringArray:
    return PackedStringArray(["low", "medium", "high", "ultra"])


## Gets all available quality tiers.
## @return Array of QualityTier values
func get_all_tiers() -> Array:
    return [QualityTier.LOW, QualityTier.MEDIUM, QualityTier.HIGH, QualityTier.ULTRA]


## Compares two quality tiers.
## @param tier_a First tier to compare
## @param tier_b Second tier to compare
## @return Negative if a < b, 0 if equal, positive if a > b
static func compare_tiers(tier_a: QualityTier, tier_b: QualityTier) -> int:
    return int(tier_a) - int(tier_b)


## Returns true if tier_a is higher quality than tier_b.
## @param tier_a First tier to compare
## @param tier_b Second tier to compare
## @return true if tier_a > tier_b
static func is_higher_quality(tier_a: QualityTier, tier_b: QualityTier) -> bool:
    return compare_tiers(tier_a, tier_b) > 0


## Returns true if tier_a is lower quality than tier_b.
## @param tier_a First tier to compare
## @param tier_b Second tier to compare
## @return true if tier_a < tier_b
static func is_lower_quality(tier_a: QualityTier, tier_b: QualityTier) -> bool:
    return compare_tiers(tier_a, tier_b) < 0
