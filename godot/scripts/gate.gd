extends Node2D
var world
var hp := 1200.0
var max_hp := 1200.0
var team := 1
var dead := false
var openness := 0.0
var opening := false
var selected := false

func _process(delta: float) -> void:
 if world == null or not world.active():
  return
 if opening:
  openness = minf(1.0, openness + delta / 3.0)
  if openness >= 0.98 and not world.nav.gate_open:
   world.nav.set_gate(true)
   dead = true
   world.notify("Ворота открыты. Займите двор крепости.")
 queue_redraw()

func open_gate() -> void:
 opening = true

func receive_damage(amount: float) -> void:
 if opening:
  return
 hp = maxf(0.0, hp - amount)
 world.gate_attacked = true
 if hp <= 0.0:
  open_gate()
  world.notify("Засов сломан. Ворота поддаются! Сигнал к штурму.")

func _draw() -> void:
 if openness < 0.99:
  var bottom := -openness * 60.0
  var points := PackedVector2Array([Vector2(-20,-53),Vector2(-8,-65),Vector2(13,-59),Vector2(20,-42),Vector2(20,bottom),Vector2(-20,bottom + 7)])
  if bottom > -42:
   draw_colored_polygon(points, Color("30251e"))
  for x in range(-18, 21, 5):
   var upper := -52.0 - 10.0 * (1.0 - absf(float(x)) / 22.0)
   if bottom > upper:
    draw_line(Vector2(x,upper), Vector2(x,bottom), Color("80725a"), 2.2)
  for y in [-48.0,-32.0,-15.0]:
   if y < bottom:
    draw_line(Vector2(-20,y+3),Vector2(20,y-3),Color("aea080"),2.5)
 if hp < max_hp and not opening:
  draw_rect(Rect2(-28,-80,56,4),Color("211d1b"))
  draw_rect(Rect2(-28,-80,56 * hp / max_hp,4),Color("b58b5a"))
 if selected and not dead:
  draw_arc(Vector2(0,1),28,0.0,TAU,40,Color("d3ad6a"),1.2)
