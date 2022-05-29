extends Node2D

const _Ray = preload("res://Ray.gd")

signal clicked(aperture)
signal modified(aperture)

var _upper_line_collision: CollisionShape2D
var _upper_line_shape: RectangleShape2D
var _lower_line_collision: CollisionShape2D
var _lower_line_shape: RectangleShape2D

var _upper_line: Line2D
var _lower_line: Line2D

var height: float setget _set_height
var width: float setget _set_width
var opening: float setget _set_opening
var max_opening_size: float setget , _get_opening

func select(var selected: bool):
	if selected:
		_upper_line.default_color = Color.gray
		_lower_line.default_color = Color.gray
	else:
		_upper_line.default_color = Color.black
		_lower_line.default_color = Color.black
		
func _set_height(value):
	if height * 0.9 < opening:
		opening = height * 0.9
	height = value
	_create_aperture()
	
func _set_width(value):
	if value > 1.0:
		width = value
		_create_aperture()
	
func _set_opening(value):
	opening = value
	_create_aperture()
	
func _get_opening():
	return height * 0.9
	
func _create_aperture():
	var half_height = height * 0.5
	var opening_half_height = opening * 0.5
	var point1 = Vector2(0.0, opening_half_height)
	var point2 = Vector2(0.0, half_height)
	_upper_line.width = width
	_lower_line.width = width
	_upper_line.clear_points()
	_lower_line.clear_points()
	_lower_line.add_point(point1)
	_lower_line.add_point(point2)
	_upper_line.add_point(point1 * Vector2(0.0, -1.0))
	_upper_line.add_point(point2 * Vector2(0.0, -1.0))
	var one_line_half_height = (height - opening) * 0.25
	_lower_line_collision.position = Vector2(0.0, opening_half_height + one_line_half_height)
	_upper_line_collision.position = Vector2(0.0, -(opening_half_height + one_line_half_height))
	_lower_line_shape.extents = Vector2(width * 0.5, one_line_half_height)
	_upper_line_shape.extents = Vector2(width * 0.5, one_line_half_height)
	emit_signal("modified", self)

func _ready():
	self.position = Vector2(400,400)
	_upper_line_collision = CollisionShape2D.new()
	_upper_line_shape = RectangleShape2D.new()
	_upper_line_collision.shape = _upper_line_shape
	_lower_line_collision = CollisionShape2D.new()
	_lower_line_shape = RectangleShape2D.new()
	_lower_line_collision.shape = _lower_line_shape
	var area2d = Area2D.new()
	area2d.connect("input_event", self, "_on_Aperture_input_event")
	area2d.add_child(_upper_line_collision)
	area2d.add_child(_lower_line_collision)
	add_child(area2d)
	_upper_line = Line2D.new()
	_lower_line = Line2D.new()
	_upper_line.default_color = Color.black
	_lower_line.default_color = Color.black
	add_child(_upper_line)
	add_child(_lower_line)
	height = 100
	opening = 30
	width = 4
	_create_aperture()

func _on_Aperture_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				emit_signal("clicked", self)

func _intersect_ray_line(line_origin: Vector2, line_end: Vector2, ray_origin: Vector2, ray_direction: Vector2):
	var line_direction: Vector2 = line_origin.direction_to(line_end)
	var denominator = ray_direction.cross(line_direction)
	if denominator == 0.0:
		return -1.0
	
	denominator = 1.0 / denominator
	var numerator_u = line_origin - ray_origin
	var numerator_t = numerator_u.cross(line_direction)
	numerator_u = numerator_u.cross(ray_direction)
	var u = numerator_u * denominator
	var t = numerator_t * denominator
	
	if u >= 0.0 and u <= line_origin.distance_to(line_end):
		return t
	else:
		return -1.0

var last_going_inside = null
func intersect(segment: _Ray.Segment):
	var global_origin = segment.origin
	segment.origin = to_local(global_origin)
	var t0 = _intersect_ray_line(_upper_line.get_point_position(0), _upper_line.get_point_position(1), segment.origin, segment.direction)
	var t1 = _intersect_ray_line(_lower_line.get_point_position(0), _lower_line.get_point_position(1), segment.origin, segment.direction)
	segment.origin = global_origin
	if t0 > 0 and t0 < segment.t:
		segment.t = t0
		segment.blocked = true
	if t1 > 0 and t1 < segment.t:
		segment.t = t1
		segment.blocked = true

func save():
	var save_dict = {
		"type": "Aperture",
		"pos_x": self.position.x,
		"pos_y": self.position.y,
		"opening": self.opening,
		"width": self.width,
		"height": self.height
	}
	return save_dict
