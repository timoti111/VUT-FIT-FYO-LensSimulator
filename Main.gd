extends Node2D

const _Aperture = preload("Aperture.gd")
const _Lens = preload("Lens.gd")
const _Ray = preload("Ray.gd")

func lens_select(lens: _Lens):
	$Camera2D/CanvasLayer/GUI.selected_lens = lens

func aperture_select(aperture: _Aperture):
	$Camera2D/CanvasLayer/GUI.selected_aperture = aperture
	
func ray_select(ray: _Ray):
	$Camera2D/CanvasLayer/GUI.selected_ray = ray
	
func scene_modified(lens: _Lens):
	for ray in $Rays.get_children():
		ray.trace()
	$Camera2D/CanvasLayer/GUI.modified = true
	
func ray_modified(ray: _Ray):
	ray.trace()
	$Camera2D/CanvasLayer/GUI.modified = true
	
func _new_lens():
	var new_lens = _Lens.new()
	new_lens.connect("clicked", self, "lens_select")
	new_lens.connect("modified", self, "scene_modified")
	$Tracables.add_child(new_lens)
	return new_lens
	
var holding_lens = false
func _on_GUI_add_lens():
	var new_lens = _new_lens()
	new_lens.position = get_global_mouse_position()
	held_objects = []
	held_objects.push_back(new_lens)
	holding_lens = true
	holding_others = true
	
func _on_GUI_remove_lens(lens):
	lens.queue_free()
	$Tracables.remove_child(lens)
	scene_modified(lens)
	$Camera2D/CanvasLayer/GUI.modified = true
	
func _new_ray():
	var new_ray = _Ray.new($Tracables)
	new_ray.connect("clicked", self, "ray_select")
	new_ray.connect("modified", self, "ray_modified")
	$Rays.add_child(new_ray)
	return new_ray

var holding_single_ray = false
func _on_GUI_add_ray():
	var new_ray = _new_ray()
	new_ray.position = get_global_mouse_position()
	held_objects = []
	held_objects.push_back(new_ray)
	holding_single_ray = true
	holding_rays = true

var holding_omnidirectional_rays = false
func _on_GUI_add_omnidirectional_rays():
	held_objects = []
	var rays = 24
	for i in range(0, rays):
		var new_ray = _new_ray()
		new_ray.position = get_global_mouse_position()
		var angle = i * (2 * PI / rays)
		var direction = Vector2(sin(angle), cos(angle))
		new_ray.set_direction(direction)
		held_objects.push_back(new_ray)
	holding_omnidirectional_rays = true
	holding_rays = true
	
var holding_parallel_rays = false
func _on_GUI_add_parallel_rays():
	var new_ray = _new_ray()
	new_ray.position = get_global_mouse_position()
	held_objects = []
	held_objects.push_back(new_ray)
	var rays = 24
	var distance = 10
	for i in range(1, rays / 2):
		var new_ray1 = _new_ray()
		new_ray1.position = get_global_mouse_position() + Vector2(0, i * distance)
		var new_ray2 = _new_ray()
		new_ray2.position = get_global_mouse_position() + Vector2(0, -i * distance)
		held_objects.push_back(new_ray1)
		held_objects.push_back(new_ray2)
	holding_parallel_rays = true
	holding_rays = true

func _on_GUI_remove_ray(ray):
	ray.queue_free()
	$Camera2D/CanvasLayer/GUI.modified = true

func _new_aperture():
	var new_aperture = _Aperture.new()
	new_aperture.connect("clicked", self, "aperture_select")
	new_aperture.connect("modified", self, "scene_modified")
	$Tracables.add_child(new_aperture)
	return new_aperture
	
var holding_aperture = false
func _on_GUI_add_aperture():
	var new_aperture = _new_aperture()
	new_aperture.position = get_global_mouse_position()
	held_objects = []
	held_objects.push_back(new_aperture)
	holding_aperture = true
	holding_others = true

func _on_GUI_remove_aperture(aperture):
	aperture.queue_free()
	$Tracables.remove_child(aperture)
	scene_modified(aperture)
	$Camera2D/CanvasLayer/GUI.modified = true
	
func dropped_object():
	if holding_single_ray or holding_parallel_rays:
		if not setting_ray_direction:
			setting_ray_direction = true
		else:
			setting_ray_direction = false
			if holding_parallel_rays:
				ray_select(null)
			else:
				ray_select(held_objects[0])
			lens_select(null)
			aperture_select(null)
			holding_single_ray = false
			holding_parallel_rays = false
	if holding_omnidirectional_rays:
		setting_ray_direction = false
		lens_select(null)
		ray_select(null)
		aperture_select(null)
		holding_omnidirectional_rays = false
	if holding_lens:
		setting_ray_direction = false
		lens_select(held_objects[0])
		ray_select(null)
		aperture_select(null)
		holding_lens = false
	if holding_aperture:
		setting_ray_direction = false
		aperture_select(held_objects[0])
		ray_select(null)
		lens_select(null)
		holding_aperture = false
	$Camera2D/CanvasLayer/GUI.modified = true

func _on_GUI_set_background(path):
	var image = Image.new()
	image.load(path)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	$Background.texture = texture
	$Background.visible = true
	$Camera2D/CanvasLayer/GUI.modified = true

func _on_GUI_reset_background():
	$Background.visible = false
	$Camera2D/CanvasLayer/GUI.modified = true

var held_objects = null
var holding_rays = false
var holding_others = false
var setting_ray_direction = false
func _input(event):
	if held_objects != null:
		if event is InputEventMouseMotion:
			if holding_rays:
				var direction = held_objects[0].position.direction_to(get_global_mouse_position())
				for ray in held_objects:
					if setting_ray_direction:
						ray.set_direction(direction)
					else:
						ray.position += event.relative * $Camera2D.zoom
					ray_modified(ray)
			if holding_others:
				for object in held_objects:
					object.position += event.relative * $Camera2D.zoom
					scene_modified(object)
		if event is InputEventKey:
			if event.pressed and event.scancode == KEY_ESCAPE:
				for held_object in held_objects:
					held_object.queue_free()
					$Rays.remove_child(held_object)
					$Tracables.remove_child(held_object)
				scene_modified(held_objects)
				held_objects = null
				holding_rays = false
				holding_others = false
				setting_ray_direction = false
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == BUTTON_LEFT:
				dropped_object()
				if not setting_ray_direction:
					held_objects = null
					holding_rays = false
					holding_others = false
		get_tree().set_input_as_handled()
		
	
var drag = false
var skip_one_drag = false
var skipped_drag_relative = Vector2(0.0, 0.0)
var zoom_by = Vector2(0.1, 0.1)
func _unhandled_input(event):
	if event is InputEventMouseMotion and drag:
		var offset = event.relative * $Camera2D.zoom + skipped_drag_relative
		if skip_one_drag:
			skip_one_drag = false
			skipped_drag_relative = offset
		else:
			skipped_drag_relative = Vector2(0.0, 0.0)
			if $Camera2D/CanvasLayer/GUI.selected_lens != null:
				$Camera2D/CanvasLayer/GUI.selected_lens.position += offset
				scene_modified($Camera2D/CanvasLayer/GUI.selected_lens)
			elif $Camera2D/CanvasLayer/GUI.selected_ray != null:
				$Camera2D/CanvasLayer/GUI.selected_ray.position += offset
				ray_modified($Camera2D/CanvasLayer/GUI.selected_ray)
			elif $Camera2D/CanvasLayer/GUI.selected_aperture != null:
				$Camera2D/CanvasLayer/GUI.selected_aperture.position += offset
				scene_modified($Camera2D/CanvasLayer/GUI.selected_aperture)
			else:
				$Camera2D.position -= offset
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			var mouse_before = get_global_mouse_position()
			$Camera2D.zoom += zoom_by
			var mouse_after = get_global_mouse_position()
			$Camera2D.position -= mouse_after - mouse_before
		if event.button_index == BUTTON_WHEEL_UP and event.pressed:
			if $Camera2D.zoom - zoom_by > Vector2(0.0, 0.0):
				var mouse_before = get_global_mouse_position()
				$Camera2D.zoom -= zoom_by
				var mouse_after = get_global_mouse_position()
				$Camera2D.position -= mouse_after - mouse_before
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				lens_select(null)
				ray_select(null)
				aperture_select(null)
				skip_one_drag = true
			drag = event.pressed


func _on_GUI_load_save(path):    
	var save = File.new()
	if not save.file_exists(path):
		return
	
	_on_GUI_new_board()
	
	save.open(path, File.READ)
	var lenses = []
	var rays = []
	var apertures = []
	while save.get_position() < save.get_len():
		var node_data = parse_json(save.get_line())
		
		if node_data["type"] == "Lens":
			lenses.push_back(node_data)
		if node_data["type"] == "Ray":
			rays.push_back(node_data)
		if node_data["type"] == "Aperture":
			apertures.push_back(node_data)
	
	for node_data in lenses:
		var new_lens = _new_lens()
		new_lens.position = Vector2(node_data["pos_x"], node_data["pos_y"])
		new_lens.set_left_side_radius(node_data["r1"])
		new_lens.set_right_side_radius(node_data["r2"])
		new_lens.set_distance(node_data["d"])
		new_lens.set_width(node_data["width"])
		new_lens.set_height(node_data["height"])
		new_lens.refractive_index = node_data["refr_index"]
	
	for node_data in apertures:
		var new_aperture = _new_aperture()
		new_aperture.position = Vector2(node_data["pos_x"], node_data["pos_y"])
		new_aperture.width = node_data["width"]
		new_aperture.height = node_data["height"]
		new_aperture.opening = node_data["opening"]
		
	for node_data in rays:
		var new_ray = _new_ray()
		new_ray.position = Vector2(node_data["pos_x"], node_data["pos_y"])
		new_ray._direction = Vector2(node_data["dir_x"], node_data["dir_y"]).normalized()
		new_ray.width = node_data["width"]
		new_ray.default_color.r = node_data["color_r"]
		new_ray.default_color.g = node_data["color_g"]
		new_ray.default_color.b = node_data["color_b"]
		new_ray.default_color.a = node_data["color_a"]
		new_ray._actual_color = new_ray.default_color
		new_ray.trace()
		
	$Camera2D/CanvasLayer/GUI.modified = false
	save.close()

func _on_GUI_save_as(path):
	var save_game = File.new()
	save_game.open(path, File.WRITE)
	var save_nodes = $Tracables.get_children() + $Rays.get_children()
	for node in save_nodes:
		var node_data = node.call("save")
		save_game.store_line(to_json(node_data))
	save_game.close()

func _on_GUI_new_board():
	for lens in $Tracables.get_children():
		lens.queue_free()
		$Tracables.remove_child(lens)
	for ray in $Rays.get_children():
		ray.queue_free()
		$Rays.remove_child(ray)
	_on_GUI_reset_background()
