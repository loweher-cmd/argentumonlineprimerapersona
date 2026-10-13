extends CanvasLayer

const AO_FONT = preload("res://assets/ui_font.ttf")
var game: Node3D
var root: Control
var health: TextureProgressBar
var mana: TextureProgressBar
var health_text: Label
var mana_text: Label
var message: Label
var message_time := 0.0
var target: Label
var counter: Label
var intro: PanelContainer
var death: PanelContainer
var slots: Array[Button] = []
var sword: TextureRect
var damage: ColorRect
var music_button: Button
var sfx_button: Button
var event_log: RichTextLabel
var log_entries: Array[String] = []
var inventory_health: Button
var inventory_mana: Button

func label(text: String, font_size: int, color := Color("e1d8bf")) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font",AO_FONT)
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",color)
	result.add_theme_color_override("font_shadow_color",Color.BLACK)
	result.add_theme_constant_override("shadow_offset_x",1)
	result.add_theme_constant_override("shadow_offset_y",1)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func skin(path: String, margin: int = 8) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = load(path)
	for edge in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		result.set_texture_margin(edge,margin)
		result.set_content_margin(edge,margin)
	return result

func button_skin(button: Button) -> void:
	button.add_theme_font_override("font",AO_FONT)
	button.add_theme_color_override("font_color",Color("e9e1c8"))
	button.add_theme_stylebox_override("normal",skin("res://assets/ui_button_default.png"))
	button.add_theme_stylebox_override("hover",skin("res://assets/ui_button_over.png"))
	button.add_theme_stylebox_override("pressed",skin("res://assets/ui_button_off.png"))
	button.focus_mode = Control.FOCUS_NONE

func panel_box(parent: Node, at: Vector2, dimensions: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = dimensions
	panel.add_theme_stylebox_override("panel",skin("res://assets/ui_slot.png",10))
	parent.add_child(panel)
	return panel

func make_bar(path: String, maximum: int) -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.max_value = maximum
	bar.texture_progress = load(path)
	bar.nine_patch_stretch = true
	bar.size = Vector2(216,16)
	return bar

func modal(title: String, body: String, button_text: String, callback: Callable) -> PanelContainer:
	var result := PanelContainer.new()
	result.position = Vector2(326,180)
	result.size = Vector2(500,340)
	result.add_theme_stylebox_override("panel",skin("res://assets/ui_slot.png",12))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",18)
	result.add_child(column)
	var title_label := label(title,28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	var details := label(body,16,Color("adb5c1"))
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(details)
	var button := Button.new()
	button.text = button_text
	button_skin(button)
	button.custom_minimum_size.y = 48
	button.pressed.connect(callback)
	column.add_child(button)
	root.add_child(result)
	return result

func _ready() -> void:
	root = Control.new()
	root.size = Vector2(1152,720)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(root)
	# Continuous opaque frame; only the central first-person view stays open.
	for region in [Rect2(0,0,1152,154),Rect2(918,154,234,566),Rect2(0,553,918,167)]:
		var backing := ColorRect.new()
		backing.position = region.position
		backing.size = region.size
		backing.color = Color("100e0b")
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(backing)
	var top := panel_box(root,Vector2(0,0),Vector2(918,154))
	top.name = "EventLogPanel"
	top.add_theme_stylebox_override("panel",skin("res://assets/ui_log.png",8))
	var title := label("ARGENTUM ONLINE  /  Dungeon Newbie",16,Color("c6ad7c"))
	title.position = Vector2(12,7)
	top.add_child(title)
	counter = label("",12,Color("adb5c1"))
	counter.position = Vector2(564,10)
	top.add_child(counter)
	event_log = RichTextLabel.new()
	event_log.name = "EventLog"
	event_log.position = Vector2(12,34)
	event_log.size = Vector2(894,108)
	event_log.add_theme_font_override("normal_font",AO_FONT)
	event_log.add_theme_font_size_override("normal_font_size",14)
	event_log.add_theme_color_override("default_color",Color("bcd8c6"))
	event_log.bbcode_enabled = false
	event_log.scroll_following = true
	event_log.selection_enabled = true
	top.add_child(event_log)
	add_log("Bienvenido al Dungeon Newbie. Que los dioses guien tu camino.")
	add_log("1 Daga | 2 Dardo magico | 3 Vida | 4 Mana. ESC libera el cursor.")
	var crosshair := label("+",23)
	crosshair.position = Vector2(569,341)
	root.add_child(crosshair)
	target = label("",16)
	target.position = Vector2(376,388)
	target.size.x = 400
	target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(target)
	message = label("",19)
	message.position = Vector2(326,505)
	message.size.x = 500
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(message)
	var tray := panel_box(root,Vector2(244,553),Vector2(674,167))
	var paladin := label("PALADIN",14,Color("b89961"))
	paladin.position = Vector2(20,14)
	tray.add_child(paladin)
	health = make_bar("res://assets/ui_health.png",120)
	health.position = Vector2(116,23)
	tray.add_child(health)
	mana = make_bar("res://assets/ui_mana.png",80)
	mana.position = Vector2(390,23)
	tray.add_child(mana)
	health_text = label("",13)
	health_text.position = Vector2(116,4)
	tray.add_child(health_text)
	mana_text = label("",13)
	mana_text.position = Vector2(390,4)
	tray.add_child(mana_text)
	for i in range(4):
		var button := Button.new()
		button.position = Vector2(20+i*158,49)
		button.size = Vector2(150,73)
		button.icon = load(game.data.icons[i])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",32)
		button.add_theme_font_size_override("font_size",14)
		button_skin(button)
		button.pressed.connect(func(): game.player.action(i))
		tray.add_child(button)
		slots.append(button)
	var capture_hint := label("WASD  Mover     RATON  Mirar     1-4  Acciones     ESC  Cursor     O  Musica     P  Sonidos",12,Color("a4adbd"))
	capture_hint.position = Vector2(24,699)
	root.add_child(capture_hint)
	sword = TextureRect.new()
	sword.texture = load(game.data.icons[0])
	sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sword.position = Vector2(590,285)
	sword.size = Vector2(340,340)
	sword.pivot_offset = Vector2(116,250)
	sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sword)
	# Weapon overlays the world, but every HUD panel draws above it.
	root.move_child(sword,0)
	damage = ColorRect.new()
	damage.size = Vector2(1152,720)
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage.color = Color(0.6,0.05,0.03,0)
	root.add_child(damage)
	var map_panel := panel_box(root,Vector2(918,0),Vector2(234,154))
	var map_title := label("DUNGEON NEWBIE  /  N",12)
	map_title.position = Vector2(12,7)
	map_panel.add_child(map_title)
	var minimap := preload("res://ui/minimap.gd").new()
	minimap.name = "Minimap"
	minimap.game = game
	minimap.position = Vector2(60,29)
	minimap.size = Vector2(113,113)
	map_panel.add_child(minimap)
	build_inventory()
	music_button = audio_button(Vector2(24,613),"Music")
	sfx_button = audio_button(Vector2(24,653),"SFX")
	game.audio.changed.connect(refresh_audio)
	refresh_audio()
	intro = modal("DUNGEON NEWBIE", "Argentum Online en primera persona\n\nWASD para caminar - Raton para mirar\n1 Daga - 2 Dardo magico\n3 Vida - 4 Mana\nESC libera el cursor\nO Musica - P Sonidos\n\nRecursos originales - Mapa 37", "Entrar al dungeon", game.begin)
	death = modal("HAS CAIDO", "Tu expedicion termina aqui.\nVuelve a intentarlo con tus pociones restauradas.", "Reiniciar",func(): get_tree().reload_current_scene())
	death.hide()
	get_viewport().size_changed.connect(resize)
	resize()

func resize() -> void:
	root.scale = get_viewport().get_visible_rect().size/Vector2(1152,720)

func _process(delta: float) -> void:
	var player: CharacterBody3D = game.player
	inventory_health.text = str(player.health_charges)
	inventory_mana.text = str(player.mana_charges)
	inventory_health.disabled = player.health_charges<=0
	inventory_mana.disabled = player.mana_charges<=0
	health.value = player.hp
	mana.value = player.mana
	health_text.text = "VIDA    %d / 120" % player.hp
	mana_text.text = "MANA    %d / 80" % player.mana
	counter.text = "MAPA 37  /  %02d de %02d derrotados" % [game.kills,game.total_enemies]
	var names := ["Daga","Dardo","Vida x%d" % player.health_charges,"Mana x%d" % player.mana_charges]
	for i in range(4):
		slots[i].text = "%d  %s\n%s" % [i+1,names[i],"%.1fs" % player.cooldowns[i] if player.cooldowns[i]>0 else ["22 dano","10 mana","+45 vida","+35 mana"][i]]
		slots[i].modulate = Color("9ba5b5") if player.cooldowns[i]>0 else Color.WHITE
	sword.visible = game.started and player.alive
	sword.rotation = -0.35-sin(player.sword_flash/0.24*PI)*0.85
	sword.position.x = 590-sin(player.sword_flash/0.24*PI)*170
	damage.color.a = player.hurt_flash*0.8
	message_time -= delta
	if message_time<=0:
		message.text = ""
	if game.started:
		var hit: Dictionary = player.aimed(18)
		target.text = ""
		if not hit.is_empty() and hit.collider.has_method("take_damage"):
			target.text = "%s  /  %d de %d" % [hit.collider.stats.name,hit.collider.hp,hit.collider.stats.hp]

func audio_button(at: Vector2, bus_name: String) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(186,32)
	button.add_theme_font_size_override("font_size",14)
	button_skin(button)
	button.pressed.connect(func(): game.audio.toggle(bus_name))
	root.add_child(button)
	return button

func refresh_audio() -> void:
	music_button.text = "[O] Musica: " + ("apagada" if game.audio.muted("Music") else "encendida")
	sfx_button.text = "[P] Sonidos: " + ("apagados" if game.audio.muted("SFX") else "encendidos")

func add_log(entry: String) -> void:
	log_entries.append(Time.get_time_string_from_system()+"  "+entry)
	if log_entries.size()>100:
		log_entries.pop_front()
	event_log.text = "\n".join(log_entries)

func item_slot(parent: Control, at: Vector2, dimensions: Vector2, icon_path: String, description: String) -> Button:
	var button := Button.new()
	button.position = at
	button.size = dimensions
	button.tooltip_text = description
	button_skin(button)
	button.add_theme_stylebox_override("normal",skin("res://assets/ui_slot.png",4))
	button.add_theme_stylebox_override("disabled",skin("res://assets/ui_slot.png",4))
	button.add_theme_font_size_override("font_size",12)
	button.add_theme_constant_override("h_separation",0)
	button.add_theme_constant_override("icon_max_width",24)
	button.expand_icon = true
	if not icon_path.is_empty():
		button.icon = load(icon_path)
	else:
		button.disabled = true
	parent.add_child(button)
	return button

func build_inventory() -> void:
	var panel := panel_box(root,Vector2(918,154),Vector2(234,566))
	panel.name = "EquipmentInventory"
	var name_label := label("PALADIN",19,Color("c6ad7c"))
	name_label.position = Vector2(14,12)
	panel.add_child(name_label)
	var heading := label("EQUIPO",12)
	heading.position = Vector2(14,43)
	panel.add_child(heading)
	for i in range(3):
		var item: Dictionary = game.data.equipment[i] if i<game.data.equipment.size() else {"name":"Sin escudo","icon":"","slot":"Escudo"}
		var slot := item_slot(panel,Vector2(14+i*62,66),Vector2(56,54),item.icon,item.name)
		slot.name = "EquipmentSlot%d" % i
		var caption := label(item.slot,11)
		caption.position = Vector2(14+i*62,123)
		panel.add_child(caption)
	var inventory_title := label("INVENTARIO",16,Color("c6ad7c"))
	inventory_title.position = Vector2(14,155)
	panel.add_child(inventory_title)
	for i in range(20):
		var icon_path: String = game.data.icons[i+2] if i<2 else ""
		var description: String = ["Pocion de vida (+45). Clic para usar.","Pocion de mana (+35). Clic para usar."][i] if i<2 else "Espacio vacio"
		var slot := item_slot(panel,Vector2(14+(i%4)*46,187+(i/4)*46),Vector2(42,42),icon_path,description)
		slot.name = "InventorySlot%d" % i
		if i==0:
			inventory_health = slot
			slot.pressed.connect(func(): game.player.action(2))
		elif i==1:
			inventory_mana = slot
			slot.pressed.connect(func(): game.player.action(3))
	var hint := label("ESC para usar el cursor\nPociones: clic o teclas 3 / 4",12,Color("a4adbd"))
	hint.position = Vector2(14,437)
	panel.add_child(hint)
