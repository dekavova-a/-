extends RefCounted
## Authored walkable regions aligned to the generated 1536x1024 map.
const CELL := 12
const MAP_SIZE := Vector2(1536, 1024)
const GATE := Vector2(1023, 275)
const COURTYARD := Vector2(1150, 195)
var grid := AStarGrid2D.new()
var gate_open := false
var gate_cells: Array[Vector2i] = []
var field := PackedVector2Array([
 Vector2(225,350),Vector2(480,305),Vector2(625,240),Vector2(750,285),
 Vector2(865,330),Vector2(970,298),Vector2(1005,295),Vector2(1050,300),
 Vector2(1100,370),Vector2(1210,445),Vector2(1370,500),Vector2(1430,570),
 Vector2(1380,665),Vector2(1250,735),Vector2(1060,860),Vector2(800,885),
 Vector2(540,845),Vector2(420,780),Vector2(360,720),Vector2(455,650),
 Vector2(470,565),Vector2(390,520),Vector2(290,495),Vector2(235,420)])
var courtyard := PackedVector2Array([
 Vector2(997,295),Vector2(1001,263),Vector2(1035,239),Vector2(1070,206),
 Vector2(1110,186),Vector2(1160,184),Vector2(1205,164),Vector2(1245,175),
 Vector2(1275,210),Vector2(1245,236),Vector2(1180,247),Vector2(1135,234),
 Vector2(1090,238),Vector2(1057,275),Vector2(1044,301)])

func _init() -> void:
 grid.region = Rect2i(0, 0, 128, 86)
 grid.cell_size = Vector2(CELL, CELL)
 grid.offset = Vector2(CELL * 0.5, CELL * 0.5)
 grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
 grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
 grid.update()
 for y in range(86):
  for x in range(128):
   var cell := Vector2i(x, y)
   var p := Vector2(x * CELL + CELL * 0.5, y * CELL + CELL * 0.5)
   var allowed := Geometry2D.is_point_in_polygon(p, field) or Geometry2D.is_point_in_polygon(p, courtyard)
   grid.set_point_solid(cell, not allowed)
   if allowed and p.x >= 978 and p.x <= 1080 and p.y >= 270 and p.y <= 311:
    gate_cells.append(cell)
 set_gate(false)

func cell_for(p: Vector2) -> Vector2i:
 return Vector2i(clampi(int(p.x / CELL), 0, 127), clampi(int(p.y / CELL), 0, 85))

func is_walkable(p: Vector2) -> bool:
 if p.x < 0 or p.y < 0 or p.x >= MAP_SIZE.x or p.y >= MAP_SIZE.y:
  return false
 return not grid.is_point_solid(cell_for(p))

func closest(p: Vector2) -> Vector2:
 var origin := cell_for(p)
 if not grid.is_point_solid(origin):
  return grid.get_point_position(origin)
 for radius in range(1, 20):
  var best := Vector2.INF
  var distance := INF
  for y in range(-radius, radius + 1):
   for x in range(-radius, radius + 1):
    if abs(x) != radius and abs(y) != radius:
     continue
    var cell := origin + Vector2i(x, y)
    if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
     var point := grid.get_point_position(cell)
     if point.distance_squared_to(p) < distance:
      distance = point.distance_squared_to(p)
      best = point
  if best != Vector2.INF:
   return best
 return Vector2.INF

func path(from: Vector2, to: Vector2) -> PackedVector2Array:
 var start := closest(from)
 var end := closest(to)
 if start == Vector2.INF or end == Vector2.INF:
  return PackedVector2Array()
 return grid.get_point_path(cell_for(start), cell_for(end), false)

func set_gate(value: bool) -> void:
 gate_open = value
 for cell in gate_cells:
  grid.set_point_solid(cell, not value)

func line_clear(a: Vector2, b: Vector2) -> bool:
 var steps := maxi(1, int(a.distance_to(b) / 5.0))
 for i in range(steps + 1):
  if not is_walkable(a.lerp(b, float(i) / steps)):
   return false
 return true
