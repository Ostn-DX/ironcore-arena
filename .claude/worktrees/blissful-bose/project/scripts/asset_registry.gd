class_name AssetRegistry extends Node

## Central registry for all game assets with hot-reload support.
## Manages atlas textures, sprite frames, and asset variants.
## Use as an autoload singleton for global asset access.

signal registry_reloaded

const REGISTRY_PATH: String = "res://assets/registry/assets.json"
const DEFAULT_VARIANT: String = "high"

var _atlases: Dictionary = {}  ## atlas_id -> AtlasData
var _assets: Dictionary = {}   ## asset_key -> AssetData
var _sprite_frames_cache: Dictionary = {}  ## "asset_key:variant" -> SpriteFrames
var _current_variant: String = DEFAULT_VARIANT
var _atlas_loader: AtlasLoader = null


## Internal data class for atlas information
class AtlasData:
    var atlas_id: String
    var texture_path: String
    var regions_path: String
    var texture: Texture2D = null
    var regions: Dictionary = {}
    
    func _init(p_id: String, p_texture: String, p_regions: String) -> void:
        atlas_id = p_id
        texture_path = p_texture
        regions_path = p_regions


## Internal data class for asset information
class AssetData:
    var asset_key: String
    var variants: Dictionary = {}  ## variant_name -> VariantData
    
    func _init(p_key: String) -> void:
        asset_key = p_key


## Internal data class for variant information
class VariantData:
    var variant_name: String
    var atlas_id: String
    var frames: Dictionary = {}  ## animation_name -> FrameData
    
    func _init(p_name: String, p_atlas: String) -> void:
        variant_name = p_name
        atlas_id = p_atlas


## Internal data class for frame animation information
class FrameData:
    var animation_name: String
    var region_keys: PackedStringArray
    var fps: int = 10
    
    func _init(p_anim: String, p_regions: PackedStringArray, p_fps: int) -> void:
        animation_name = p_anim
        region_keys = p_regions
        fps = p_fps


func _ready() -> void:
    _atlas_loader = AtlasLoader.new()
    load_registry()


## Loads the asset registry from disk and builds internal data structures.
## Parses JSON registry, loads atlas metadata, and clears/rebuilds cache.
func load_registry() -> void:
    if not FileAccess.file_exists(REGISTRY_PATH):
        push_error("AssetRegistry: Registry file not found at " + REGISTRY_PATH)
        return
    
    var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
    if not file:
        push_error("AssetRegistry: Failed to open registry file: " + REGISTRY_PATH)
        return
    
    var json_text := file.get_as_text()
    file.close()
    
    var json := JSON.new()
    var error := json.parse(json_text)
    if error != OK:
        push_error("AssetRegistry: Failed to parse registry JSON: " + json.get_error_message())
        return
    
    var data: Dictionary = json.data
    
    # Clear existing data
    _atlases.clear()
    _assets.clear()
    _clear_cache()
    
    # Parse atlases
    if data.has("atlases"):
        _parse_atlases(data["atlases"])
    
    # Parse assets
    if data.has("assets"):
        _parse_assets(data["assets"])
    
    print("AssetRegistry: Loaded registry with ", _atlases.size(), " atlases and ", _assets.size(), " assets")


## Parses atlas definitions from registry data
func _parse_atlases(atlases_data: Dictionary) -> void:
    for atlas_id: String in atlases_data.keys():
        var atlas_info: Dictionary = atlases_data[atlas_id]
        var texture_path: String = atlas_info.get("texture", "")
        var regions_path: String = atlas_info.get("regions", "")
        
        if texture_path.is_empty():
            push_warning("AssetRegistry: Atlas '" + atlas_id + "' has no texture path")
            continue
        
        var atlas_data := AtlasData.new(atlas_id, texture_path, regions_path)
        _atlases[atlas_id] = atlas_data


## Parses asset definitions from registry data
func _parse_assets(assets_data: Dictionary) -> void:
    for asset_key: String in assets_data.keys():
        var asset_info: Dictionary = assets_data[asset_key]
        var asset_data := AssetData.new(asset_key)
        
        if asset_info.has("variants"):
            var variants: Dictionary = asset_info["variants"]
            for variant_name: String in variants.keys():
                var variant_info: Dictionary = variants[variant_name]
                var atlas_id: String = variant_info.get("atlas", "")
                
                if atlas_id.is_empty():
                    push_warning("AssetRegistry: Asset '" + asset_key + "' variant '" + variant_name + "' has no atlas")
                    continue
                
                var variant_data := VariantData.new(variant_name, atlas_id)
                
                # Parse frames
                if variant_info.has("frames"):
                    var frames: Dictionary = variant_info["frames"]
                    for anim_name: String in frames.keys():
                        var frame_info: Dictionary = frames[anim_name]
                        var regions: Array = frame_info.get("regions", [])
                        var fps: int = frame_info.get("fps", 10)
                        
                        var region_keys := PackedStringArray()
                        for region: String in regions:
                            region_keys.append(region)
                        
                        var frame_data := FrameData.new(anim_name, region_keys, fps)
                        variant_data.frames[anim_name] = frame_data
                
                asset_data.variants[variant_name] = variant_data
        
        _assets[asset_key] = asset_data


## Gets SpriteFrames for an asset key and variant.
## Returns cached SpriteFrames if available, otherwise builds from atlas.
## @param asset_key The unique identifier for the asset
## @param variant The quality variant (low/medium/high/ultra), uses current variant if empty
## @return SpriteFrames containing all animations for the asset
func get_sprite_frames(asset_key: String, variant: String = "") -> SpriteFrames:
    if asset_key.is_empty():
        push_error("AssetRegistry: Cannot get SpriteFrames with empty asset_key")
        return null
    
    var use_variant := variant if not variant.is_empty() else _current_variant
    var cache_key := asset_key + ":" + use_variant
    
    # Check cache first
    if _sprite_frames_cache.has(cache_key):
        return _sprite_frames_cache[cache_key]
    
    # Build SpriteFrames from atlas
    var sprite_frames := _build_sprite_frames(asset_key, use_variant)
    if sprite_frames:
        _sprite_frames_cache[cache_key] = sprite_frames
    
    return sprite_frames


## Builds SpriteFrames from atlas data for a specific asset and variant
func _build_sprite_frames(asset_key: String, variant: String) -> SpriteFrames:
    if not _assets.has(asset_key):
        push_error("AssetRegistry: Asset not found: " + asset_key)
        return null
    
    var asset_data: AssetData = _assets[asset_key]
    
    # Check if variant exists, fall back to first available variant
    var variant_data: VariantData = null
    if asset_data.variants.has(variant):
        variant_data = asset_data.variants[variant]
    elif asset_data.variants.size() > 0:
        # Fall back to first available variant
        var first_variant: String = asset_data.variants.keys()[0]
        variant_data = asset_data.variants[first_variant]
        push_warning("AssetRegistry: Variant '" + variant + "' not found for '" + asset_key + "', using '" + first_variant + "'")
    else:
        push_error("AssetRegistry: No variants found for asset: " + asset_key)
        return null
    
    # Load atlas if not already loaded
    if not _atlases.has(variant_data.atlas_id):
        push_error("AssetRegistry: Atlas not found: " + variant_data.atlas_id)
        return null
    
    var atlas_data: AtlasData = _atlases[variant_data.atlas_id]
    _load_atlas_data(atlas_data)
    
    if not atlas_data.texture:
        push_error("AssetRegistry: Failed to load atlas texture: " + atlas_data.texture_path)
        return null
    
    # Build SpriteFrames
    var sprite_frames := SpriteFrames.new()
    
    for anim_name: String in variant_data.frames.keys():
        var frame_data: FrameData = variant_data.frames[anim_name]
        
        # Add animation
        sprite_frames.add_animation(anim_name)
        sprite_frames.set_animation_loop(anim_name, anim_name != "death")  # Don't loop death animation
        sprite_frames.set_animation_speed(anim_name, frame_data.fps)
        
        # Add frames
        for region_key: String in frame_data.region_keys:
            if atlas_data.regions.has(region_key):
                var region: Rect2 = atlas_data.regions[region_key]
                var atlas_texture := AtlasTexture.new()
                atlas_texture.atlas = atlas_data.texture
                atlas_texture.region = region
                sprite_frames.add_frame(anim_name, atlas_texture)
            else:
                push_warning("AssetRegistry: Region '" + region_key + "' not found in atlas '" + variant_data.atlas_id + "'")
    
    return sprite_frames


## Loads atlas texture and regions if not already loaded
func _load_atlas_data(atlas_data: AtlasData) -> void:
    if atlas_data.texture != null:
        return  # Already loaded
    
    # Load texture
    if ResourceLoader.exists(atlas_data.texture_path):
        atlas_data.texture = load(atlas_data.texture_path) as Texture2D
    
    # Load regions
    if not atlas_data.regions_path.is_empty() and FileAccess.file_exists(atlas_data.regions_path):
        var file := FileAccess.open(atlas_data.regions_path, FileAccess.READ)
        if file:
            var json_text := file.get_as_text()
            file.close()
            
            var json := JSON.new()
            var error := json.parse(json_text)
            if error == OK:
                var regions_data: Dictionary = json.data
                for region_key: String in regions_data.keys():
                    var region_info: Dictionary = regions_data[region_key]
                    var x: float = region_info.get("x", 0)
                    var y: float = region_info.get("y", 0)
                    var w: float = region_info.get("w", 0)
                    var h: float = region_info.get("h", 0)
                    atlas_data.regions[region_key] = Rect2(x, y, w, h)


## Gets texture region for an atlas-based asset.
## Useful for single-frame assets or UI elements.
## @param asset_key The unique identifier for the asset
## @param variant The quality variant
## @param region_key The specific region identifier within the atlas
## @return Rect2 defining the region in the atlas texture
func get_texture_region(asset_key: String, variant: String, region_key: String) -> Rect2:
    if asset_key.is_empty() or region_key.is_empty():
        return Rect2()
    
    var use_variant := variant if not variant.is_empty() else _current_variant
    
    if not _assets.has(asset_key):
        push_error("AssetRegistry: Asset not found: " + asset_key)
        return Rect2()
    
    var asset_data: AssetData = _assets[asset_key]
    
    # Get variant data
    var variant_data: VariantData = null
    if asset_data.variants.has(use_variant):
        variant_data = asset_data.variants[use_variant]
    elif asset_data.variants.size() > 0:
        variant_data = asset_data.variants[asset_data.variants.keys()[0]]
    else:
        return Rect2()
    
    # Load atlas
    if not _atlases.has(variant_data.atlas_id):
        return Rect2()
    
    var atlas_data: AtlasData = _atlases[variant_data.atlas_id]
    _load_atlas_data(atlas_data)
    
    if atlas_data.regions.has(region_key):
        return atlas_data.regions[region_key]
    
    return Rect2()


## Gets the atlas texture for an atlas ID.
## @param atlas_id The unique identifier for the atlas
## @return The loaded Texture2D or null if not found
func get_atlas_texture(atlas_id: String) -> Texture2D:
    if not _atlases.has(atlas_id):
        push_error("AssetRegistry: Atlas not found: " + atlas_id)
        return null
    
    var atlas_data: AtlasData = _atlases[atlas_id]
    _load_atlas_data(atlas_data)
    
    return atlas_data.texture


## Gets a specific atlas region by key.
## @param atlas_id The unique identifier for the atlas
## @param region_key The specific region identifier
## @return Rect2 defining the region in the atlas texture
func get_atlas_region(atlas_id: String, region_key: String) -> Rect2:
    if not _atlases.has(atlas_id):
        return Rect2()
    
    var atlas_data: AtlasData = _atlases[atlas_id]
    _load_atlas_data(atlas_data)
    
    if atlas_data.regions.has(region_key):
        return atlas_data.regions[region_key]
    
    return Rect2()


## Reloads the registry from disk. Used for hot-reload functionality.
## Clears all caches and rebuilds from the registry file.
func reload() -> void:
    _clear_cache()
    _atlases.clear()
    _assets.clear()
    load_registry()
    registry_reloaded.emit()
    print("AssetRegistry: Reloaded from ", REGISTRY_PATH)


## Sets the current quality variant for asset loading.
## Clears the sprite frames cache when variant changes.
## @param variant The quality variant to use (low/medium/high/ultra)
func set_variant(variant: String) -> void:
    if variant == _current_variant:
        return
    _current_variant = variant
    _clear_cache()
    print("AssetRegistry: Variant set to ", variant)


## Gets the current quality variant.
## @return The current variant string
func get_variant() -> String:
    return _current_variant


## Clears the sprite frames cache.
## Called when variant changes or during reload.
func _clear_cache() -> void:
    _sprite_frames_cache.clear()


## Returns true if the asset key exists in the registry.
## @param asset_key The asset key to check
## @return true if asset exists
func has_asset(asset_key: String) -> bool:
    return _assets.has(asset_key)


## Returns an array of all registered asset keys.
## @return PackedStringArray of asset keys
func get_all_asset_keys() -> PackedStringArray:
    var keys := PackedStringArray()
    for key: String in _assets.keys():
        keys.append(key)
    return keys


## Returns an array of available variants for an asset.
## @param asset_key The asset key to query
## @return PackedStringArray of variant names, empty if asset not found
func get_asset_variants(asset_key: String) -> PackedStringArray:
    if not _assets.has(asset_key):
        return PackedStringArray()
    
    var variants := PackedStringArray()
    var asset_data: AssetData = _assets[asset_key]
    for variant: String in asset_data.variants.keys():
        variants.append(variant)
    
    return variants
