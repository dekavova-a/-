extends SceneTree
const Scene = preload("res://scenes/battlefield.tscn")
const Navigation = preload("res://scripts/navigation.gd")
var checks := 0
var failed := 0

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, text: String) -> void:
 checks += 1
 if value:
  print("PASS: ",text)
 else:
  failed += 1
  push_error("FAIL: " + text)

func mission():
 var world = Scene.instantiate()
 root.add_child(world)
 world.running = true
 world.paused = false
 world.hud.close_modal()
 return world

func run() -> void:
 var navigation = Navigation.new()
 var start := Vector2(600,600)
 check(navigation.path(start,Navigation.COURTYARD).is_empty(),"closed gate blocks all paths to the courtyard")
 navigation.set_gate(true)
 var path: PackedVector2Array = navigation.path(start,Navigation.COURTYARD)
 check(not path.is_empty(),"opening the gate creates a real traversable path")
 var all_walkable := true
 for point in path:
  all_walkable = all_walkable and navigation.is_walkable(point)
 check(all_walkable,"path stays within authored walkable areas")
 check(not navigation.is_walkable(Vector2(30,30)),"river and map borders are not traversable")
 check(not navigation.line_clear(Vector2(950,250),Vector2(1100,300)),"walls block line of sight")
 var world = mission()
 check(world.live_units(0).size() == 5 and world.live_units(1).size() == 6,"mission starts with both armies")
 check(world.investigate(),"investigation starts when paid")
 check(is_equal_approx(world.gold,395.0),"investigation deducts 25 gold")
 check(not world.investigate(),"investigation cannot be paid twice")
 world._intrigue(8.1)
 check(world.intrigue == "known","investigation reveals the captain's debt")
 check(world.bribe(),"captain can be bribed after investigation")
 check(is_equal_approx(world.gold,215.0),"bribe deducts exactly 180 gold")
 world._intrigue(6.1)
 check(world.intrigue == "betrayed" and world.gate.opening,"betrayal starts opening the portcullis")
 check(world.live_units(0).size() == 7,"captain's two formations change allegiance")
 check(not world.bribe(),"bribe cannot be applied twice")
 world.gate._process(3.2)
 check(world.nav.gate_open,"gate navigation changes after the opening animation")
 world._update_objectives(10.1)
 check(world.result.is_empty(),"defectors alone cannot win: an attacking formation must enter the courtyard")
 world.free()
 world = mission()
 var gold: float = world.gold
 var food: float = world.provisions
 check(world.recruit("spears"),"recruitment accepts a valid order")
 check(world.gold == gold - 90 and world.provisions == food - 15,"recruitment charges both resources")
 world._update_recruitment(7.1)
 check(world.live_units(0).size() == 6 and world.recruit_queue.is_empty(),"completed recruitment spawns an actual formation")
 world.paused = true
 var before: float = world.time
 world._process(10.0)
 check(world.time == before,"pause freezes mission simulation")
 check(not world.recruit("guard"),"recruitment is disabled while paused")
 world.paused = false
 var attacker = world.spawn_unit("spears",0,Vector2(800,500))
 var victim = world.spawn_unit("spears",1,Vector2(830,500))
 attacker.attack(victim)
 var hp: float = victim.hp
 attacker._physics_process(0.1)
 check(victim.hp < hp,"melee attack applies damage")
 victim.receive_damage(10000)
 check(victim.dead and world.kills == 1,"defeated enemy is counted once")
 victim.receive_damage(10000)
 check(world.kills == 1,"dead units cannot be killed twice")
 world.free()
 world = mission()
 for enemy in world.live_units(1):
  enemy.position = Vector2(900,400)
 world.live_units(0)[0].position = world.supply
 world._update_objectives(10.1)
 check(world.supply_captured,"uncontested supply camp can be captured")
 world.morale = 1.0
 world._update_objectives(1.0)
 check(world.gate.opening and world.siege_route == "Блокада","blockade forces the garrison to open the gate")
 world.free()
 world = mission()
 world.gate.receive_damage(10000)
 check(world.gate.opening and world.gate.hp == 0,"assault can break the gate")
 world.gate._process(3.2)
 for enemy in world.live_units(1):
  enemy.position = Vector2(900,400)
 world.live_units(0)[0].position = world.crown
 world._update_objectives(10.1)
 check(world.result == "victory","occupying the clear courtyard wins the mission")
 world.free()
 world = mission()
 world.camp_hp = 0
 world._process(0.1)
 check(world.result == "defeat","loss of the camp ends the mission")
 world.free()
 print("MISSION_TESTS checks=",checks," failed=",failed)
 quit(0 if failed == 0 else 1)
