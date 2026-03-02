class_name AtlasLoader extends RefCounted

## Loads prebuilt atlas textures and region metadata.
## Handles caching of loaded atlases for performance.
## Supports both JSON and TRES region formats.

## Internal data structure for cached atlas information
class CachedAtlas:
    var atlas_id: String
    var texture: Texture2D = null
    var regions: Dictionary = {}
    var last_loaded: int = 0
    
    func _init(p_id: String) -> void:
        atlas_id = p_id


const ATLAS_BASE_PATH: String = "res://assets/atlases/"
const DEFAULT_EXTENSION: String = ".png"
const REGIONS_EXTENSION_JSON: String = ".json"
const REGIONS_EXTENSION_TRES: String = ".tres"

var _loaded_atlases: Dictionary = {}  ## atlas_id -> CachedAtlas


## Loads an atlas by ID.
## Looks for texture at res://assets/atlases/{atlas_id}.png
## @param atlas_id The unique identifier for the atlas
## @return The loaded Texture2D or null if not found
func load_atlas(atlas_id: String) -> Texture2D:
    if atlas_id.is_empty():
        push_error("AtlasLoader: Cannot load atlas with empty ID")
        return null
    
    # Check cache first
    if _loaded_atlases.has(atlas_id):
        var cached: CachedAtlas = _loaded_atlases[atlas_id]
        if cached.texture != null:
            return cached.texture
    
    # Build texture path
    var texture_path := ATLAS_BASE_PATH + atlas_id + DEFAULT_EXTENSION
    
    # Load texture
    var texture: Texture2D = null
    if ResourceLoader.exists(texture_path):
        texture = load(texture_path) as Texture2D
    else:
        # Try without extension
        texture_path = ATLAS_BASE_PATH + atlas_id
        if ResourceLoader.exists(texture_path):
            texture = load(texture_path) as Texture2D
    
    if not texture:
        push_error("AtlasLoader: Failed to load atlas texture: " + texture_path)
        return null
    
    # Cache the atlas
    var cached_atlas: CachedAtlas
    if _loaded_atlases.has(atlas_id):
        cached_atlas = _loaded_atlases[atlas_id]
    else:
        cached_atlas = CachedAtlas.new(atlas_id)
        _loaded_atlases[atlas_id] = cached_atlas
    
    cached_atlas.texture = texture
    cached_atlas.last_loaded = Time.get_ticks_msec()
    
    return texture


## Loads region metadata for an atlas.
## Supports both JSON and TRES formats. JSON is preferred.
## @param atlas_id The unique identifier for the atlas
## @return Dictionary mapping region keys to Rect2 values
func load_regions(atlas_id: String) -> Dictionary:
    if atlas_id.is_empty():
        push_error("AtlasLoader: Cannot load regions with empty atlas ID")
        return {}
    
    # Check cache first
    if _loaded_atlases.has(atlas_id):
        var cached: CachedAtlas = _loaded_atlases[atlas_id]
        if cached.regions.size() > 0:
            return cached.regions.duplicate()
    
    # Try JSON first, then TRES
    var regions := _load_regions_json(atlas_id)
    if regions.is_empty():
        regions = _load_regions_tres(atlas_id)
    
    # Cache the regions
    if not regions.is_empty():
        var cached_atlas: CachedAtlas
        if _loaded_atlases.has(atlas_id):
            cached_atlas = _loaded_atlases[atlas_id]
        else:
            cached_atlas = CachedAtlas.new(atlas_id)
            _loaded_atlases[atlas_id] = cached_atlas
        
        cached_atlas.regions = regions.duplicate()
    
    return regions


## Loads regions from a JSON file.
## Expected format: {"region_name": {"x": 0, "y": 0, "w": 32, "h": 32}}
## @param atlas_id The atlas ID to load regions for
## @return Dictionary of region data
func _load_regions_json(atlas_id: String) -> Dictionary:
    var regions_path := ATLAS_BASE_PATH + atlas_id + "_regions" + REGIONS_EXTENSION_JSON
    
    if not FileAccess.file_exists(regions_path):
        # Try alternative naming: {atlas_id}.json
        regions_path = ATLAS_BASE_PATH + atlas_id + REGIONS_EXTENSION_JSON
        if not FileAccess.file_exists(regions_path):
            return {}
    
    var file := FileAccess.open(regions_path, FileAccess.READ)
    if not file:
        push_error("AtlasLoader: Failed to open regions file: " + regions_path)
        return {}
    
    var json_text := file.get_as_text()
    file.close()
    
    var json := JSON.new()
    var error := json.parse(json_text)
    if error != OK:
        push_error("AtlasLoader: Failed to parse regions JSON: " + json.get_error_message())
        return {}
    
    var regions_data: Dictionary = json.data
    var regions: Dictionary = {}
    
    for region_key: String in regions_data.keys():
        var region_info: Dictionary = regions_data[region_key]
        
        # Support both {x,y,w,h} and {x,y,width,height} formats
        var x: float = region_info.get("x", 0.0)
        var y: float = region_info.get("y", 0.0)
        var w: float = region_info.get("w", region_info.get("width", 0.0))
        var h: float = region_info.get("h", region_info.get("height", 0.0))
        
        regions[region_key] = Rect2(x, y, w, h)
    
    return regions


## Loads regions from a Godot resource (TRES) file.
## Expected format: AtlasRegions resource with a regions dictionary.
## @param atlas_id The atlas ID to load regions for
## @return Dictionary of region data
func _load_regions_tres(atlas_id: String) -> Dictionary:
    var regions_path := ATLAS_BASE_PATH + atlas_id + "_regions" + REGIONS_EXTENSION_TRES
    
    if not ResourceLoader.exists(regions_path):
        # Try alternative naming
        regions_path = ATLAS_BASE_PATH + atlas_id + REGIONS_EXTENSION_TRES
        if not ResourceLoader.exists(regions_path):
            return {}
    
    var resource := load(regions_path)
    if not resource:
        return {}
    
    # Check if it's a custom AtlasRegions resource
    if resource.has_method("get_regions"):
        return resource.get_regions()
    
    # Check if it has a regions property
    if "regions" in resource:
        var regions_data: Dictionary = resource.regions
        var regions: Dictionary = {}
        
        for region_key: String in regions_data.keys():
            var value = regions_data[region_key]
            if value is Rect2:
                regions[region_key] = value
            elif value is Rect2i:
                regions[region_key] = Rect2(value)
            elif value is Dictionary or value is Array:
                # Try to convert from array/dict format
                var x: float = 0.0
                var y: float = 0.0
                var w: float = 0.0
                var h: float = 0.0
                
                if value is Array and value.size() >= 4:
                    x = float(value[0])
                    y = float(value[1])
                    w = float(value[2])
                    h = float(value[3])
                elif value is Dictionary:
                    x = value.get("x", 0.0)
                    y = value.get("y", 0.0)
                    w = value.get("w", value.get("width", 0.0))
                    h = value.get("h", value.get("height", 0.0))
                
                regions[region_key] = Rect2(x, y, w, h)
        
        return regions
    
    return {}


## Gets a specific region from an atlas.
## Loads the atlas and regions if not already cached.
## @param atlas_id The unique identifier for the atlas
## @param region_key The specific region identifier
## @return Rect2 defining the region, or empty Rect2 if not found
func get_region(atlas_id: String, region_key: String) -> Rect2:
    if atlas_id.is_empty() or region_key.is_empty():
        return Rect2()
    
    # Check cache first
    if _loaded_atlases.has(atlas_id):
        var cached: CachedAtlas = _loaded_atlases[atlas_id]
        if cached.regions.has(region_key):
            return cached.regions[region_key]
    
    # Load regions
    var regions := load_regions(atlas_id)
    if regions.has(region_key):
        return regions[region_key]
    
    return Rect2()


## Gets all region keys for an atlas.
## @param atlas_id The unique identifier for the atlas
## @return PackedStringArray of all region keys
func get_region_keys(atlas_id: String) -> PackedStringArray:
    if atlas_id.is_empty():
        return PackedStringArray()
    
    var regions := load_regions(atlas_id)
    var keys := PackedStringArray()
    for key: String in regions.keys():
        keys.append(key)
    return keys


## Checks if an atlas is loaded.
## @param atlas_id The atlas ID to check
## @return true if the atlas is cached
func is_atlas_loaded(atlas_id: String) -> bool:
    return _loaded_atlases.has(atlas_id)


## Gets cached atlas info.
## @param atlas_id The atlas ID to query
## @return CachedAtlas or null if not loaded
func get_cached_atlas(atlas_id: String) -> CachedAtlas:
    if _loaded_atlases.has(atlas_id):
        return _loaded_atlases[atlas_id]
    return null


## Clears all loaded atlases from cache.
## Call this to free memory or force reload.
func clear() -> void:
    _loaded_atlases.clear()


## Clears a specific atlas from cache.
## @param atlas_id The atlas ID to clear
func clear_atlas(atlas_id: String) -> void:
    if _loaded_atlases.has(atlas_id):
        _loaded_atlases.erase(atlas_id)


## Preloads an atlas and its regions into cache.
## Useful for loading screens or pre-caching critical assets.
## @param atlas_id The atlas ID to preload
## @return true if successfully preloaded
func preload_atlas(atlas_id: String) -> bool:
    var texture := load_atlas(atlas_id)
    var regions := load_regions(atlas_id)
    return texture != null and regions.size() > 0


## Gets the number of cached atlases.
## @return Number of atlases in cache
func get_cache_size() -> int:
    return _loaded_atlases.size()


## Returns a list of all cached atlas IDs.
## @return PackedStringArray of cached atlas IDs
func get_cached_atlas_ids() -> PackedStringArray:
    var ids := PackedStringArray()
    for id: String in _loaded_atlases.keys():
        ids.append(id)
    return ids
