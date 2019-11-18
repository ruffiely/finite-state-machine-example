extends Node

class State:
	func update(entity, delta):
		pass
	
	func handle_input(event):
		pass
	
	func enter(entity):
		pass
	
	func exit(entity):
		pass

class IdleState extends State:
	func enter(entity):
		entity.play_animation(Global.ANIMATIONS.IDLE)

class GatherState extends State:
	const gathering_time = 2.5
	
	var progress_bar
	var gather_obj
	var gather_time_spend = 0.0
	
	func _init(progress_bar, gather_obj):
		self.progress_bar = progress_bar
		self.gather_obj = gather_obj
	
	func update(entity, delta):
		if !is_instance_valid(gather_obj):
			entity._switch_state(States.IdleState.new())
			entity._show_text("Gathering canceled")
		gather_time_spend += delta
		progress_bar.set_progress(gather_time_spend / gathering_time * 100)
		if gather_time_spend > gathering_time:
			_gathering_finished(entity)
	
	func _gathering_finished(entity):
		entity._switch_state(States.IdleState.new())
		if entity.inventory.is_full():
			entity._show_text('Inventory full')
		else:
			var item = gather_obj.get_parent().gather()
			entity.inventory.add(item)
			entity._show_text('+ 1 ' + item.get_name())
	
	func exit(entity):
		progress_bar.hide()
	
	func enter(entity):
		progress_bar.show()
		entity.play_animation(Global.ANIMATIONS.GATHER)

class StoreState extends State:
	const storing_time = 1.5
	
	var progress_bar
	var store_obj
	var store_time_spend = 0.0
	
	func _init(progress_bar, store_obj):
		self.progress_bar = progress_bar
		self.store_obj = store_obj
	
	func update(entity, delta):
		if store_obj.owner.is_repaired():
			entity._switch_state(States.IdleState.new())
			entity._show_text("Repairing canceled")
			return
		store_time_spend += delta
		progress_bar.set_progress(store_time_spend / storing_time * 100)
		if store_time_spend > storing_time:
			_storing_finished(entity)
	
	func _storing_finished(entity):
		if not store_obj.owner.repair(entity.inventory):
			entity._show_text('Repair failed')
		entity._switch_state(States.IdleState.new())
	
	func exit(entity):
		progress_bar.hide()
	
	func enter(entity):
		if not store_obj.owner.has_needed_materials(entity.inventory):
			entity._show_text("No materials")
			entity._switch_state(States.IdleState.new())
			return
		progress_bar.show()
		entity.play_animation(Global.ANIMATIONS.GATHER)

class MoveState extends State:
	var path : = PoolVector3Array()
	var path_index = 0
	var speed
	
	func _init(path, path_index, speed):
		self.path = path
		self.path_index = path_index
		self.speed = speed
	
	func update(entity, delta):
		if path_index < path.size():
			var move_vec = (path[path_index] - entity.global_transform.origin)
			if move_vec.length() < 0.1:
				path_index += 1
			else:
				entity.play_animation(Global.ANIMATIONS.MOVE)
				var velocity = move_vec.normalized() * speed
				var collide = entity.move_and_collide(velocity * delta, false)
			
				var angle = atan2(move_vec.x, move_vec.z)
				var char_rot = entity.get_rotation()
				char_rot.y = angle
				entity.set_rotation(char_rot)
		else:
			entity._switch_state(States.IdleState.new())