extends Node2D
signal message(text: String)
const Navigation = preload("res://scripts/navigation.gd")
const Unit = preload("res://scripts/unit.gd")
const Gate = preload("res://scripts/gate.gd")
const HUD = preload("res://scripts/hud.gd")
const MAP = preload("res://assets/siege_map.png")
const COSTS := {"spears":90,"crossbows":110,"guard":140}
var nav = Navigation.new()
var units: Array[Node2D] = []
var selected: Array[Node2D] = []
var units_root: Node2D
var gate: Node2D
var camera: Camera2D
var hud: CanvasLayer
var gold := 420.0
var provisions := 150.0
var morale := 100.0
var camp_hp := 900.0
var time := 0.0
var running := false
var paused := false
var result := ""
var gate_attacked := false
var siege_route := ""
var intrigue := "unknown"
var intrigue_time := 0.0
var supply_captured := false
var village_captured := false
var supply_progress := 0.0
var village_progress := 0.0
var crown_progress := 0.0
var next_raid := 100.0
var income_clock := 0.0
var recruit_queue: Array[Dictionary] = []
var active_count := 0
var kills := 0
var arrows: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var floating: Array[Dictionary] = []
var attack_mode := false
var dragging := false
var drag_start := Vector2.ZERO
var drag_end := Vector2.ZERO
var panning := false
var last_pointer := Vector2.ZERO
var camera_drag := Vector2.ZERO
var camp := Vector2(440,690)
var supply := Vector2(1330,600)
var village := Vector2(555,315)
var crown := Vector2(1150,195)
var marker := Vector2.ZERO
var marker_age := 100.0
var ui_clock := 0.0

func _ready() -> void:
 var backdrop := Sprite2D.new()
 backdrop.texture = MAP
 backdrop.centered = false
 backdrop.z_index = -10
 add_child(backdrop)
 units_root = Node2D.new()
 units_root.y_sort_enabled = true
 add_child(units_root)
 gate = Gate.new()
 gate.world = self
 gate.position = Navigation.GATE
 units_root.add_child(gate)
 camera = Camera2D.new()
 camera.position = Vector2(855,510)
 camera.zoom = Vector2.ONE * 1.12
 camera.position_smoothing_enabled = false
 add_child(camera)
 spawn_unit("spears",0,Vector2(530,600))
 spawn_unit("spears",0,Vector2(600,665))
 spawn_unit("crossbows",0,Vector2(490,660))
 spawn_unit("guard",0,Vector2(560,735))
 spawn_unit("crossbows",0,Vector2(650,735))
 spawn_unit("spears",1,Vector2(930,380))
 spawn_unit("crossbows",1,Vector2(1090,420))
 spawn_unit("guard",1,Vector2(1250,570))
 spawn_unit("spears",1,Vector2(1180,655))
 spawn_unit("spears",1,Vector2(1100,215))
 spawn_unit("crossbows",1,Vector2(1210,210))
 hud = HUD.new()
 hud.world = self
 add_child(hud)
 select_all()
 if "--smoke" in OS.get_cmdline_user_args():
  running = true
  hud.close_modal()
 if "--capture" in OS.get_cmdline_user_args():
  running = true
  hud.close_modal()
  _capture_later()
 queue_redraw()

func _capture_later() -> void:
 await get_tree().create_timer(1.0).timeout
 await RenderingServer.frame_post_draw
 var image := get_viewport().get_texture().get_image()
 var path := OS.get_environment("CROWN_CAPTURE_PATH")
 if path.is_empty():
  path = "user://battlefield.png"
 var err := image.save_png(path)
 print("CAPTURE_RESULT=",err," PATH=",path)
 get_tree().quit(0 if err == OK else 1)

func active() -> bool:
 return running and not paused and result.is_empty()

func notify(text: String) -> void:
 message.emit(text)

func spawn_unit(kind: String, team: int, point: Vector2) -> Node2D:
 var u = Unit.new()
 u.serial = active_count
 active_count += 1
 var safe = nav.closest(point)
 u.setup(self,kind,team,safe if safe != Vector2.INF else point)
 units.append(u)
 units_root.add_child(u)
 return u

func live_units(team := -1) -> Array[Node2D]:
 var out: Array[Node2D] = []
 for u in units:
  if is_instance_valid(u) and not u.dead and (team < 0 or u.team == team):
   out.append(u)
 return out

func select_all() -> void:
 for u in live_units():
  u.selected = u.team == 0
 selected = live_units(0)

func clean_selection() -> void:
 selected = selected.filter(func(u): return is_instance_valid(u) and not u.dead and u.team == 0)

func find_enemy(unit: Node2D, radius: float) -> Node2D:
 var best: Node2D = null
 var distance := radius
 for other in live_units(1 - unit.team):
  var d := unit.position.distance_to(other.position)
  if d < distance and nav.line_clear(unit.position,other.position):
   best = other
   distance = d
 return best

func on_unit_lost(unit: Node2D) -> void:
 if unit.team == 1:
  kills += 1
  morale = maxf(0.0,morale - 6.0)
 else:
  notify("Потерян отряд: " + unit.title())

func recruit(kind: String) -> bool:
 if not active() or not COSTS.has(kind):
  return false
 if live_units(0).size() + recruit_queue.size() >= 12:
  notify("Лимит армии: 12 отрядов")
  return false
 var cost: int = COSTS[kind]
 if gold < cost or provisions < 15:
  notify("Для найма нужны золото и 15 припасов")
  return false
 gold -= cost
 provisions -= 15
 recruit_queue.append({"kind":kind,"time":7.0,"total":7.0})
 notify("Начат набор: " + {"spears":"копейщики","crossbows":"арбалетчики","guard":"домовая стража"}[kind])
 return true

func investigate() -> bool:
 if not active() or intrigue != "unknown" or gold < 25:
  return false
 gold -= 25
 intrigue = "investigating"
 intrigue_time = 8.0
 notify("Посланник ищет недовольных среди гарнизона. 8 секунд.")
 return true

func bribe() -> bool:
 if not active() or intrigue != "known" or gold < 180 or gate.opening:
  return false
 gold -= 180
 intrigue = "negotiating"
 intrigue_time = 6.0
 notify("Капитану предложено погасить долг гарнизону. Ждём ответа.")
 return true

func _intrigue(delta: float) -> void:
 if intrigue == "investigating" or intrigue == "negotiating":
  intrigue_time -= delta
  if intrigue_time <= 0.0:
   if intrigue == "investigating":
    intrigue = "known"
    notify("Выяснено: гарнизон три месяца не получал жалованье. Цена сделки: 180 золота.")
   else:
    intrigue = "betrayed"
    siege_route = "Измена гарнизона"
    gate.open_gate()
    for u in live_units(1):
     if u.position.y < 280:
      u.team = 0
      u.defected = true
      u.target = null
      u.order = "idle"
      u.route.clear()
      u.recolor()
    notify("Капитан принял вашу сторону. Его люди поднимают решётку.")

func _process(delta: float) -> void:
 if active():
  _camera_input(delta)
  marker_age += delta
  time += delta
  income_clock += delta
  if income_clock >= 10.0:
   income_clock -= 10.0
   gold += 18.0
   if village_captured:
    gold += 16.0
    provisions += 15.0
   provisions = maxf(0.0,provisions - live_units(0).size())
  _intrigue(delta)
  _update_recruitment(delta)
  _update_objectives(delta)
  _update_enemy()
  _projectiles(delta)
  clean_selection()
  if camp_hp <= 0.0:
   finish("defeat")
  elif live_units(0).is_empty() and recruit_queue.is_empty() and (gold < 90 or provisions < 15):
   finish("defeat")
 for fx in sparks:
  if active():
   fx["age"] += delta
 sparks = sparks.filter(func(fx): return fx["age"] < 0.65)
 queue_redraw()

func _update_recruitment(delta: float) -> void:
 if recruit_queue.is_empty():
  return
 recruit_queue[0]["time"] -= delta
 if recruit_queue[0]["time"] <= 0.0:
  var job: Dictionary = recruit_queue.pop_front()
  var u = spawn_unit(job["kind"],0,camp + Vector2(70,15 + fmod(time * 7,70)))
  u.move_to(camp + Vector2(120,0))
  notify("Прибыло подкрепление: " + u.title())

func _capture_point(point: Vector2, radius: float, progress: float, delta: float, require_attacker := false) -> float:
 var allies := 0
 var enemies := 0
 for u in live_units():
  if u.position.distance_to(point) < radius:
   if u.team == 0 and (not require_attacker or not u.defected):
    allies += 1
   elif u.team == 1:
    enemies += 1
 if allies > 0 and enemies == 0:
  return minf(10.0,progress + delta)
 return maxf(0.0,progress - delta * 0.5)

func _update_objectives(delta: float) -> void:
 if not village_captured:
  village_progress = _capture_point(village,65,village_progress,delta)
  if village_progress >= 10.0:
   village_captured = true
   notify("Деревня поддержала ваш дом: дополнительные золото и припасы каждые 10 секунд.")
 if not supply_captured:
  supply_progress = _capture_point(supply,85,supply_progress,delta)
  if supply_progress >= 10.0:
   supply_captured = true
   gold += 90.0
   provisions += 60.0
   notify("Обоз захвачен. Крепость лишилась снабжения. Вы получили 90 золота и 60 припасов.")
 if supply_captured and not gate.opening:
  morale = maxf(0.0,morale - delta * 1.2)
  if morale <= 0.0:
   gate.open_gate()
   siege_route = "Блокада"
   notify("Гарнизон требует переговоров и открывает ворота.")
 if nav.gate_open:
  crown_progress = _capture_point(crown,70,crown_progress,delta,true)
  if crown_progress >= 10.0:
   if siege_route.is_empty():
    siege_route = "Штурм"
   finish("victory")
 for enemy in live_units(1):
  if enemy.position.distance_to(camp) < 95:
   camp_hp = maxf(0.0,camp_hp - delta * 14.0)

func _update_enemy() -> void:
 if time < next_raid:
  return
 next_raid = time + 80.0
 notify("Разведка: отряд регента идёт к вашему лагерю.")
 for u in live_units(1):
  if u.position.y > 290:
   u.move_to(camp,true)
 if live_units(1).size() < 7 and not supply_captured:
  var patrol = spawn_unit("spears",1,Vector2(1285,650))
  patrol.move_to(camp,true)

func shoot(shooter: Node2D, victim: Node2D, amount: float) -> void:
 arrows.append({"position":shooter.position,"target":victim,"damage":amount,"team":shooter.team,"age":0.0})

func _projectiles(delta: float) -> void:
 for arrow in arrows:
  arrow["age"] += delta
  var victim = arrow["target"]
  if not is_instance_valid(victim) or victim.get("dead"):
   arrow["age"] = 99.0
   continue
  var p: Vector2 = arrow["position"]
  if p.distance_to(victim.position) < 340.0 * delta:
   victim.receive_damage(arrow["damage"])
   impact(victim.position,arrow["team"],true)
   arrow["age"] = 99.0
  else:
   arrow["position"] = p.move_toward(victim.position,340.0 * delta)
 arrows = arrows.filter(func(a): return a["age"] < 3.0)

func impact(point: Vector2, side: int, ranged: bool) -> void:
 sparks.append({"position":point,"age":0.0,"side":side,"ranged":ranged})

func finish(outcome: String) -> void:
 if not result.is_empty():
  return
 result = outcome
 hud.show_result()

func toggle_pause() -> void:
 if not running or not result.is_empty():
  return
 paused = not paused
 if paused:
  hud.show_pause()
 else:
  hud.close_modal()

func _camera_input(delta: float) -> void:
 var direction := Vector2.ZERO
 if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A): direction.x -= 1
 if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D): direction.x += 1
 if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W): direction.y -= 1
 if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S): direction.y += 1
 camera.position += direction * delta * 500.0 / camera.zoom.x
 camera.position.x = clampf(camera.position.x,380,1260)
 camera.position.y = clampf(camera.position.y,220,850)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  match event.physical_keycode:
   KEY_ESCAPE:
    if attack_mode:
     attack_mode = false
    else:
     toggle_pause()
   KEY_F1: hud.show_help()
   KEY_SPACE: toggle_pause()
   KEY_F11:
    var current := DisplayServer.window_get_mode()
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if current == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
  if not active():
   return
  match event.physical_keycode:
   KEY_1: recruit("spears")
   KEY_2: recruit("crossbows")
   KEY_3: recruit("guard")
   KEY_Q:
    attack_mode = true
    notify("Движение с боем: укажите точку левой кнопкой. Esc: отмена.")
   KEY_H:
    for u in selected:
     u.halt()
   KEY_F:
    clean_selection()
    if not selected.is_empty(): camera.position = selected[0].position + Vector2(100,0)
   KEY_TAB: select_all()
 if not active():
  return
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
   _zoom(1.1)
  elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
   _zoom(1.0 / 1.1)
  elif event.button_index == MOUSE_BUTTON_MIDDLE:
   panning = event.pressed
  elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
   issue_order(get_global_mouse_position())
  elif event.button_index == MOUSE_BUTTON_LEFT:
   if event.pressed:
    if attack_mode:
     issue_order(get_global_mouse_position(),true)
     attack_mode = false
    else:
     dragging = true
     drag_start = get_global_mouse_position()
     drag_end = drag_start
   elif dragging:
    dragging = false
    _select_region(Input.is_physical_key_pressed(KEY_SHIFT))
 if event is InputEventMouseMotion:
  if panning:
   camera.position -= event.relative / camera.zoom
  if dragging:
   drag_end = get_global_mouse_position()

func _zoom(factor: float) -> void:
 var before := get_global_mouse_position()
 camera.zoom = Vector2.ONE * clampf(camera.zoom.x * factor,0.7,2.3)
 camera.position += before - get_global_mouse_position()

func _select_region(additive := false) -> void:
 if not additive:
  for u in live_units(): u.selected = false
  selected.clear()
 var rect := Rect2(drag_start,drag_end - drag_start).abs()
 for u in live_units(0):
  if (rect.size.length() > 8 and rect.has_point(u.position)) or (rect.size.length() <= 8 and u.position.distance_to(drag_end) < 34):
   if not selected.has(u): selected.append(u)
   u.selected = true

func issue_order(point: Vector2, advance := false) -> void:
 clean_selection()
 var target: Node2D = null
 for u in live_units(1):
  if point.distance_to(u.position) < 30:
   target = u
 if point.distance_to(gate.position) < 45 and not gate.opening:
  target = gate
 var issued := 0
 var count := selected.size()
 var side := maxi(1,ceili(sqrt(count)))
 for i in range(count):
  var u = selected[i]
  if target != null:
   u.attack(target)
   issued += 1
  else:
   var formation := Vector2((i % side - (side - 1) * 0.5) * 45,(floori(float(i) / side) - (side - 1) * 0.5) * 39)
   if u.move_to(point + formation,advance) or u.move_to(point,advance):
    issued += 1
 marker = point
 marker_age = 0.0
 if issued == 0:
  notify("Нет доступного пути. Вход в крепость закрыт воротами.")

func _draw() -> void:
 if nav == null:
  return
 for data in [[village,village_progress,village_captured,"ДЕРЕВНЯ"],[supply,supply_progress,supply_captured,"ОБОЗ"],[crown,crown_progress,false,"ДВОР КРЕПОСТИ"]]:
  var point: Vector2 = data[0]
  var color := Color("d2b573") if data[2] else Color("d3c8ab")
  draw_set_transform(point,0,Vector2(1,0.6))
  draw_arc(Vector2.ZERO,39,0,TAU,48,Color(color,0.55),1.1)
  if data[1] > 0:
   draw_arc(Vector2.ZERO,42,-PI * 0.5,-PI * 0.5 + TAU * float(data[1]) / 10.0,48,Color("e6c77f"),2.5)
  draw_set_transform(Vector2.ZERO)
  draw_string(ThemeDB.fallback_font,point + Vector2(-40,37),data[3],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("eee1c4"))
 draw_rect(Rect2(camp + Vector2(-45,60),Vector2(90,4)),Color("262223"))
 draw_rect(Rect2(camp + Vector2(-45,60),Vector2(90 * camp_hp / 900.0,4)),Color("bda575"))
 for arrow in arrows:
  var p: Vector2 = arrow["position"]
  var victim = arrow["target"]
  if is_instance_valid(victim):
   var direction: Vector2 = (victim.position - p).normalized()
   draw_line(p + Vector2(0,-12),p - direction * 9 + Vector2(0,-12),Color("dfceb0"),1.2)
 for fx in sparks:
  var p: Vector2 = fx["position"]
  var age: float = fx["age"]
  for i in range(4):
   var angle := float(i) * 1.7 + time
   var direction := Vector2(cos(angle),sin(angle) * 0.6)
   draw_line(p + direction * age * 23,p + direction * age * 30,Color(0.9,0.75,0.45,1.0-age/0.65),1.0)
 if marker_age < 0.8:
  draw_arc(marker,10 + marker_age * 20,0,TAU,32,Color(0.9,0.8,0.6,1.0 - marker_age / 0.8),1.2)
 if dragging:
  var rect := Rect2(drag_start,drag_end - drag_start).abs()
  draw_rect(rect,Color(0.8,0.7,0.4,0.1))
  draw_rect(rect,Color("e1cc94"),false,1.0)
