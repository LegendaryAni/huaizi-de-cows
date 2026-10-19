extends RefCounted

const Config = preload("res://scripts/scifi/ScifiConfig.gd")
var root = ""
var path = ""
var journal_path = ""
var data:Dictionary = {}
var pending:Dictionary = {}
var error = ""
var protected = false
var fault = ""
var events:Array = []

func _init(directory:String = "") -> void:
	root = directory if not directory.is_empty() else ProjectSettings.globalize_path("user://")
	path = root.path_join("scifi_progress.json")
	journal_path = root.path_join("scifi_pending.json")
	data = defaults()
	load_progress()

func defaults() -> Dictionary:
	return {"version":1,"credits":0,"upgrades":{"hp":0,"damage":0,"weapon_cd":0,"skill_cd":0},"loadout":{"weapon":"rail","skills":["dash","repair"]},"settled_ids":[],"runs":[]}

func _integer(value:Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= 9007199254740991 and floor(value) == value

func valid(value:Variant) -> bool:
	if not value is Dictionary or value.get("version",0) != 1:
		return false
	if not _integer(value.get("credits")) or not value.get("upgrades") is Dictionary or not value.get("settled_ids") is Array or not value.get("runs") is Array or not Config.valid_loadout(value.get("loadout")):
		return false
	for id in value.settled_ids:
		if not id is String or id.is_empty(): return false
	for key in ["hp","damage","weapon_cd","skill_cd"]:
		var n = value.upgrades.get(key)
		if not _integer(n) or n > 5: return false
	for run in value.runs:
		if not run is Dictionary or not run.get("run_id") is String or not _integer(run.get("credits")): return false
	return true

func valid_journal(value:Variant) -> bool:
	return value is Dictionary and value.get("version",0) == 1 and value.get("run_id") is String and not value.run_id.is_empty() and value.get("reward") is Dictionary and _integer(value.reward.get("credits"))

func read_json(file_path:String) -> Variant:
	var file = FileAccess.open(file_path,FileAccess.READ)
	if file == null:
		return null
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return parser.data

func load_progress() -> void:
	if FileAccess.file_exists(path):
		var value = read_json(path)
		if valid(value):
			data = value
		else:
			protected = true
			error = "成長存檔格式錯誤或版本不相容，原檔已保護。"
			var backup = read_json(path + ".bak")
			if valid(backup) and not (value is Dictionary and int(value.get("version",0)) > 1):
				data = backup
				error += " 已唯讀載入有效備份。"
	if FileAccess.file_exists(journal_path):
		var value = read_json(journal_path)
		if valid_journal(value):
			pending = value
		else:
			protected = true
			error = "待結算記錄損壞，原檔已保護。"

func _write(file_path:String, value:Dictionary) -> bool:
	var file = FileAccess.open(file_path,FileAccess.WRITE)
	if file == null:
		error = "無法寫入存檔：" + str(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(value,"\t"))
	file.flush()
	var ok = file.get_error() == OK
	file.close()
	if not ok:
		error = "存檔寫入未完成。"
	return ok

func commit(next:Dictionary) -> bool:
	if protected:
		return false
	if not valid(next):
		error = "拒絕無效存檔交易。"
		return false
	DirAccess.make_dir_recursive_absolute(root)
	if fault == "temp_write":
		error = "測試故障：暫存寫入失敗"
		return false
	if not _write(path + ".tmp",next):
		return false
	if fault == "before_replace" or fault == "replace":
		error = "測試故障：原子替換前失敗"
		return false
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path,path + ".bak") != OK:
			error = "備份失敗，交易未提交。"
			return false
	if DirAccess.rename_absolute(path + ".tmp",path) != OK:
		error = "原子替換失敗，請重試。"
		return false
	if fault == "after_commit":
		error = "測試故障：已落盤但回應中斷"
		return false
	data = next
	error = ""
	return true

func save_loadout(loadout:Dictionary) -> bool:
	var next = data.duplicate(true)
	next.loadout = loadout.duplicate(true)
	return commit(next)

func settle(run_id:String,reward:Dictionary) -> bool:
	if run_id.is_empty() or not _integer(reward.get("credits")):
		error = "拒絕無效結算記錄。"
		return false
	if data.settled_ids.has(run_id):
		return true
	if not pending.is_empty() and pending.run_id != run_id:
		error = "上一局尚待儲存，請先重試。"
		return false
	pending = {"version":1,"run_id":run_id,"reward":reward.duplicate(true)}
	return retry()

func retry() -> bool:
	if pending.is_empty():
		return error.is_empty()
	if protected:
		return false
	# Re-read committed disk data after a lost acknowledgement before applying reward.
	var disk = read_json(path)
	if valid(disk):
		data = disk
	if data.settled_ids.has(pending.run_id):
		pending.clear()
		DirAccess.remove_absolute(journal_path)
		error = ""
		return true
	DirAccess.make_dir_recursive_absolute(root)
	if fault == "journal_write":
		error = "無法儲存待結算記錄；請保留視窗並重試。"
		return false
	if not _write(journal_path + ".tmp",pending):
		return false
	if DirAccess.rename_absolute(journal_path + ".tmp",journal_path) != OK:
		error = "待結算記錄提交失敗，請保留視窗並重試。"
		return false
	var next = data.duplicate(true)
	next.credits = int(next.credits) + int(pending.reward.credits)
	next.settled_ids.append(pending.run_id)
	next.runs.append(pending.reward.merged({"run_id":pending.run_id}))
	if not commit(next):
		return false
	pending.clear()
	DirAccess.remove_absolute(journal_path)
	return true

func purchase(key:String) -> bool:
	if not pending.is_empty() or not data.upgrades.has(key):
		return false
	var level = int(data.upgrades[key])
	if level >= 5 or int(data.credits) < Config.ECONOMY.prices[level]:
		return false
	var next = data.duplicate(true)
	next.credits -= Config.ECONOMY.prices[level]
	next.upgrades[key] = level + 1
	return commit(next)

func snapshot() -> Dictionary:
	return data.merged({"save_error":error,"protected":protected,"pending":pending.duplicate(true),"path":path,"journal_path":journal_path},true)
