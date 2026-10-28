extends SceneTree
var world
var checks := 0
var failures := 0

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, text: String) -> void:
 checks += 1
 if value:
  print("PASS: ",text)
 else:
  failures += 1
  push_error("FAIL: " + text)

func find_button(node: Node, prefix: String) -> Button:
 if node is Button and node.text.begins_with(prefix):
  return node
 for child in node.get_children():
  var found := find_button(child,prefix)
  if found != null:
   return found
 return null

func click(point: Vector2, button_index := MOUSE_BUTTON_LEFT) -> void:
 var motion := InputEventMouseMotion.new()
 motion.position = point
 root.push_input(motion)
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = button_index
  event.position = point
  event.pressed = pressed
  root.push_input(event)

func key(code: int) -> void:
 for pressed in [true,false]:
  var event := InputEventKey.new()
  event.physical_keycode = code
  event.keycode = code
  event.pressed = pressed
  root.push_input(event)

func run() -> void:
 root.size = Vector2i(1600,900)
 world = load("res://scenes/battlefield.tscn").instantiate()
 root.add_child(world)
 for i in range(5):
  await process_frame
 var start := find_button(root,"ПОДНЯТЬ")
 check(start != null,"briefing has a start button")
 click(start.get_global_rect().get_center())
 await process_frame
 await process_frame
 check(world.running and not world.paused,"actual GUI click starts the mission")
 var hire := find_button(root,"Копейщики [1]")
 click(hire.get_global_rect().get_center())
 check(world.recruit_queue.size() == 1,"actual GUI click queues recruitment")
 var point: Vector2 = world.get_viewport().get_canvas_transform() * Vector2(800,570)
 click(point,MOUSE_BUTTON_RIGHT)
 check(world.selected.any(func(u): return not u.route.is_empty()),"right click on terrain issues movement to selected formations")
 key(KEY_ESCAPE)
 check(world.paused,"Escape opens tactical pause")
 for i in range(3):
  await process_frame
 var resume := find_button(root,"Вернуться")
 check(resume != null,"pause menu has a resume button")
 click(resume.get_global_rect().get_center())
 await process_frame
 await process_frame
 check(not world.paused,"actual GUI click resumes the mission")
 await create_timer(0.2).timeout
 key(KEY_Q)
 check(world.attack_mode,"Q enters attack-move mode")
 key(KEY_ESCAPE)
 check(not world.attack_mode and not world.paused,"Escape cancels attack mode before pausing")
 var spy := find_button(root,"Найти слабость")
 click(spy.get_global_rect().get_center())
 check(world.intrigue == "investigating","council GUI click starts investigation")
 world.free()
 print("INPUT_TESTS checks=",checks," failed=",failures)
 quit(0 if failures == 0 else 1)
