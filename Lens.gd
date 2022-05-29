extends Area2D

signal clicked(lens)
signal modified(lens)

const _Ray = preload("res://Ray.gd")

var lens_bounds = PoolVector2Array()
var bounds_color = PoolColorArray([Color(1.0, 0.0, 0.0)])

var lens_color_actual = PoolColorArray([Color(0.0, 1.0, 1.0, 0.5)])
var lens_color_selected = PoolColorArray([Color(0.0, 0.5, 1.0, 0.5)])
var lens_color_unselected = PoolColorArray([Color(0.0, 1.0, 1.0, 0.5)])
var lens_points = PoolVector2Array()

var arc1points = PoolVector2Array()
var arc2points = PoolVector2Array()

var botton_arc_points = []

var bounds
var circle1
var circle2

var refractive_index = 1.52 setget _set_refractive_index

func select(var selected: bool):
	if selected:
		lens_color_actual = lens_color_selected
	else:
		lens_color_actual = lens_color_unselected

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			var local_position = to_local(get_global_mouse_position())
			var hit = circle1.point_inside(local_position) and circle2.point_inside(local_position)
			if event.pressed and hit:
				emit_signal("clicked", self)

func _set_refractive_index(value: float):
	refractive_index = value
	emit_signal("modified", self)

func set_left_side_radius(value: float):
	circle1.set_radius(value)
	create_lens()
func get_left_side_radius():
	return circle1.get_radius()

func set_right_side_radius(value: float):
	circle2.set_radius(value)
	create_lens()
func get_right_side_radius():
	return circle2.get_radius()

func set_distance(value: float):
	if (value != 0.0):
		circle1.set_x_offset(-value * 0.5)
		circle2.set_x_offset(value * 0.5)
		create_lens()
func get_distance():
	return 2 * circle2.get_x_offset()

func set_width(width: float):
	bounds.set_width(width)
	create_lens()
func get_width():
	return bounds.get_width()
	
func set_height(height: float):
	bounds.set_height(height)
	create_lens()
func get_height():
	return bounds.get_height()

enum PointDestination {ARC1, ARC2}
func add_point(point: Vector2, index):
	match index:
		PointDestination.ARC1:
			arc1points.insert(0, point)
			if point.y != 0.0:
				point.y = -point.y
				arc1points.push_back(point)
		PointDestination.ARC2:
			arc2points.push_back(point)
			if point.y != 0.0:
				point.y = -point.y
				arc2points.insert(0, point)

func create_arc(circle: Circle, intersection):
	var arc = circle.create_arc(180, 4.7)
	var filtered = []
	for point in arc:
		var point_valid = false
		if intersection != null:
			var radius_sign = sign(circle.get_radius())
			if radius_sign * point.x < radius_sign * intersection.x:
				point_valid = true
		else:
			point_valid = true
		if point_valid:
			filtered.push_back(point)
	return filtered
	
var intersection_point
func create_lens():
	circle1.set_bounds(bounds)
	circle2.set_bounds(bounds)
	botton_arc_points.clear()
	arc1points = PoolVector2Array()
	arc2points = PoolVector2Array()
	lens_points = PoolVector2Array()
	lens_bounds = PoolVector2Array()
	var half_width = bounds.get_max_x()
	var half_height = bounds.get_max_y()
	var arc1_valid = circle1.is_valid()
	var arc2_valid = circle2.is_valid()
	
	var circ_intersections = circle1.intersect(circle2)
	intersection_point = null
	if circ_intersections != null and arc1_valid and arc2_valid:
		if bounds.in_bounds(circ_intersections[1]):
			intersection_point = circ_intersections[1]
	
	var arc1 = []
	var arc2 = []
	if arc1_valid:
		arc1 = create_arc(circle1, intersection_point)
	if arc2_valid:
		arc2 = create_arc(circle2, intersection_point)
		
	if intersection_point != null:
		arc1.push_back(intersection_point)
	else:
		if not arc2.empty():
			botton_arc_points.push_back(arc2.back())
		if (arc1.empty() or arc1.back().x < bounds.get_max_x() - 0.0001) and (arc2.empty() or (arc2.back().y < bounds.get_max_y() - 0.0001 and arc2.back().x > 0)):
			arc2.push_back(Vector2(bounds.get_max_x(), bounds.get_max_y()))
			botton_arc_points.push_back(arc2.back())
		if (arc2.empty() or arc2.back().x > bounds.get_min_x() + 0.0001) and (arc1.empty() or (arc1.back().y < bounds.get_max_y() - 0.0001 and arc1.back().x < 0)):
			arc1.push_back(Vector2(bounds.get_min_x(), bounds.get_max_y()))
			botton_arc_points.push_back(arc1.back())
		if not arc1.empty():
			botton_arc_points.push_back(arc1.back())
			
	for point in arc1:
		add_point(point, PointDestination.ARC1)
	for point in arc2:
		add_point(point, PointDestination.ARC2)
		
	lens_points.append_array(arc1points)
	lens_points.append_array(arc2points)
	lens_bounds.push_back(Vector2(half_width, half_height))
	lens_bounds.push_back(Vector2(half_width, -half_height))
	lens_bounds.push_back(Vector2(-half_width, -half_height))
	lens_bounds.push_back(Vector2(-half_width, half_height))
	collision_shape.extents = Vector2(half_width, half_height)
	emit_signal("modified", self)

var collision_shape: RectangleShape2D
func _ready():
	bounds = Bounds.new(200, 400)
	circle1 = Circle.new(160, -30, bounds)
	circle2 = Circle.new(160, 30, bounds)
	var collision = CollisionShape2D.new()
	collision_shape = RectangleShape2D.new()
	collision.shape = collision_shape
	add_child(collision)
	create_lens()
	set_process(true)
	
func _process(delta):
	update()

func _draw():
	draw_polygon(lens_points, lens_color_actual)

class Circle:
	const _Ray = preload("res://Ray.gd")
	var _radius: float
	var _bounds
	var _x_offset: float
	var _valid: bool
	
	func _init(radius: float, x_offest: float, bounds: Bounds):
		_bounds = bounds
		_radius = radius
		_x_offset = x_offest
		_check_validity()
		
	func _check_validity():
		_valid = abs(_x_offset) < _bounds.get_max_x() and not _bounds.in_bounds(Vector2(2 * _radius + _x_offset, 0.0))
	
	func is_valid():
		return _valid
		
	func set_radius(radius: float):
		_radius = radius
		_check_validity()
	func get_radius():
		return _radius
	func set_bounds(bounds: Bounds):
		_bounds = bounds
		_check_validity()
	func get_bounds():
		return _bounds
	func set_x_offset(x_offset: float):
		_x_offset = x_offset
		_check_validity()
	func get_x_offset():
		return _x_offset
		
	func point_inside(point: Vector2):
		if not _valid:
			return true
		var signum = sign(_x_offset) * sign(_radius)
		var value = pow(point.x - _x_offset - _radius, 2.0) + pow(point.y, 2.0) - pow(_radius, 2.0) 
		return value * signum > 0.0
		
	func solve_for_x(x: float):
		var y2 = _radius * _radius - pow(-x + _x_offset + _radius, 2.0)
		if y2 < 0.0:
			return null
		var y = sqrt(y2)
		return [Vector2(x, -y), Vector2(x, y)]
		
	func solve_for_y(y: float):
		var d = _x_offset
		var r = _radius
		var a = 1
		var b = -2.0 * (r + d)
		var c = 2 * r * d + d * d + y * y
		var D = b * b - 4.0 * a * c
		if D < 0.0:
			return null
		return [Vector2((-b - sqrt(D)) * 0.5, y), Vector2((-b + sqrt(D)) * 0.5, y)]
		
	func intersect(circle: Circle):
		var d = abs(_x_offset) + abs(circle.get_x_offset())
		var r1 = _radius
		var r2 = circle.get_radius()
		var denominator = 2.0 * (-r1 + r2 + d)
		if denominator == 0.0:
			return null
		var numerator = d * (r1 + r2)
		var x = numerator / denominator
		return solve_for_x(x)
		
	func intersect_line_segment(segment: _Ray.Segment, intersection, last_going_inside):
		var intersected = false
		if not _valid:
			return intersected
		var origin = segment.origin
		var direction = segment.direction
		var circle_center = Vector2(_x_offset + _radius, 0.0)
		var circle_dir = circle_center - origin
		var tca = circle_dir.dot(direction)
		var d2 = circle_dir.dot(circle_dir) - tca * tca
		var radius2 = pow(_radius, 2.0)
		if d2 > radius2:
			return intersected
		var thc = sqrt(radius2 - d2)
		var t0 = tca - thc
		var t1 = tca + thc
		
		var signum = sign(_radius) * sign(_x_offset)
		if t0 > 0 and t0 < segment.t:
			var point: Vector2 = origin + t0 * direction
			if _bounds.in_bounds(point) and (intersection == null or sign(_radius) * point.x < sign(_radius) * intersection.x):
				var normal = signum * point.direction_to(circle_center)
				var dotDirNor = direction.dot(normal)
				var going_inside = dotDirNor < 0
				if going_inside != last_going_inside:
					segment.t = t0
					segment.going_inside = going_inside
					segment.hit_normal = -sign(dotDirNor) * normal
					segment.modified = true
					intersected = true
		
		if t1 > 0 and t1 < segment.t:
			var point: Vector2 = origin + t1 * direction
			if _bounds.in_bounds(point) and (intersection == null or sign(_radius) * point.x < sign(_radius) * intersection.x):
				var normal = signum * point.direction_to(circle_center)
				var dotDirNor = direction.dot(normal)
				var going_inside = dotDirNor < 0
				if going_inside != last_going_inside:
					segment.t = t1
					segment.going_inside = going_inside
					segment.hit_normal = -sign(dotDirNor) * normal
					segment.modified = true
					intersected = true
		return intersected
		
	func create_arc(max_angle: float, step: float):
		var center = Vector2(_radius + _x_offset, 0.0)
		var i = 0
		var points = []
		while i * step <= max_angle:
			var angle = deg2rad(i * step)
			var new_arc_point = center + Vector2(-sign(_radius) * cos(angle), sin(angle)) * abs(_radius) # calculate new upper arc1 point
			if _bounds.in_bounds(new_arc_point):
				points.push_back(new_arc_point)
			else:
				var x = sign(_radius) * _bounds.get_max_x()
				var bound_x_intersection = solve_for_x(x)
				var y = _bounds.get_max_y()
				var bound_y_intersection = solve_for_y(y)
				var y_in_bound = false
				if bound_y_intersection != null:
					var intersection
					if _radius > 0:
						intersection = bound_y_intersection[0]
					else:
						intersection = bound_y_intersection[1]
					if _bounds.in_x_bounds(intersection):
						points.push_back(intersection)
						y_in_bound = true
				if bound_x_intersection != null and not y_in_bound:
					if _bounds.in_y_bounds(bound_x_intersection[1]):
						points.push_back(bound_x_intersection[1])
				break
			i += 1
		return points

class Bounds:
	var _width
	var _height
	var _min_x
	var _max_x
	var _min_y
	var _max_y
	
	func _init(width: float, height: float):
		set_width(width)
		set_height(height)
		
	func set_width(width: float):
		_width = width
		_max_x = width * 0.5
		_min_x = -_max_x
	func set_height(height: float):
		_height = height
		_max_y = height * 0.5
		_min_y = -_max_y
	func get_width():
		return _width
	func get_height():
		return _height
		
	func in_bounds(point: Vector2):
		return point.x >= _min_x and point.x <= _max_x and point.y >= _min_y and point.y <= _max_y
	func in_x_bounds(point: Vector2):
		return point.x >= _min_x and point.x <= _max_x
	func in_y_bounds(point: Vector2):
		return point.y >= _min_y and point.y <= _max_y
	func get_min_x():
		return _min_x
	func get_max_x():
		return _max_x
	func get_min_y():
		return _min_y
	func get_max_y():
		return _max_y
		
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
		
func  _intersect_lens_openings(segment: _Ray.Segment):
	var intersected = false
	var ray_origin: Vector2 = segment.origin
	var ray_direction: Vector2 = segment.direction
	if botton_arc_points.size() > 0:
		if not circle1.is_valid():
			var line_origin: Vector2 = Vector2(botton_arc_points.back())
			var line_end = line_origin * Vector2(1.0, -1.0)
			var t = _intersect_ray_line(line_origin, line_end, ray_origin, ray_direction)
			if t > 0 and t < segment.t:
				var line_direction = line_origin.direction_to(line_end)
				var normal: Vector2 = Vector2(line_direction.y, -line_direction.x)
				var dotDirNor = ray_direction.dot(normal)
				var going_inside = dotDirNor < 0
				if going_inside != last_going_inside:
					segment.t = t
					segment.going_inside = going_inside
					segment.hit_normal = -sign(dotDirNor) * normal
					segment.modified = true
					intersected = true
		if not circle2.is_valid():
			var line_end: Vector2 = Vector2(botton_arc_points.front())
			var line_origin = line_end * Vector2(1.0, -1.0)
			var t = _intersect_ray_line(line_origin, line_end, ray_origin, ray_direction)
			if t > 0 and t < segment.t:
				var line_direction = line_origin.direction_to(line_end)
				var normal: Vector2 = Vector2(line_direction.y, -line_direction.x)
				var dotDirNor = ray_direction.dot(normal)
				var going_inside = dotDirNor < 0
				if going_inside != last_going_inside:
					segment.t = t
					segment.going_inside = going_inside
					segment.hit_normal = -sign(dotDirNor) * normal
					segment.modified = true
					intersected = true
		for cap in range(-1, 2, 2):
			for i in range(1, botton_arc_points.size()):
				var line_origin: Vector2 = botton_arc_points[i - 1] * Vector2(1.0, cap)
				var line_end: Vector2 = botton_arc_points[i] * Vector2(1.0, cap)
				var t = _intersect_ray_line(line_origin, line_end, ray_origin, ray_direction)
				if t > 0 and t < segment.t:
					var line_direction = line_origin.direction_to(line_end)
					var normal: Vector2 = Vector2(cap * line_direction.y, -cap * line_direction.x)
					var dotDirNor = ray_direction.dot(normal)
					var going_inside = dotDirNor < 0
					if going_inside != last_going_inside:
						segment.t = t
						segment.going_inside = going_inside
						segment.hit_normal = -sign(dotDirNor) * normal
						segment.modified = true
						intersected = true
	return intersected

var last_going_inside = null
func intersect(segment: _Ray.Segment):
	if segment.last_hit_object != self:
		last_going_inside = null
		
	var global_origin = segment.origin
	segment.origin = to_local(global_origin)
	var intersected: bool = circle1.intersect_line_segment(segment, intersection_point, last_going_inside)
	intersected = circle2.intersect_line_segment(segment, intersection_point, last_going_inside) or intersected
	intersected = _intersect_lens_openings(segment) or intersected
	segment.origin = global_origin
		
	if intersected:
		segment.blocked = false
		segment.hit_object = self
		segment.hit_normal = segment.hit_normal.normalized()
		last_going_inside = segment.going_inside
	else:
		last_going_inside = null
		
func save():
	var save_dict = {
		"type": "Lens",
		"pos_x": self.position.x,
		"pos_y": self.position.y,
		"r1": self.get_left_side_radius(),
		"r2": self.get_right_side_radius(),
		"d": self.get_distance(),
		"width": self.get_width(),
		"height": self.get_height(),
		"refr_index": self.refractive_index
	}
	return save_dict
