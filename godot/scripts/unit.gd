extends Node2D
## One controllable formation with independently phased, directional soldier sprites.
const SPEAR = preload("res://assets/spearmen_walk.png")
const CROSSBOW = preload("res://assets/crossbow_walk.png")
var world
var kind := "spears"
var team := 0
var hp := 360.0
var max_hp := 360.0
var speed := 38.0
var attack_range := 38.0
var damage := 24.0
var reload_time := 1.2
var cooldown := 0.0
var selected := false
var dead := false
var defected := false
var order := "idle"
var target: Node2D
var route := PackedVector2Array()
var destination := Vector2.ZERO
var facing := Vector2(1, -1)
var animation_clock := 0.0
var hit_time := 0.0
var attack_time := 0.0
var moving := false
var repath_time := 0.0
var loss_time := 0.0
var members: Array[Sprite2D] = []
var offsets: Array[Vector2] = []
var member_count := 9
var serial := 0

func setup(controller, unit_kind: String, side: int, point: Vector2) -> void:
 world = controller
 kind = unit_kind
 team = side
 position = point
 if kind == "crossbows":
  hp = 230.0
  speed = 34.0
  attack_range = 155.0
  damage = 28.0
  reload_time = 2.3
  member_count = 6
 elif kind == "guard":
  hp = 540.0
  speed = 33.0
  damage = 36.0
  member_count = 9
 max_hp = hp

func _ready() -> void:
 for i in range(member_count):
  var soldier := Sprite2D.new()
  soldier.texture = CROSSBOW if kind == "crossbows" else SPEAR
  soldier.hframes = 4
  soldier.vframes = 8
  var cell_height := soldier.texture.get_height() / 8.0
  soldier.offset = Vector2(0, -cell_height * 0.34)
  soldier.scale = Vector2.ONE * (0.125 if kind == "guard" else 0.115)
  var offset := Vector2((i % 3 - 1) * 13.0, (floori(float(i) / 3.0) - 1) * 11.0)
  offsets.append(offset)
  soldier.position = offset
  add_child(soldier)
  members.append(soldier)
 recolor()

func recolor() -> void:
 for soldier in members:
  soldier.modulate = Color("d9cdaf") if team == 0 else Color("9bafd0")
  if kind == "guard":
   soldier.modulate = Color("e6c48c") if team == 0 else Color("abbbd1")

func title() -> String:
 match kind:
  "crossbows": return "Арбалетчики"
  "guard": return "Домовая стража"
 return "Копейщики"

func move_to(point: Vector2, fight := false) -> bool:
 var planned = world.nav.path(position, point)
 if planned.is_empty():
  return false
 route = planned
 destination = route[-1]
 target = null
 order = "advance" if fight else "move"
 return true

func attack(victim: Node2D) -> void:
 if victim == self or victim == null:
  return
 target = victim
 order = "attack"
 route.clear()
 repath_time = 0.0

func halt() -> void:
 order = "hold"
 route.clear()
 target = null

func receive_damage(amount: float) -> void:
 if dead:
  return
 hp = maxf(0.0, hp - amount)
 hit_time = 0.12
 if hp <= 0.0:
  dead = true
  selected = false
  world.on_unit_lost(self)

func _physics_process(delta: float) -> void:
 if world == null or not world.active():
  return
 if dead:
  loss_time += delta
  modulate.a = maxf(0.0, 1.0 - loss_time / 1.8)
  for soldier in members:
   soldier.rotation = lerpf(soldier.rotation, -1.25, delta * 5.0)
  if loss_time > 1.8:
   queue_free()
  return
 cooldown -= delta
 repath_time -= delta
 hit_time = maxf(0.0, hit_time - delta)
 attack_time = maxf(0.0, attack_time - delta)
 moving = false
 if not is_instance_valid(target):
  target = null
 if is_instance_valid(target) and target.get("dead"):
  target = null
  if order == "attack":
   order = "idle"
   route.clear()
 if is_instance_valid(target) and order != "attack":
  if position.distance_to(target.position) > attack_range + 65.0 or not world.nav.line_clear(position,target.position):
   target = null
 if target == null and order != "move":
  target = world.find_enemy(self, attack_range + 65.0)
 var engaged := false
 if is_instance_valid(target):
  var distance := position.distance_to(target.position)
  var reach := attack_range + (20.0 if target == world.gate else 0.0)
  if distance <= reach and (target == world.gate or world.nav.line_clear(position,target.position)):
   engaged = true
   facing = (target.position - position).normalized()
   if cooldown <= 0.0:
    cooldown = reload_time
    attack_time = 0.27
    var strength := maxf(0.25, hp / max_hp)
    if kind == "crossbows":
     world.shoot(self,target,damage * strength)
    else:
     target.receive_damage(damage * strength)
     world.impact(target.position, team, false)
  elif order == "attack" and repath_time <= 0.0:
   repath_time = 0.8
   var toward := (position - target.position).normalized()
   var endpoint := target.position + toward * maxf(20.0,reach * 0.7)
   route = world.nav.path(position,endpoint)
 if not engaged:
  _walk(delta)
 animation_clock += delta * (7.5 if moving else 1.0)
 var row := posmod(int(round(facing.angle() / (PI / 4.0))),8)
 var living := maxi(1,ceili(member_count * hp / max_hp))
 for i in range(members.size()):
  var soldier := members[i]
  soldier.visible = i < living
  var frame_id := (int(animation_clock + i * 0.23) % 4) if moving else 1
  soldier.frame = row * 4 + frame_id
  var thrust := sin((1.0 - attack_time / 0.27) * PI) * 3.0 if attack_time > 0.0 else 0.0
  soldier.position = offsets[i] + facing * thrust
  soldier.self_modulate = Color(1.8,1.25,1.1) if hit_time > 0.0 else Color.WHITE
 queue_redraw()

func _walk(delta: float) -> void:
 if route.is_empty():
  if order == "move" or order == "advance":
   order = "idle"
  return
 var next := route[0]
 var direction := next - position
 if direction.length() < 2.0:
  route.remove_at(0)
  return
 var step := direction.normalized() * minf(speed * delta,direction.length())
 if world.nav.is_walkable(position + step):
  position += step
  facing = direction.normalized()
  moving = true
 else:
  route.clear()

func _draw() -> void:
 if dead:
  return
 for i in range(members.size()):
  if members[i].visible:
   draw_set_transform(offsets[i],0,Vector2(1.0,0.4))
   draw_circle(Vector2(1,3),7,Color(0.02,0.025,0.02,0.25))
 draw_set_transform(Vector2.ZERO)
 var banner := Color("b88753") if team == 0 else Color("8aafcd")
 draw_line(Vector2(-22,2),Vector2(-22,-35),Color("50432f"),1.2)
 var wave := sin(animation_clock * 1.5 + serial) * 1.8
 draw_colored_polygon(PackedVector2Array([Vector2(-22,-35),Vector2(-9,-33+wave),Vector2(-10,-21+wave),Vector2(-22,-24)]),banner)
 draw_line(Vector2(-17,-31),Vector2(-17,-25),Color("e4d5b4"),1.0)
 if selected:
  draw_set_transform(Vector2.ZERO,0,Vector2(1,0.6))
  draw_arc(Vector2.ZERO,25,0,TAU,48,Color("dbc48e"),1.5)
  draw_set_transform(Vector2.ZERO)
 if selected or hp < max_hp:
  draw_rect(Rect2(-20,-44,40,3),Color("181b1a"))
  draw_rect(Rect2(-20,-44,40 * hp / max_hp,3),Color("c6b078") if team == 0 else Color("8ea9bf"))
