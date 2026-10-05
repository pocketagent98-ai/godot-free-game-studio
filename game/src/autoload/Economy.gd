extends Node
## Economy — coins, diamonds and every purchase/unlock. No in-app purchases.
## Currency is earned only by racing, daily tasks and rewarded ads.

signal changed()

func coins() -> int:
	return int(SaveManager.get_value("coins", 0))

func diamonds() -> int:
	return int(SaveManager.get_value("diamonds", 0))

func add_coins(amount: int) -> void:
	SaveManager.set_value("coins", maxi(0, coins() + amount))
	changed.emit()

func add_diamonds(amount: int) -> void:
	SaveManager.set_value("diamonds", maxi(0, diamonds() + amount))
	changed.emit()

func spend_coins(amount: int) -> bool:
	if coins() < amount:
		return false
	SaveManager.set_value("coins", coins() - amount)
	changed.emit()
	return true

func spend_diamonds(amount: int) -> bool:
	if diamonds() < amount:
		return false
	SaveManager.set_value("diamonds", diamonds() - amount)
	changed.emit()
	return true

# ------------------------------------------------------------- unlocks ---- #
func is_car_unlocked(id: int) -> bool:
	return id in (SaveManager.get_value("unlocked_cars", []) as Array)

func is_paint_unlocked(id: int) -> bool:
	return id in (SaveManager.get_value("unlocked_paints", []) as Array)

func is_wheel_unlocked(id: int) -> bool:
	return id in (SaveManager.get_value("unlocked_wheels", []) as Array)

func buy_car(id: int) -> bool:
	if is_car_unlocked(id):
		return true
	var c := GameData.car(id)
	if not spend_coins(int(c["price_coins"])):
		return false
	_unlock("unlocked_cars", id)
	return true

func buy_paint(id: int) -> bool:
	if is_paint_unlocked(id):
		return true
	var p := GameData.paint(id)
	var dc: int = int(p["price_diamonds"])
	var cc: int = int(p["price_coins"])
	if dc > 0:
		if not spend_diamonds(dc):
			return false
	else:
		if not spend_coins(cc):
			return false
	_unlock("unlocked_paints", id)
	return true

func buy_wheel(id: int) -> bool:
	if is_wheel_unlocked(id):
		return true
	var w := GameData.wheel(id)
	var dc: int = int(w["price_diamonds"])
	if dc > 0:
		if not spend_diamonds(dc):
			return false
	else:
		if not spend_coins(int(w["price_coins"])):
			return false
	_unlock("unlocked_wheels", id)
	return true

func _unlock(key: String, id: int) -> void:
	var arr: Array = SaveManager.get_value(key, [])
	if not (id in arr):
		arr.append(id)
	SaveManager.set_value(key, arr)
	changed.emit()

# ------------------------------------------------------------ selection ---- #
func select_car(id: int) -> void:
	if is_car_unlocked(id):
		SaveManager.set_value("selected_car", id)
		changed.emit()

func select_paint(id: int) -> void:
	if is_paint_unlocked(id):
		SaveManager.set_value("selected_paint", id)
		changed.emit()

func select_wheel(id: int) -> void:
	if is_wheel_unlocked(id):
		SaveManager.set_value("selected_wheel", id)
		changed.emit()

func selected_car() -> int:
	return int(SaveManager.get_value("selected_car", 0))

func selected_paint() -> int:
	return int(SaveManager.get_value("selected_paint", 0))

func selected_wheel() -> int:
	return int(SaveManager.get_value("selected_wheel", 0))

# ------------------------------------------------------------- upgrades ---- #
func upgrade_level(car_id: int) -> int:
	var up: Dictionary = SaveManager.get_value("upgrades", {})
	return int(up.get(str(car_id), 0))

func upgrade_cost(car_id: int) -> int:
	var lvl := upgrade_level(car_id)
	return 800 + lvl * 650

func buy_upgrade(car_id: int) -> bool:
	if upgrade_level(car_id) >= 5:
		return false
	if not spend_coins(upgrade_cost(car_id)):
		return false
	var up: Dictionary = SaveManager.get_value("upgrades", {})
	up[str(car_id)] = upgrade_level(car_id) + 1
	SaveManager.set_value("upgrades", up)
	changed.emit()
	return true
