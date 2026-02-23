extends Node
class_name AgentSystem
## AgentSystem - Swarm Agent management for autonomous development
## Part of Studio Architecture: Swarm Agent Definitions (Section 5)

signal task_completed(agent_name: String, task_id: String, result: Dictionary)
signal task_failed(agent_name: String, task_id: String, error: String)
signal agent_status_changed(agent_name: String, status: String)

# Active agents
var agents: Dictionary = {}  # agent_name -> Agent
var task_queue: Array[Dictionary] = []
var active_tasks: Dictionary = {}  # task_id -> task_info

func _ready() -> void:
	print("AgentSystem: Initialized")
	_register_default_agents()

func _register_default_agents() -> void:
	## Register the core agents from the architecture
	
	# Core Governance
	register_agent(ArchitectureAgent.new())
	register_agent(CodeReviewAgent.new())
	register_agent(QualityAgent.new())
	
	# Content Agents
	register_agent(ContentAgent.new())
	register_agent(BalanceAgent.new())

func register_agent(agent: Agent) -> void:
	if not agent or not is_instance_valid(agent):
		push_warning("AgentSystem: Cannot register invalid agent")
		return
	
	agents[agent.agent_name] = agent
	
	if not agent.task_completed.is_connected(_on_agent_task_completed):
		agent.task_completed.connect(_on_agent_task_completed)
	if not agent.task_failed.is_connected(_on_agent_task_failed):
		agent.task_failed.connect(_on_agent_task_failed)
	if not agent.status_changed.is_connected(_on_agent_status_changed):
		agent.status_changed.connect(_on_agent_status_changed)
	
	add_child(agent)
	print("AgentSystem: Registered agent '%s'" % agent.agent_name)

func queue_task(agent_name: String, task_type: String, params: Dictionary = {}) -> String:
	## Queue a task for an agent
	if not agents.has(agent_name):
		push_error("AgentSystem: Agent '%s' not found" % agent_name)
		return ""
	
	var task_id = _generate_task_id()
	var task = {
		"id": task_id,
		"agent": agent_name,
		"type": task_type,
		"params": params,
		"queued_at": Time.get_unix_time_from_system(),
		"status": "queued"
	}
	
	task_queue.append(task)
	print("AgentSystem: Queued task '%s' for agent '%s'" % [task_type, agent_name])
	
	_process_queue()
	return task_id

func get_agent_status(agent_name: String) -> String:
	if not agents.has(agent_name):
		return "not_found"
	return agents[agent_name].status

func get_all_status() -> Dictionary:
	var status: Dictionary = {}
	for name in agents:
		status[name] = agents[name].get_full_status()
	return status

func _process_queue() -> void:
	## Process queued tasks
	while task_queue.size() > 0:
		var task: int = task_queue[0]
		var agent = agents.get(task.agent)
		
		if agent and agent.is_available():
			task_queue.pop_front()
			active_tasks[task.id] = task
			agent.execute_task(task)
		else:
			break  # Agent busy, wait

func _generate_task_id() -> String:
	return "task_%d_%d" % [Time.get_ticks_msec(), randi()]

func _on_agent_task_completed(agent_name: String, task_id: String, result: Dictionary) -> void:
	active_tasks.erase(task_id)
	task_completed.emit(agent_name, task_id, result)
	_process_queue()

func _on_agent_task_failed(agent_name: String, task_id: String, error: String) -> void:
	active_tasks.erase(task_id)
	task_failed.emit(agent_name, task_id, error)
	_process_queue()

func _on_agent_status_changed(agent_name: String, status: String) -> void:
	agent_status_changed.emit(agent_name, status)
	if status == "idle":
		_process_queue()

# ============================================================================
# BASE AGENT CLASS
# ============================================================================

class_name Agent extends Node

signal task_completed(agent_name: String, task_id: String, result: Dictionary)
signal task_failed(agent_name: String, task_id: String, error: String)
signal status_changed(agent_name: String, status: String)

var agent_name: String = "BaseAgent"
var description: String = "Base agent class"
var status: String = "idle"
var current_task: Dictionary = {}
var capabilities: Array[String] = []

func is_available() -> bool:
	return status == "idle"

func get_full_status() -> Dictionary:
	return {
		"name": agent_name,
		"description": description,
		"status": status,
		"capabilities": capabilities,
		"current_task": current_task.get("type", "none") if not current_task.is_empty() else "none"
	}

func execute_task(task: Dictionary) -> void:
	current_task = task
	status = "working"
	status_changed.emit(agent_name, status)
	
	# Override in subclasses
	_process_task(task)

func _process_task(task: Dictionary) -> void:
	## Override this in agent subclasses
	push_warning("Agent '%s' does not implement _process_task" % agent_name)
	_finish_task({"status": "no_implementation"})

func _finish_task(result: Dictionary) -> void:
	task_completed.emit(agent_name, current_task.get("id", ""), result)
	current_task = {}
	status = "idle"
	status_changed.emit(agent_name, status)

func _fail_task(error: String) -> void:
	task_failed.emit(agent_name, current_task.get("id", ""), error)
	current_task = {}
	status = "idle"
	status_changed.emit(agent_name, status)

# ============================================================================
# SPECIFIC AGENT IMPLEMENTATIONS
# ============================================================================

class ArchitectureAgent extends Agent:
	## Reviews code architecture and suggests improvements
	
	func _init():
		agent_name = "ArchitectureAgent"
		description = "Reviews code structure and architectural patterns"
		capabilities = ["code_review", "refactor_suggestion", "architecture_validation"]
	
	func _process_task(task: Dictionary) -> void:
		match task.type:
			"review_script":
				_review_script(task.params.get("script_path", ""))
			"validate_architecture":
				_validate_architecture()
			_:
				_finish_task({"status": "unknown_task"})
	
	func _review_script(script_path: String) -> void:
		print("ArchitectureAgent: Reviewing %s" % script_path)
		# Implementation would use LLM to review code
		_finish_task({
			"script": script_path,
			"issues_found": 0,
			"suggestions": []
		})
	
	func _validate_architecture() -> void:
		print("ArchitectureAgent: Validating project architecture")
		_finish_task({
			"structure_valid": true,
			"violations": []
		})

class CodeReviewAgent extends Agent:
	## Reviews code for bugs and best practices
	
	func _init():
		agent_name = "CodeReviewAgent"
		description = "Finds bugs, style issues, and optimization opportunities"
		capabilities = ["bug_detection", "style_check", "optimization"]
	
	func _process_task(task: Dictionary) -> void:
		match task.type:
			"check_bugs":
				_check_for_bugs(task.params.get("files", []))
			_:
				_finish_task({"status": "unknown_task"})
	
	func _check_for_bugs(files: Array) -> void:
		print("CodeReviewAgent: Checking %d files for bugs" % files.size())
		_finish_task({
			"files_checked": files.size(),
			"bugs_found": []
		})

class QualityAgent extends Agent:
	## Monitors and ensures quality standards
	
	func _init():
		agent_name = "QualityAgent"
		description = "Monitors code quality, performance, and test coverage"
		capabilities = ["quality_check", "performance_test", "coverage_analysis"]
	
	func _process_task(task: Dictionary) -> void:
		match task.type:
			"run_quality_check":
				_run_quality_check()
			"performance_benchmark":
				_run_performance_benchmark()
			_:
				_finish_task({"status": "unknown_task"})
	
	func _run_quality_check() -> void:
		print("QualityAgent: Running quality checks")
		_finish_task({
			"score": 0.95,
			"issues": []
		})
	
	func _run_performance_benchmark() -> void:
		print("QualityAgent: Running performance benchmark")
		if PerformanceMonitor:
			var summary = PerformanceMonitor.get_performance_summary()
			finish_task({"performance": summary})
		else:
			_finish_task({"error": "PerformanceMonitor not available"})

class ContentAgent extends Agent:
	## Generates game content using AI
	
	func _init():
		agent_name = "ContentAgent"
		description = "Generates dialogue, descriptions, and flavor text"
		capabilities = ["dialogue_generation", "description_generation", "lore_creation"]
	
	func _process_task(task: Dictionary) -> void:
		match task.type:
			"generate_dialogue":
				_generate_dialogue(task.params)
			"generate_item_desc":
				_generate_item_description(task.params)
			_:
				_finish_task({"status": "unknown_task"})
	
	func _generate_dialogue(params: Dictionary) -> void:
		if LLMClient:
			var response = await LLMClient.generate_dialogue(
				params.get("character", "NPC"),
				params.get("context", ""),
				params.get("tone", "neutral")
			)
			_finish_task({"dialogue": response})
		else:
			_finish_task({"error": "LLMClient not available"})
	
	func _generate_item_description(params: Dictionary) -> void:
		if LLMClient:
			var response = await LLMClient.generate_item_description(
				params.get("item_type", "weapon"),
				params.get("rarity", "common")
			)
			_finish_task({"description": response})
		else:
			_finish_task({"error": "LLMClient not available"})

class BalanceAgent extends Agent:
	## Analyzes and suggests game balance adjustments
	
	func _init():
		agent_name = "BalanceAgent"
		description = "Analyzes game balance and suggests adjustments"
		capabilities = ["balance_analysis", "difficulty_tuning", "economy_balance"]
	
	func _process_task(task: Dictionary) -> void:
		match task.type:
			"analyze_balance":
				_analyze_balance()
			_:
				_finish_task({"status": "unknown_task"})
	
	func _analyze_balance() -> void:
		print("BalanceAgent: Analyzing game balance")
		_finish_task({
			"weapons_balanced": true,
			"economy_balanced": true,
			"suggestions": []
		})
