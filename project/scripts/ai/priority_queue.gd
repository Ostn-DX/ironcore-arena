class_name PriorityQueue extends RefCounted
## Binary heap priority queue with deterministic ordering for equal f-costs
##
## Provides O(log n) insertion and removal operations.
## Ensures deterministic behavior by tie-breaking equal f-costs by position.

var _heap: Array[PathNode] = []


## Adds a node to the priority queue
## Maintains heap property by bubbling up
func enqueue(node: PathNode) -> void:
	_heap.append(node)
	_bubble_up(_heap.size() - 1)


## Removes and returns the node with lowest f-cost
## Uses position as tie-breaker for deterministic ordering
## Returns null if queue is empty
func dequeue() -> PathNode:
	if _heap.is_empty():
		return null
	
	var result: PathNode = _heap[0]
	var last: PathNode = _heap.pop_back()
	
	if not _heap.is_empty():
		_heap[0] = last
		_bubble_down(0)
	
	return result


## Returns true if the queue contains no elements
func is_empty() -> bool:
	return _heap.is_empty()


## Returns the number of elements in the queue
func size() -> int:
	return _heap.size()


## Removes all elements from the queue
func clear() -> void:
	_heap.clear()


## Checks if a node with the given position exists in the queue
func contains_position(pos: Vector2i) -> bool:
	for node: PathNode in _heap:
		if node.position == pos:
			return true
	return false


## Returns the node at the given position if it exists, null otherwise
func get_node_at_position(pos: Vector2i) -> PathNode:
	for node: PathNode in _heap:
		if node.position == pos:
			return node
	return null


## Internal: Moves element up to maintain heap property
func _bubble_up(index: int) -> void:
	while index > 0:
		var parent_index: int = (index - 1) / 2
		if _compare_nodes(_heap[index], _heap[parent_index]) < 0:
			_swap(index, parent_index)
			index = parent_index
		else:
			break


## Internal: Moves element down to maintain heap property
func _bubble_down(index: int) -> void:
	var size: int = _heap.size()
	
	while true:
		var left_child: int = 2 * index + 1
		var right_child: int = 2 * index + 2
		var smallest: int = index
		
		if left_child < size and _compare_nodes(_heap[left_child], _heap[smallest]) < 0:
			smallest = left_child
		
		if right_child < size and _compare_nodes(_heap[right_child], _heap[smallest]) < 0:
			smallest = right_child
		
		if smallest != index:
			_swap(index, smallest)
			index = smallest
		else:
			break


## Internal: Compares two nodes for heap ordering
## Returns negative if a should come before b (lower f-cost or tie-break)
## Tie-breaking: lower x, then lower y for deterministic ordering
func _compare_nodes(a: PathNode, b: PathNode) -> int:
	var f_diff: float = a.f_cost() - b.f_cost()
	
	# Primary: compare by f-cost
	if f_diff < -0.0001:
		return -1
	elif f_diff > 0.0001:
		return 1
	
	# Secondary tie-break: lower x position
	if a.position.x < b.position.x:
		return -1
	elif a.position.x > b.position.x:
		return 1
	
	# Tertiary tie-break: lower y position
	if a.position.y < b.position.y:
		return -1
	elif a.position.y > b.position.y:
		return 1
	
	return 0


## Internal: Swaps two elements in the heap
func _swap(i: int, j: int) -> void:
	var temp: PathNode = _heap[i]
	_heap[i] = _heap[j]
	_heap[j] = temp
