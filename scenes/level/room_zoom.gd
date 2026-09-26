class_name RoomZoom
extends Node
## Looking closer (F7): pinch or the mouse wheel zooms the room, dragging looks around while zoomed
## in, double-tapping an empty spot zooms in there (and back out), and the + / - buttons do the same.
## Taps still work as before: a press only becomes a drag once it has moved a little.

const MAX_ZOOM := 2.5
const STEP := 1.25
const DOUBLE_TAP_SECONDS := 0.35
const DOUBLE_TAP_ZOOM := 2.0
## Screen pixels a press has to move before it pans instead of tapping.
const DRAG_START := 24.0

signal zoom_changed(zoom: float)

var view: RoomView
## Returns true while something covers the room (a close-up, a dialog, the pause menu...).
var blocked: Callable = func() -> bool: return false
## Returns true when a screen position is over the UI (buttons, the inventory bar...).
var over_ui: Callable = func(_at: Vector2) -> bool: return false

var _touches: Dictionary = {}
var _pinch_distance := 0.0
var _pinch_zoom := 1.0
var _pinch_mid := Vector2.ZERO
var _press_at := Vector2.INF
var _dragging := false
## A pinch happened during this press: its release must not count as a tap.
var _pinched := false
## Set when a press ended as a drag or pinch; the level ignores the tap that comes with its release.
var _swallow_tap := false
var _last_tap_msec := -100000
var _last_tap_at := Vector2.INF
var _tween: Tween


func _init(room_view: RoomView) -> void:
	view = room_view


## True (once) when the tap being handled was really the end of a drag or pinch.
func swallow_tap() -> bool:
	var s := _swallow_tap
	_swallow_tap = false
	return s


func zoom() -> float:
	return view.view_zoom


func zoom_in() -> void:
	animate_to(view.view_zoom * STEP, _screen_center())


func zoom_out() -> void:
	animate_to(view.view_zoom / STEP, _screen_center())


## Back to the whole room.
func reset(seconds: float = 0.35) -> void:
	animate_to(1.0, _screen_center(), seconds)


## Zooms to `target` keeping the room point under `screen_pos` in place.
func animate_to(target: float, screen_pos: Vector2, seconds: float = 0.3) -> void:
	target = clampf(target, 1.0, MAX_ZOOM)
	if _tween and _tween.is_valid():
		_tween.kill()
	if bool(SaveManager.settings.get("reduce_motion", false)) or seconds <= 0.0 or not is_inside_tree():
		_set_zoom(target, screen_pos)
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_method(func(z: float) -> void: _set_zoom(z, screen_pos), view.view_zoom, target, seconds)


func _set_zoom(z: float, screen_pos: Vector2) -> void:
	var before := view.view_zoom
	view.zoom_view_at(screen_pos, z)
	if not is_equal_approx(before, view.view_zoom):
		zoom_changed.emit(view.view_zoom)


func _screen_center() -> Vector2:
	return view.get_viewport().get_visible_rect().size / 2.0 if view.is_inside_tree() else RoomView.STAGE_SIZE / 2.0


func _input(event: InputEvent) -> void:
	if blocked.call():
		_touches.clear()
		_press_at = Vector2.INF
		_dragging = false
		return
	# Two fingers: pinch to zoom, move them together to look around.
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and not over_ui.call(st.position):
			_touches[st.index] = st.position
		else:
			_touches.erase(st.index)
		if _touches.size() == 2:
			_start_pinch()
		return
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _touches.has(sd.index):
			_touches[sd.index] = sd.position
			if _touches.size() >= 2:
				_update_pinch()
		return
	if event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		if not over_ui.call(mg.position):
			_set_zoom(clampf(view.view_zoom * mg.factor, 1.0, MAX_ZOOM), mg.position)
		return
	if event is InputEventPanGesture:
		var pg := event as InputEventPanGesture
		if view.view_zoom > 1.0 and not over_ui.call(pg.position):
			view.pan_view(-pg.delta * 12.0)
		return
	if event is InputEventMouseButton:
		_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_mouse_motion(event as InputEventMouseMotion)


func _mouse_button(mb: InputEventMouseButton) -> void:
	if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if over_ui.call(mb.position):
			return
		var f := 1.12 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12
		_set_zoom(clampf(view.view_zoom * f, 1.0, MAX_ZOOM), mb.position)
		get_viewport().set_input_as_handled()
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_pinched = false
		_swallow_tap = false
		_press_at = Vector2.INF if over_ui.call(mb.position) or get_viewport().gui_is_dragging() else mb.position
		_dragging = false
		return
	if _pinched:
		_swallow_tap = true
		_pinched = false
	if _press_at == Vector2.INF:
		return
	if _dragging:
		# The press became a look-around: don't let it count as a tap on whatever is under it.
		_swallow_tap = true
	elif _touches.size() < 2:
		_maybe_double_tap(mb.position)
	_press_at = Vector2.INF
	_dragging = false


func _mouse_motion(mm: InputEventMouseMotion) -> void:
	if _press_at == Vector2.INF or not (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) or _touches.size() >= 2:
		return
	if get_viewport().gui_is_dragging():
		_press_at = Vector2.INF
		return
	if not _dragging and view.view_zoom > 1.001 and mm.position.distance_to(_press_at) > DRAG_START:
		_dragging = true
	if _dragging:
		view.pan_view(mm.relative)


## Two quick taps on the same spot zoom in there, or back out when already zoomed in.
func _maybe_double_tap(at: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_tap_msec < int(DOUBLE_TAP_SECONDS * 1000.0) and at.distance_to(_last_tap_at) < 60.0:
		_last_tap_msec = -100000
		_last_tap_at = Vector2.INF
		if view.view_zoom > 1.2:
			reset()
		else:
			animate_to(DOUBLE_TAP_ZOOM, at)
		return
	_last_tap_msec = now
	_last_tap_at = at


func _start_pinch() -> void:
	var p: Array = _touches.values()
	_pinch_distance = maxf((p[0] as Vector2).distance_to(p[1] as Vector2), 1.0)
	_pinch_zoom = view.view_zoom
	_pinch_mid = ((p[0] as Vector2) + (p[1] as Vector2)) / 2.0
	_press_at = Vector2.INF
	_dragging = false
	_pinched = true


func _update_pinch() -> void:
	var p: Array = _touches.values()
	var a := p[0] as Vector2
	var b := p[1] as Vector2
	var mid := (a + b) / 2.0
	_set_zoom(clampf(_pinch_zoom * a.distance_to(b) / _pinch_distance, 1.0, MAX_ZOOM), mid)
	view.pan_view(mid - _pinch_mid)
	_pinch_mid = mid
