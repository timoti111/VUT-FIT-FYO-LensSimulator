extends Control

signal add_lens()
signal remove_lens(lens)

signal add_ray()
signal add_parallel_rays()
signal add_omnidirectional_rays()
signal remove_ray(ray)

signal add_aperture()
signal remove_aperture(aperture)

signal set_background(path)
signal reset_background()

signal load_save(path)
signal save_as(path)

signal new_board()

var directory: Directory = Directory.new()

const _Lens = preload("Lens.gd")
const _Ray = preload("Ray.gd")
const _Aperture = preload("Aperture.gd")

var lens_selected

var selected_lens: _Lens = null setget _set_lens
var selected_ray: _Ray = null setget _set_ray
var selected_aperture: _Aperture = null setget _set_aperture

var _save_path: String setget _set_save_path
var modified: bool setget _set_modified

var _window_title = "Lens Simulator"

func _ready():
	self.modified = false
	self._save_path = ""
	OS.set_window_title(_window_title)

func _set_save_path(value):
	if modified:
		OS.set_window_title(value + "*" + " - " + _window_title)
	else:
		OS.set_window_title(value + " - " + _window_title)
	_save_path = value
	
func _set_modified(value):
	modified = value
	if modified:
		OS.set_window_title(_save_path + "*" + " - " + _window_title)
	else:
		OS.set_window_title(_save_path + " - " + _window_title)

var _changing = false
func _set_ray(ray: _Ray):
	$RaySettingsDialog.hide()
	if ray != null:
		selected_ray = ray
		$RaySettingsDialog.popup()
		
func _set_lens(lens: _Lens):
	$LensSettingsDialog.hide()
	if lens != null:
		selected_lens = lens
		$LensSettingsDialog.popup()
		
func _set_aperture(aperture: _Aperture):
	$ApertureSettingsDialog.hide()
	if aperture != null:
		selected_aperture = aperture
		$ApertureSettingsDialog.popup()
	
func _on_LensSettingsDialog_about_to_show():
	_changing = true
	$LensSettingsDialog/MarginContainer/VBoxContainer/GridContainer/WidthSpinBox.value = selected_lens.get_width()
	$LensSettingsDialog/MarginContainer/VBoxContainer/GridContainer/HeightSpinBox.value = selected_lens.get_height()
	$LensSettingsDialog/MarginContainer/VBoxContainer/GridContainer/Radius1SpinBox.value = selected_lens.get_left_side_radius()
	$LensSettingsDialog/MarginContainer/VBoxContainer/GridContainer/Radius2SpinBox.value = selected_lens.get_right_side_radius()
	$LensSettingsDialog/MarginContainer/VBoxContainer/GridContainer/DistanceSpinBox.value = selected_lens.get_distance()
	$LensSettingsDialog/MarginContainer/VBoxContainer/GridContainer/RefrIndexSpinBox.value = selected_lens.refractive_index
	selected_lens.select(true)
	_changing = false

func _on_LensSettingsDialog_popup_hide():
	if selected_lens != null:
		selected_lens.select(false)
	selected_lens = null
	
func _on_RaySettingsDialog_about_to_show():
	_changing = true
	$RaySettingsDialog/MarginContainer/VBoxContainer/GridContainer/RayColorButton.color = selected_ray.default_color
	$RaySettingsDialog/MarginContainer/VBoxContainer/GridContainer/RayWidthSpinBox.value = selected_ray.width
	selected_ray.select(true)
	_changing = false

func _on_RaySettingsDialog_popup_hide():
	if selected_ray != null:
		selected_ray.select(false)
	selected_ray = null

func _on_ApertureSettingsDialog_about_to_show():
	_changing = true
	$ApertureSettingsDialog/MarginContainer/VBoxContainer/GridContainer/OpeningSpinBox.value = selected_aperture.opening
	$ApertureSettingsDialog/MarginContainer/VBoxContainer/GridContainer/OpeningSpinBox.max_value = selected_aperture.max_opening_size
	$ApertureSettingsDialog/MarginContainer/VBoxContainer/GridContainer/AWidthSpinBox.value = selected_aperture.width
	$ApertureSettingsDialog/MarginContainer/VBoxContainer/GridContainer/AHeightSpinBox.value = selected_aperture.height
	selected_aperture.select(true)
	_changing = false

func _on_ApertureSettingsDialog_popup_hide():
	if selected_aperture != null:
		selected_aperture.select(false)
	selected_aperture = null
	
func _on_AddRaysButtons_pressed(id):
	if id == 0:
		emit_signal("add_ray")
	if id == 1:
		emit_signal("add_parallel_rays")
	if id == 2:
		emit_signal("add_omnidirectional_rays")
	
func _on_AddLensButton_pressed():
	emit_signal("add_lens")

func _on_AddRayButton_pressed():
	emit_signal("add_ray")

func _on_AddApertureButton_pressed():
	emit_signal("add_aperture")
	
func _on_ResetBgButton_pressed():
	emit_signal("reset_background")

func _on_ChangeBgButton_pressed():
	$FileDialog.mode = $FileDialog.MODE_OPEN_FILE
	$FileDialog.clear_filters()
	$FileDialog.add_filter("*.png ; PNG Image")
	$FileDialog.add_filter("*.jpg, *.jpeg ; JPG Image")
	$FileDialog.window_title = "Load Background"
	$FileDialog.current_dir = directory.get_current_dir()
	$FileDialog.popup()
	
func _on_FileDialog_file_selected(path):
	directory.change_dir($FileDialog.current_path)
	if $FileDialog.window_title == "Load Background":
		emit_signal("set_background", path)
	if $FileDialog.window_title == "Load Save":
		_ready()
		self._save_path = path
		emit_signal("load_save", path)
	if $FileDialog.window_title == "Save As":
		self._save_path = path
		_on_SaveButton_pressed()

func _on_Radius1SpinBox_value_changed(value):
	if not _changing:
		selected_lens.set_left_side_radius(value)

func _on_Radius2SpinBox_value_changed(value):
	if not _changing:
		selected_lens.set_right_side_radius(value)

func _on_DistanceSpinBox_value_changed(value):
	if not _changing:
		selected_lens.set_distance(value)

func _on_WidthSpinBox_value_changed(value):
	if not _changing:
		selected_lens.set_width(value)

func _on_HeightSpinBox_value_changed(value):
	if not _changing:
		selected_lens.set_height(value)

func _on_RefrIndexSpinBox_value_changed(value):
	if not _changing:
		selected_lens.refractive_index = value

func _on_Remove_pressed():
	emit_signal("remove_lens", selected_lens)
	_set_lens(null)

func _on_RemoveRayButton_pressed():
	emit_signal("remove_ray", selected_ray)
	_set_ray(null)
	
func _on_RemoveApertureButton_pressed():
	emit_signal("remove_aperture", selected_aperture)
	_set_aperture(null)
	
func _on_RayColorButton_color_changed(color):
	if not _changing:
		selected_ray.default_color = color
		self.modified = true
	
func _on_RayWidthSpinBox_value_changed(value):
	if not _changing:
		selected_ray.width = value
		self.modified = true

func _on_LoadButton_pressed():
	$FileDialog.mode = $FileDialog.MODE_OPEN_FILE
	$FileDialog.clear_filters()
	$FileDialog.add_filter("*.lens ; Lens Save")
	$FileDialog.window_title = "Load Save"
	$FileDialog.current_dir = directory.get_current_dir()
	$FileDialog.popup()

func _on_SaveButton_pressed():
	if _save_path.empty():
		_on_SaveAsButton_pressed()
	else:
		emit_signal("save_as", _save_path)
		self.modified = false

func _on_SaveAsButton_pressed():
	$FileDialog.mode = $FileDialog.MODE_SAVE_FILE
	$FileDialog.clear_filters()
	$FileDialog.add_filter("*.lens ; Lens Save")
	$FileDialog.window_title = "Save As"
	$FileDialog.current_dir = directory.get_current_dir()
	$FileDialog.popup()
	
func _on_NewButton_pressed():
	emit_signal("new_board")
	_ready()
	
func _on_HelpButton_pressed():
	$HelpDialog.popup_centered()

func _on_AWidthSpinBox_value_changed(value):
	if not _changing:
		selected_aperture.width = value
		self.modified = true

func _on_AHeightSpinBox_value_changed(value):
	if not _changing:
		selected_aperture.height = value
		$ApertureSettingsDialog/MarginContainer/VBoxContainer/GridContainer/OpeningSpinBox.max_value = selected_aperture.max_opening_size
		_changing = true
		$ApertureSettingsDialog/MarginContainer/VBoxContainer/GridContainer/OpeningSpinBox.value = selected_aperture.opening
		_changing = false
		self.modified = true

func _on_OpeningSpinBox_value_changed(value):
	if not _changing:
		selected_aperture.opening = value
		self.modified = true


func _on_AddRaysButtons_ready():
	$PanelContainer/HBoxContainer/AddRaysButtons.get_popup().connect("id_pressed", self,"_on_AddRaysButtons_pressed")
