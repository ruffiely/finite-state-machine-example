extends KinematicBody


export (PackedScene) var Portrait = preload("res://UI/SelectionPortrait.tscn")

const speed = 5.0

var ScrollingText = preload("res://assets/people/utils/ScrollingText.tscn")

onready var progress_bar = $ProgressBar

var character_portrait
var character_name = "Expedition Member"

export var team = 0
export (int) var health = 100

# Activity state
var state
var next_state
# Food state
var food = food_state.NORMAL
# Rest state
var rest = rest_state.RESTED

var inventory
var skills

const STARVING_DAMAGE_PER_SEC = 5

enum food_state {
	STARVING,
	NORMAL,
	BEST,
}

enum rest_state {
	RESTLESS,
	NORMAL,
	RESTED,
}

func play_animation(animation):
	match animation:
		Global.ANIMATIONS.IDLE:
			$AnimationPlayer.play("Baked_Idle_Cycle")
		Global.ANIMATIONS.MOVE:
			$AnimationPlayer.play("Baked_Walk_Cylcle", -1, 1.5)
		Global.ANIMATIONS.STORE:
			$AnimationPlayer.play("cauldron")
		Global.ANIMATIONS.GATHER:
			$AnimationPlayer.play("cauldron")

func _ready():
	skills = Global.SkillTree.new()
	inventory = Global.Inventory.new()
	character_portrait = Portrait.instance()
	character_portrait.hint_tooltip = character_name
	_switch_state(States.IdleState.new())

func _process(delta):
	if not progress_bar.visible and $StatusMessageContainer.get_children().size() <= 0:
		return
	var pos = get_translation()
	var cam = get_tree().get_root().get_camera()
	var screen_pos = cam.unproject_position(pos)
	progress_bar.set_position(Vector2(screen_pos.x - progress_bar.rect_size.x/2, screen_pos.y - 130.0))
	for child in $StatusMessageContainer.get_children():
		child.set_position(Vector2(screen_pos.x - child.get_width() / 2, screen_pos.y - 130.0))

func _physics_process(delta):
	state.update(self, delta)

func move_to(nav, pos):
	_switch_state(States.MoveState.new(nav.get_simple_path(global_transform.origin, pos), 0, speed))

func gather(nav, pos, collider):
	if $Area.overlaps_body(collider):
		_switch_state(States.GatherState.new(progress_bar, collider))
	else:
		move_to(nav, pos)
		next_state = States.GatherState.new(progress_bar, collider)

func repair(nav, pos, collider):
	if $Area.overlaps_body(collider):
		_switch_state(States.StoreState.new(progress_bar, collider))
	else:
		move_to(nav, pos)
		next_state = States.StoreState.new(progress_bar, collider)

func mark_assigned():
	$Spatial.show()

func remove_assigned():
	$Spatial.hide()

func select():
	$Selected.show()

func deselect():
	$Selected.hide()

func _do_damage(damage):
	health -= damage
	_show_text('- ' + str(damage) + ' Health')
	if health < 0:
		_die()

func _die():
	queue_free()

func _check_food_state():
	if food == food_state.STARVING:
		_do_damage(STARVING_DAMAGE_PER_SEC)

func _check_rest_state():
	pass

func _on_CheckTimer_timeout():
	_check_food_state()
	_check_rest_state()

func _show_text(text):
	var scrolling_text = ScrollingText.instance()
	$StatusMessageContainer.add_child(scrolling_text)
	scrolling_text.show_text(text)

func _on_Area_body_entered(body):
	if next_state == null:
		return
	if next_state is States.GatherState and $Area.overlaps_body(next_state.gather_obj):
		_switch_state(States.GatherState.new(progress_bar, body))
	if next_state is States.StoreState and $Area.overlaps_body(next_state.store_obj):
		_switch_state(States.StoreState.new(progress_bar, body))

func _switch_state(new_state):
	if state != null:
		state.exit(self)
	state = new_state
	new_state.enter(self)