extends Line2D

signal clicked(lens)
signal modified(lens)

var _Lens = load("res://Lens.gd")

var _points: PoolVector2Array
var _origin: Vector2 = Vector2(0.0, 0.0)
var _direction: Vector2 = Vector2(-1.0, 0.0)
var _segments = []
var _objects: Node2D
var _actual_color: Color
var _selected = false

func select(selected: bool):
	_selected = selected
	if selected:
		_actual_color = Color.orange
		_right_pressed = false
	else:
		_actual_color = self.default_color
		_right_pressed = false
		
func set_direction(value):
	_direction = value.normalized()
	emit_signal("modified", self)
	
var _right_pressed = false
func _input(event):
	if _selected:
		var change_direction = false
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_RIGHT:
				_right_pressed = event.pressed
				if event.pressed:
					set_direction(_origin.direction_to(to_local(get_global_mouse_position())))
				get_tree().set_input_as_handled()
		if event is InputEventMouseMotion and _right_pressed:
			set_direction(_origin.direction_to(to_local(get_global_mouse_position())))
			get_tree().set_input_as_handled()
			
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			emit_signal("clicked", self)

func _init(objects: Node2D):
	self.position = Vector2(400, 400)
	self._objects = objects
	
var collision_shape: CircleShape2D
func _ready():
	self.trace()
	var area2d = Area2D.new()
	area2d.connect("input_event", self, "_input_event")
	self.add_child(area2d)
	
	var collision = CollisionShape2D.new()
	collision_shape = CircleShape2D.new()
	collision_shape.radius = 15
	collision.shape = collision_shape
	area2d.add_child(collision)
	width = 3
	default_color = Color.yellow
	_actual_color = default_color
	set_process(true)
	
func _process(delta):
	update()

func _draw():
	draw_circle(_origin, collision_shape.radius, _actual_color)

func _refract(var incidence: Vector2, var normal: Vector2, var eta: float):
	var dotNI = normal.dot(incidence)
	var k = 1.0 - eta * eta * (1.0 - pow(dotNI, 2.0))
	if k < 0.0:
		return null
	else:
		return (eta * incidence - (eta * dotNI + sqrt(k)) * normal).normalized();

func trace():	
	self.clear_points()
	_segments.clear()
	var _new_segment = Segment.new(to_global(_origin), _direction)
	_segments.append(_new_segment)
	
	var lens_stack = []
	var cycle = true
	for object in _objects.get_children():
		object.last_going_inside = null
	while cycle:
		for object in _objects.get_children():
			object.intersect(_segments.back())
		var last_segment = _segments.back()
		if last_segment.modified and not last_segment.blocked:
			var new_origin = last_segment.origin + last_segment.t * last_segment.direction
			var last_n = 1.0
			var new_n = 1.0
			if last_segment.going_inside:
				if lens_stack.empty():
					last_n = 1.0
				else:
					last_n = lens_stack.back().refractive_index
				lens_stack.push_back(last_segment.hit_object)
				new_n = last_segment.hit_object.refractive_index
			else:
				last_n = last_segment.hit_object.refractive_index
				lens_stack.erase(last_segment.hit_object)
				if lens_stack.empty():
					new_n = 1.0
				else:
					new_n = lens_stack.back().refractive_index
			var eta = last_n / new_n
			var new_direction = self._refract(last_segment.direction, last_segment.hit_normal, eta)
			if new_direction != null:
				var new_segment = Segment.new(new_origin, new_direction)
				new_segment.last_hit_object = last_segment.hit_object
				_segments.push_back(new_segment)
				continue
		cycle = false
	
	self.add_point(to_local(_segments[0].origin))
	for i in range(0, _segments.size()):
		var last_point = self.get_point_position(i)
		var new_point = last_point + _segments[i].t * _segments[i].direction
		self.add_point(new_point)

class Segment:
	var blocked: bool = false
	var modified: bool = false
	var t: float = 99999999
	var hit_object = null
	var last_hit_object = null
	var going_inside: bool
	var hit_normal: Vector2
	var origin: Vector2
	var direction: Vector2
	
	func _init(origin: Vector2, direction: Vector2):
		self.origin = origin
		self.direction = direction
		
func save():
	var save_dict = {
		"type": "Ray",
		"pos_x": self.position.x,
		"pos_y": self.position.y,
		"dir_x": self._direction.x,
		"dir_y": self._direction.y,
		"width": self.width,
		"color_r": self.default_color.r,
		"color_g": self.default_color.g,
		"color_b": self.default_color.b,
		"color_a": self.default_color.a
	}
	return save_dict
		
