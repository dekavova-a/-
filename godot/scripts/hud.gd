extends CanvasLayer
const Minimap = preload("res://scripts/minimap.gd")
const PORTRAIT = preload("res://assets/captain.png")
const TITLE_FONT = preload("res://assets/fonts/title.ttf")
var world
var root: Control
var gold_label: Label
var food_label: Label
var morale_label: Label
var objective_label: Label
var status_label: Label
var selected_label: Label
var health_bar: ProgressBar
var queue_label: Label
var notification: Label
var notice_time := 0.0
var spy_button: Button
var bribe_button: Button
var intrigue_text: Label
var recruit_buttons: Array[Button] = []
var modal: Control
var update_clock := 0.0

func style(color := Color("191b1beF"),border := Color("7e6846")) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = color
 box.border_color = border
 box.set_border_width_all(1)
 box.content_margin_left = 15
 box.content_margin_right = 15
 box.content_margin_top = 12
 box.content_margin_bottom = 12
 return box

func label(text: String, size := 16, color := Color("e7dbc2"), serif := false) -> Label:
 var item := Label.new()
 item.text = text
 item.focus_mode = Control.FOCUS_NONE
 item.add_theme_font_size_override("font_size",size)
 item.add_theme_color_override("font_color",color)
 if serif:
  item.add_theme_font_override("font",TITLE_FONT)
 item.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return item

func paragraph(text: String, width := 255) -> Label:
 var item := label(text,14,Color("b9b6a8"))
 item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 item.custom_minimum_size.x = width
 return item

func button(text: String, callback: Callable, height := 38) -> Button:
 var item := Button.new()
 item.text = text
 item.focus_mode = Control.FOCUS_NONE
 item.custom_minimum_size.y = height
 item.add_theme_font_size_override("font_size",14)
 item.add_theme_color_override("font_color",Color("e5d5b3"))
 item.add_theme_stylebox_override("normal",style(Color("2a2924")))
 item.add_theme_stylebox_override("hover",style(Color("4b3b29"),Color("d3b579")))
 item.add_theme_stylebox_override("pressed",style(Color("695033")))
 item.add_theme_stylebox_override("disabled",style(Color("242521"),Color("484638")))
 item.pressed.connect(callback)
 return item

func panel(parent: Control, anchors: Rect2, offsets: Rect2) -> PanelContainer:
 var item := PanelContainer.new()
 item.anchor_left = anchors.position.x
 item.anchor_top = anchors.position.y
 item.anchor_right = anchors.end.x
 item.anchor_bottom = anchors.end.y
 item.offset_left = offsets.position.x
 item.offset_top = offsets.position.y
 item.offset_right = offsets.end.x
 item.offset_bottom = offsets.end.y
 item.add_theme_stylebox_override("panel",style())
 parent.add_child(item)
 return item

func vertical(parent: Node, separation := 10) -> VBoxContainer:
 var item := VBoxContainer.new()
 item.add_theme_constant_override("separation",separation)
 parent.add_child(item)
 return item

func _ready() -> void:
 root = Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root)
 _top_bar()
 _council()
 _bottom_bar()
 notification = label("",15,Color("f3dfaa"))
 notification.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 notification.offset_top = 91
 notification.offset_left = -480
 notification.offset_right = 350
 notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 notification.add_theme_color_override("font_shadow_color",Color("111615"))
 notification.add_theme_constant_override("shadow_outline_size",8)
 root.add_child(notification)
 world.message.connect(_notice)
 show_intro()
 update_ui()

func _top_bar() -> void:
 var bar := panel(root,Rect2(0,0,1,0),Rect2(0,0,0,74))
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",30)
 bar.add_child(row)
 var brand := vertical(row,2)
 brand.add_child(label("ПЕПЕЛ КОРОНЫ",23,Color("e0c491"),true))
 brand.add_child(label("ВОРОНИЙ БРОД / ОСАДА 01",10,Color("8f9288")))
 var task := vertical(row,2)
 task.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 task.add_child(label("ПРИКАЗ ПРЕТЕНДЕНТА",10,Color("a4916d")))
 objective_label = label("Откройте ворота и займите двор крепости",16)
 task.add_child(objective_label)
 gold_label = label("ЗОЛОТО 420",17,Color("e2bf7d"))
 food_label = label("ПРИПАСЫ 150",17)
 morale_label = label("ДУХ ВРАГА 100",17,Color("9eb5c2"))
 row.add_child(gold_label)
 row.add_child(food_label)
 row.add_child(morale_label)
 row.add_child(button("Ⅱ",func(): world.toggle_pause(),36))

func _council() -> void:
 var p := panel(root,Rect2(1,0,0,1),Rect2(-307,87,294,-255))
 var box := vertical(p,6)
 box.add_child(label("ТАЙНЫЙ СОВЕТ",21,Color("dfc799"),true))
 var portrait := TextureRect.new()
 var portrait_crop := AtlasTexture.new()
 portrait_crop.atlas = PORTRAIT
 portrait_crop.region = Rect2(0,0,PORTRAIT.get_width(),PORTRAIT.get_height() * 0.7)
 portrait.texture = portrait_crop
 portrait.custom_minimum_size = Vector2(240,150)
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 box.add_child(portrait)
 box.add_child(label("ЭДРИК ВЕЙН",18,Color("e6d8b8"),true))
 box.add_child(label("Капитан гарнизона регента",12,Color("9fa59c")))
 intrigue_text = paragraph("У каждого человека есть причина хранить верность. И причина её нарушить.",240)
 box.add_child(intrigue_text)
 spy_button = button("Найти слабость · 25 золота",func(): world.investigate(),40)
 bribe_button = button("Погасить долг · 180 золота",func(): world.bribe(),40)
 box.add_child(spy_button)
 box.add_child(bribe_button)
 box.add_child(HSeparator.new())
 box.add_child(label("ТРИ ДОРОГИ К ПОБЕДЕ",11,Color("b09a71")))
 box.add_child(paragraph("ШТУРМ · разбить ворота\nБЛОКАДА · захватить обоз\nИЗМЕНА · договориться с капитаном",240))
 var spacer := Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 box.add_child(spacer)
 box.add_child(label("ДОМ ВОРОНЬЕЙ БАШНИ",11,Color("b5a27b")))
 box.add_child(label("Ваше знамя: охра · Враг: синий",11,Color("969e99")))
 box.add_child(button("Управление · F1",show_help,32))

func _bottom_bar() -> void:
 var p := panel(root,Rect2(0,1,1,0),Rect2(14,-166,-28,150))
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",20)
 p.add_child(row)
 var map_box := vertical(row,3)
 map_box.custom_minimum_size.x = 210
 map_box.add_child(label("ВЛАДЕНИЯ ВОРОНЬЕГО БРОДА",10,Color("b9a780")))
 var minimap = Minimap.new()
 minimap.world = world
 map_box.add_child(minimap)
 var selection := vertical(row,6)
 selection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 selected_label = label("Армия претендента",19,Color("dfc9a0"),true)
 selection.add_child(selected_label)
 status_label = label("5 отрядов · Tab: вся армия",13,Color("a7aea3"))
 selection.add_child(status_label)
 health_bar = ProgressBar.new()
 health_bar.custom_minimum_size = Vector2(210,5)
 health_bar.show_percentage = false
 health_bar.add_theme_stylebox_override("background",style(Color("34352c"),Color.TRANSPARENT))
 health_bar.add_theme_stylebox_override("fill",style(Color("b49d6c"),Color.TRANSPARENT))
 health_bar.get_theme_stylebox("background").content_margin_top = 0
 health_bar.get_theme_stylebox("fill").content_margin_top = 0
 health_bar.get_theme_stylebox("background").content_margin_bottom = 0
 health_bar.get_theme_stylebox("fill").content_margin_bottom = 0
 selection.add_child(health_bar)
 var orders := HBoxContainer.new()
 orders.add_theme_constant_override("separation",7)
 selection.add_child(orders)
 orders.add_child(button("Вся армия · Tab",func(): world.select_all(),33))
 orders.add_child(button("С боем · Q",func(): world.attack_mode = true,33))
 orders.add_child(button("Стой · H",func():
  for u in world.selected:
   u.halt()
 ,33))
 var recruitment := vertical(row,6)
 recruitment.custom_minimum_size.x = 450
 recruitment.add_child(label("НАБОР В ВОЕННОМ ЛАГЕРЕ",11,Color("c7b386")))
 var recruits := HBoxContainer.new()
 recruits.add_theme_constant_override("separation",8)
 recruitment.add_child(recruits)
 for kind in ["spears","crossbows","guard"]:
  var text: String = {"spears":"Копейщики [1]\n90 зол. / 15 прип.","crossbows":"Арбалетчики [2]\n110 зол. / 15 прип.","guard":"Стража [3]\n140 зол. / 15 прип."}[kind]
  var b := button(text,world.recruit.bind(kind),57)
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  recruits.add_child(b)
  recruit_buttons.append(b)
 queue_label = label("Очередь пуста · Лимит: 12 отрядов",12,Color("9b9f91"))
 recruitment.add_child(queue_label)

func _notice(text: String) -> void:
 notification.text = text
 notice_time = 7.0

func _process(delta: float) -> void:
 notice_time = maxf(0.0,notice_time - delta)
 notification.visible = notice_time > 0.0
 update_clock += delta
 if update_clock > 0.15:
  update_clock = 0.0
  update_ui()

func update_ui() -> void:
 gold_label.text = "ЗОЛОТО  " + str(int(world.gold))
 food_label.text = "ПРИПАСЫ  " + str(int(world.provisions))
 morale_label.text = "ДУХ ВРАГА  " + str(int(world.morale))
 if world.crown_progress > 0:
  objective_label.text = "Захват двора: %d / 10 сек." % int(world.crown_progress)
 elif world.nav.gate_open:
  objective_label.text = "Ворота открыты. Удержите двор 10 секунд."
 var states := {"unknown":"Капитан верен регенту. Узнайте, что держит его в крепости.","investigating":"Посланник собирает сведения. Осталось %d сек." % int(world.intrigue_time),"known":"Три месяца без жалованья. Капитан готов открыть ворота, если вы погасите долг перед его людьми.","negotiating":"Посланник передаёт предложение. Осталось %d сек." % int(world.intrigue_time),"betrayed":"Капитан принял вашу сторону. Его отряды теперь под вашим знаменем."}
 intrigue_text.text = states[world.intrigue]
 spy_button.disabled = not world.active() or world.intrigue != "unknown" or world.gold < 25
 bribe_button.disabled = not world.active() or world.intrigue != "known" or world.gold < 180 or world.gate.opening
 if world.intrigue == "betrayed":
  bribe_button.text = "Капитан служит вашему дому"
 var count: int = world.selected.size()
 selected_label.text = world.selected[0].title() if count == 1 else "Выбрано отрядов: %d" % count
 status_label.text = "%d / 12 отрядов · Лагерь: %d%%" % [world.live_units(0).size(),int(world.camp_hp / 9.0)]
 var hp := 0.0
 var max_hp := 0.0
 for u in world.selected:
  if is_instance_valid(u):
   hp += u.hp
   max_hp += u.max_hp
 health_bar.value = hp / maxf(1.0,max_hp) * 100.0
 var queue: Array = world.recruit_queue
 queue_label.text = "Очередь пуста · Лимит: 12 отрядов" if queue.is_empty() else "Подкрепление через %d сек. · В очереди: %d" % [ceili(queue[0]["time"]),queue.size()]
 var kinds := ["spears","crossbows","guard"]
 for i in range(3):
  recruit_buttons[i].disabled = not world.active() or world.gold < world.COSTS[kinds[i]] or world.provisions < 15 or world.live_units(0).size()+queue.size() >= 12

func close_modal() -> void:
 if is_instance_valid(modal):
  modal.queue_free()
 modal = null

func _modal_box() -> VBoxContainer:
 close_modal()
 modal = Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(modal)
 var shade := ColorRect.new()
 shade.color = Color(0.035,0.04,0.04,0.76)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(center)
 var card := PanelContainer.new()
 card.custom_minimum_size = Vector2(740,0)
 card.add_theme_stylebox_override("panel",style(Color("181c1bF9"),Color("a18655")))
 center.add_child(card)
 var margin := MarginContainer.new()
 margin.add_theme_constant_override("margin_left",24)
 margin.add_theme_constant_override("margin_right",24)
 margin.add_theme_constant_override("margin_top",19)
 margin.add_theme_constant_override("margin_bottom",19)
 card.add_child(margin)
 return vertical(margin,16)

func _start() -> void:
 world.running = true
 world.paused = false
 close_modal()
 update_ui()

func show_intro() -> void:
 var box := _modal_box()
 box.add_child(label("ПЕПЕЛ КОРОНЫ / ОСАДА I",13,Color("b39a6c")))
 box.add_child(label("ВОРОНИЙ БРОД",38,Color("e6d1a7"),true))
 box.add_child(paragraph("Король мёртв. Регент запер ворота и объявил наследника изменником. Вы пришли вернуть крепость своему дому. Но за каждой стеной стоят люди, которым тоже есть что терять.",650))
 box.add_child(HSeparator.new())
 box.add_child(paragraph("ЦЕЛЬ: открыть ворота и удержать двор крепости 10 секунд.\n\nШТУРМ: атакуйте решётку выбранными отрядами.\nБЛОКАДА: захватите обоз справа и дождитесь падения боевого духа.\nИЗМЕНА: узнайте слабость капитана через Тайный совет и предложите сделку.\n\nДеревня на северо-западе приносит доход и припасы. Защищайте свой лагерь: враг готовит вылазки.",650))
 box.add_child(label("ЛКМ / рамка: выбрать · ПКМ: приказ · Tab: вся армия",14))
 box.add_child(label("WASD / стрелки: камера · Колесо: масштаб · F1: справка",14))
 box.add_child(button("ПОДНЯТЬ ЗНАМЁНА  →",_start,48))
 box.add_child(label("GODOT 4 · WINDOWS · ПЕРВАЯ ИГРАБЕЛЬНАЯ СЦЕНА 0.2",10,Color("92978a")))

func show_pause() -> void:
 var box := _modal_box()
 box.add_child(label("ВОЕННЫЙ СОВЕТ",32,Color("e6d1a7"),true))
 box.add_child(paragraph("Время остановлено. Осмотрите планы и вернитесь к осаде.",650))
 box.add_child(button("Вернуться к осаде",func():
  world.paused = false
  close_modal()
 ,44))
 box.add_child(button("Начать заново",func(): get_tree().reload_current_scene(),40))
 box.add_child(button("Выйти из игры",func(): get_tree().quit(),40))

func show_help() -> void:
 if not world.running or not world.result.is_empty():
  return
 world.paused = true
 var box := _modal_box()
 box.add_child(label("ПРИКАЗЫ КОМАНДИРА",29,Color("e6d1a7"),true))
 box.add_child(paragraph("ЛКМ / рамка: выделить отряд. Shift добавляет к выделению.\nПКМ по земле: движение. ПКМ по врагу / воротам: атака.\nQ, затем ЛКМ: движение с боем. H: остановиться.\nTab: вся армия. F: камера к выделению.\nWASD / стрелки / средняя кнопка: камера. Колесо: масштаб.\n1 / 2 / 3: нанять копейщиков / арбалетчиков / стражу.\nEsc / Пробел: пауза. F11: полный экран.\n\nЗахват деревни, обоза и двора происходит автоматически: держите отряд в круге 10 секунд, когда рядом нет врагов.\n\nВаши знамёна - охра. У регента - синие. Решётка открывает настоящий проход; через закрытую стену пройти нельзя.",650))
 box.add_child(button("Продолжить",func():
  world.paused = false
  close_modal()
 ,44))

func show_result() -> void:
 var box := _modal_box()
 var won: bool = world.result == "victory"
 box.add_child(label("КРЕПОСТЬ ВАША" if won else "ЗНАМЯ ПАЛО",34,Color("e6d1a7"),true))
 box.add_child(paragraph("Над Вороньим бродом поднято ваше знамя. Это первый шаг к престолу." if won else "Лагерь потерян или армия лишилась возможности продолжить осаду. Попробуйте другой подход к крепости.",650))
 box.add_child(label("Путь к победе: " + world.siege_route if won else "Отступление от Вороньего брода",18))
 box.add_child(label("Время: %02d:%02d · Уничтожено отрядов: %d" % [int(world.time)/60,int(world.time)%60,world.kills],15))
 box.add_child(button("Новая осада",func(): get_tree().reload_current_scene(),44))
 box.add_child(button("Выйти",func(): get_tree().quit(),38))
