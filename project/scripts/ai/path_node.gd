class_name PathNode extends RefCounted
## Internal node for A* pathfinding
##
## Represents a single grid cell in the A* search space.
## Stores position, costs, and parent reference for path reconstruction.

## Grid position of this node
var position: Vector2i

## Cost from start to this node (actual path cost)
var g_cost: float = 0.0

## Heuristic cost from this node to goal (estimated)
var h_cost: float = 0.0

## Parent node for path reconstruction
var parent: PathNode = null


## Returns the total f-cost (g_cost + h_cost)
func f_cost() -> float:
	return g_cost + h_cost


## Compares two nodes by position for equality checks
func equals(other: PathNode) -> bool:
	return position == other.position


## Creates a copy of this node
func duplicate() -> PathNode:
	var copy := PathNode.new()
	copy.position = position
	copy.g_cost = g_cost
	copy.h_cost = h_cost
	copy.parent = parent
	return copy
