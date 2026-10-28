extends Control
var world
var map_texture = preload("res://assets/siege_map.png")

func _ready() -> void:
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 mouse_filter = Control.MOUSE_FILTER_STOP
 custom_minimum_size = Vector2(210,112)

func _process(_delta: float) -> void:
 queue_redraw()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  world.camera.position = event.position / size * Vector2(1536,1024) + Vector2(90,0)
  accept_event()
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
  world.camera.position = event.position / size * Vector2(1536,1024) + Vector2(90,0)
  accept_event()

func _draw() -> void:
 draw_texture_rect(map_texture,Rect2(Vector2.ZERO,size),false,Color(0.65,0.65,0.6))
 if world == null:
  return
 for u in world.live_units():
  var point: Vector2 = u.position / Vector2(1536,1024) * size
  draw_circle(point,2.2,Color("e4c58e") if u.team == 0 else Color("88b8d3"))
 for point in [world.supply,world.village,world.crown]:
  var p: Vector2 = point / Vector2(1536,1024) * size
  draw_rect(Rect2(p-Vector2(2,2),Vector2(4,4)),Color("e9d7b2"),false,1.0)
 var viewport: Vector2 = get_viewport_rect().size
 var camera_size: Vector2 = viewport / world.camera.zoom
 var top_left: Vector2 = (world.camera.position-camera_size/2.0) / Vector2(1536,1024) * size
 draw_rect(Rect2(top_left,camera_size / Vector2(1536,1024) * size),Color("d6c59b"),false,1.0)
 draw_rect(Rect2(Vector2.ZERO,size),Color("8b744f"),false,1.0)
