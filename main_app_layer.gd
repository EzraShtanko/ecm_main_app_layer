@icon("img/img_Icon_MainAppLayer_32x32px.png")
@tool
class_name MainAppLayer
extends Control

signal revealed
signal concealed

@export_tool_button("Post Reconfig", "CheckBox") var action_post_reconfig: Callable = func() : reconfig.post()

@export var has_curtain: bool = true
@export var has_shroud: bool = true
@export var render_size: Vector2i = Vector2i(1920, 1080):
	set(v): render_size = v; reconfig.post()
@export var t_fade_in: float = 1.
@export var t_fade_out: float = 1.

var ccp: CustomConsolePrinter = CustomConsolePrinter.new()

var curtain: ColorRect:
	get:
		if not curtain: curtain = $Curtain
		return curtain
var content: Control:
	get:
		if not content: content = $Content
		return content
var shroud: ColorRect:
	get:
		if not shroud: shroud = $Shroud
		return shroud
	
var tween_fade: Tween

class Reconfig extends mio.Reconfig:
	var x: MainAppLayer
	func _init(_x: MainAppLayer): x = _x
	func _process() -> void:
		x.size = Vector2.ZERO
		var p: Control = x.get_parent_control()
		if p: x.position = x.get_parent_control().size / 2.
		for i: Control in [x.curtain, x.content, x.shroud]:
			if i:
				i.size = x.render_size
				i.position = -x.render_size / 2.
var reconfig: Reconfig = Reconfig.new(self)


func _ready() -> void: 
	ccp.title 		= name
	ccp.padding 		= 110
	ccp.flag_bold	= true
	ccp.color		= "orange"
	
	if has_curtain:
		if not get_children().any( func (x: Node) : return (x is ColorRect) and x.name == "Curtain"):
			var nc := ColorRect.new()
			add_child(nc)
			await get_tree().create_timer(0.1).timeout
			nc.owner 			= self
			nc.name 				= "Curtain"
			nc.color 			= Color.BLACK
			curtain 				= nc
		else: curtain = $Curtain
	
	if not get_children().any( func (x: Node) : return (x is Control) and x.name == "Content"):
		var nc: Control = Control.new()
		add_child(nc)
		await get_tree().create_timer(0.1).timeout
		nc.owner 			= self
		nc.name 				= "Content"
		content 				= nc
	else: content = $Content
	
	if has_shroud:
		if not get_children().any( func (x: Node) : return (x is Control) and x.name == "Shroud"):
			var nc := ColorRect.new()
			add_child(nc)
			await get_tree().create_timer(0.1).timeout
			nc.owner 			= self
			nc.name 				= "Shroud"
			nc.color 			= Color.BLACK
			shroud				= nc
		else: shroud = $Shroud
	
	for i: Control in [curtain, content, shroud]:
		i.anchor_top		= 0.5
		i.anchor_right		= 0.5
		i.anchor_left		= 0.5
		i.anchor_bottom		= 0.5
		i.size				= render_size
	
	if not Engine.is_editor_hint():
		shroud.visible = true
		shroud.modulate.a = 1.
	
	if not visibility_changed.is_connected(on_visibility_changed): visibility_changed.connect(on_visibility_changed)
	if content: content.visible = false
	if visible: _reveal()
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()


func _physics_process(_delta: float) -> void:
	if is_node_ready(): reconfig.process()


func _reveal() -> void:
	if not is_node_ready(): await ready
	if tween_fade: tween_fade.kill()
	tween_fade = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_parallel(false)
	
	ccp.log_oh("revealing")
	shroud.modulate.a = 0.
	visible = true
	shroud.visible = true
	tween_fade.tween_property(shroud, ^"modulate:a", 1., t_fade_in / 2.)
	tween_fade.tween_callback( func () : content.visible = true; curtain.visible = true )
	tween_fade.tween_property(shroud, ^"modulate:a", 0., t_fade_in / 2.).set_ease(Tween.EASE_IN_OUT)
	tween_fade.tween_callback( func () : shroud.visible = false; revealed.emit() )

func _conceal() -> void:
	if not is_node_ready(): await ready
	if tween_fade: tween_fade.kill()
	tween_fade = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_parallel(false)
	
	ccp.log_oh("concealing")
	print("concealing %s" % name)
	
	shroud.modulate.a = 0.
	shroud.visible = true
	tween_fade.tween_property(shroud, ^"modulate:a", 1., t_fade_out / 2.).set_ease(Tween.EASE_IN)
	tween_fade.tween_callback( func () : curtain.visible = false; content.visible = false )
	tween_fade.tween_property(shroud, ^"modulate:a", 0., t_fade_out / 2.).set_ease(Tween.EASE_IN)
	tween_fade.tween_callback( func () : visible = false; concealed.emit())


func on_visibility_changed() -> void:
	#if Engine.is_editor_hint(): return
	#if not is_node_ready(): return
	if visible: _reveal()
	else:
		if shroud: 		shroud.modulate.a 	= 0.
		if curtain: 		curtain.visible 		= false
		if content:		content.visible 		= false
		if shroud:		shroud.visible 		= false
	
func _on_viewport_size_changed() -> void:
	if Engine.is_editor_hint(): return
	var ns: Vector2 = get_viewport_rect().size
	if ns.x / ns.y >= float(render_size.x) / float(render_size.y):	scale = Vector2.ONE * ns.y / render_size.y
	else:												scale = Vector2.ONE * ns.x / render_size.x
