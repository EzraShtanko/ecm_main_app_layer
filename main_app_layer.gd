@tool
class_name MainAppLayer
extends Control

signal revealed
signal concealed


@export var render_size: Vector2i = Vector2i(1920, 1080):
	set(v): render_size = v; reconfig.post()
@export var t_fade_in: float = 1.
@export var t_fade_out: float = 1.

var reconfig: Reconfig = Reconfig.new(self):
	get: 
		if not reconfig: reconfig = Reconfig.new(self)
		return reconfig

var curtain: ColorRect:
	get: return $Curtain
var content: Control:
	get: return $Content
var shroud: ColorRect:
	get: return $Shroud
	
var tween_fade: Tween

class Reconfig extends mio.Reconfig:
	var x: MainAppLayer
	func _init(_x: MainAppLayer): x = _x
	func _process() -> void:
		var p: Control = x.get_parent_control()
		if p: x.position = x.get_parent_control().size / 2.
		for i: Control in [x.curtain, x.content, x.shroud]:
			i.size = x.render_size
			i.position = -x.render_size / 2.


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	if not Engine.is_editor_hint():
		shroud.visible = true
		shroud.modulate.a = 1.

func _physics_process(_delta: float) -> void:
	reconfig.process()


func _reveal() -> void:
	mio.strike_tween(tween_fade)
	tween_fade = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_parallel(false)
	
	print("revealing %s" % name)
	
	shroud.visible = true
	tween_fade.tween_property(shroud, ^"modulate:a", 1., t_fade_in / 2.)
	tween_fade.tween_callback( func () : content.visible = true; curtain.visible = true )
	tween_fade.tween_property(shroud, ^"modulate:a", 0., t_fade_in / 2.).set_ease(Tween.EASE_IN_OUT)
	tween_fade.tween_callback( func () : shroud.visible = false; revealed.emit() )

func _conceal() -> void:
	mio.strike_tween(tween_fade)
	tween_fade = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_parallel(false)
	
	print("concealing %s" % name)
	
	tween_fade.tween_property(shroud, ^"modulate:a", 1., t_fade_out / 2.).set_ease(Tween.EASE_IN)
	tween_fade.tween_callback( func () : curtain.visible = false; content.visible = false )
	tween_fade.tween_property(shroud, ^"modulate:a", 0., t_fade_out / 2.).set_ease(Tween.EASE_IN)
	tween_fade.tween_callback( func () : visible = false; concealed.emit())


func on_visibility_changed() -> void:
	if not is_node_ready(): return
	if visible: _reveal()
	else:
		shroud.modulate.a = 0.
		curtain.visible = false
		content.visible = false
		shroud.visible = false
	
func _on_viewport_size_changed() -> void:
	if Engine.is_editor_hint(): return
	var ns: Vector2 = get_viewport_rect().size
	if ns.x / ns.y >= float(render_size.x) / float(render_size.y):	scale = Vector2.ONE * ns.y / render_size.y
	else:												scale = Vector2.ONE * ns.x / render_size.x

