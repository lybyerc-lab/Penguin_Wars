class_name WeaponRack
extends Node2D
## Personal runtime inventory for one penguin's weapons. Definitions stay shared
## Resources; every occupied slot owns a separate WeaponController instance.

const DEFAULT_CAPACITY: int = 6

@export_range(1, DEFAULT_CAPACITY) var slot_capacity: int = DEFAULT_CAPACITY

var owner_player: PenguinPlayer
var _loadout: Array[WeaponDefinition] = []
var _slots: Array[WeaponDefinition] = []
var _controllers: Array[WeaponController] = []

func setup(player: PenguinPlayer) -> void:
	owner_player = player
	_reset_slots(slot_capacity)
	for index: int in range(mini(_loadout.size(), slot_capacity)):
		_set_slot(index, _loadout[index])

## The one spawn-time loadout path. Calling this later intentionally resets the
## rack, which is what a fresh run or selected character needs.
func configure_loadout(definitions: Array[WeaponDefinition], capacity_to_use: int = DEFAULT_CAPACITY) -> void:
	slot_capacity = clampi(capacity_to_use, 1, DEFAULT_CAPACITY)
	_loadout = definitions.duplicate()
	if owner_player != null:
		_reset_slots(slot_capacity)
		for index: int in range(mini(_loadout.size(), slot_capacity)):
			_set_slot(index, _loadout[index])

func capacity() -> int:
	return slot_capacity

func occupied_count() -> int:
	var count := 0
	for definition: WeaponDefinition in _slots:
		if definition != null:
			count += 1
	return count

## All slot entries, including empty slots, in rack order. Returned as a copy.
func slots() -> Array[WeaponDefinition]:
	return _slots.duplicate()

## Occupied definitions in rack order, for future offer and merge code.
func weapons() -> Array[WeaponDefinition]:
	var owned: Array[WeaponDefinition] = []
	for definition: WeaponDefinition in _slots:
		if definition != null:
			owned.append(definition)
	return owned

func weapon_at(slot: int) -> WeaponDefinition:
	return _slots[slot] if _valid_slot(slot) else null

func controller_at(slot: int) -> WeaponController:
	return _controllers[slot] if _valid_slot(slot) else null

func is_slot_empty(slot: int) -> bool:
	return _valid_slot(slot) and _slots[slot] == null

func first_empty_slot() -> int:
	for slot: int in range(slot_capacity):
		if _slots[slot] == null:
			return slot
	return -1

## Returns the inserted slot, or -1 when full or given no definition.
func add_weapon(definition: WeaponDefinition) -> int:
	var slot := first_empty_slot()
	if definition == null or slot < 0:
		return -1
	_set_slot(slot, definition)
	return slot

## Inserts only into an empty valid slot, preserving existing ownership.
func insert_weapon(slot: int, definition: WeaponDefinition) -> bool:
	if definition == null or not is_slot_empty(slot):
		return false
	_set_slot(slot, definition)
	return true

## Replaces an occupied or empty valid slot. Null definitions are rejected;
## remove_weapon() is the explicit emptying operation.
func replace_weapon(slot: int, definition: WeaponDefinition) -> bool:
	if definition == null or not _valid_slot(slot):
		return false
	_set_slot(slot, definition)
	return true

func remove_weapon(slot: int) -> WeaponDefinition:
	if not _valid_slot(slot):
		return null
	var removed := _slots[slot]
	_set_slot(slot, null)
	return removed

func clear() -> void:
	for slot: int in range(slot_capacity):
		_set_slot(slot, null)

func _reset_slots(new_capacity: int) -> void:
	for controller: WeaponController in _controllers:
		if is_instance_valid(controller):
			controller.queue_free()
	_slots.clear()
	_controllers.clear()
	_slots.resize(new_capacity)
	_controllers.resize(new_capacity)

func _set_slot(slot: int, definition: WeaponDefinition) -> void:
	if not _valid_slot(slot):
		return
	var previous: WeaponController = _controllers[slot]
	if is_instance_valid(previous):
		previous.queue_free()
	_slots[slot] = definition
	_controllers[slot] = null
	if definition == null or owner_player == null:
		return
	var controller := WeaponController.new()
	controller.name = "WeaponSlot%d" % slot
	controller.definition = definition
	controller.wielder = owner_player
	controller.z_index = 1
	var visual := WeaponVisual.new()
	visual.name = "Visual"
	controller.add_child(visual)
	add_child(controller)
	_controllers[slot] = controller

func _valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < slot_capacity
