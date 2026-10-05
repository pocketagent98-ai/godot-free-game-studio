extends Node
## Ads — one interface, three backends:
##   • Android/iOS : Google AdMob via the Poing Studios plugin (if installed)
##   • Web/HTML5   : a JS-bridge hook (web ads) with graceful no-op fallback
##   • Editor/desktop: an in-engine mock so the full flow is testable
##
## NO in-app purchases anywhere in this project. Rewarded ads are the only way
## a player can multiply coins or pre-load a booster.

signal rewarded_finished(kind: String, success: bool)
signal interstitial_closed()

const TEST_REWARDED_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const TEST_REWARDED_IOS := "ca-app-pub-3940256099942544/1712485313"
const TEST_INTERSTITIAL_ANDROID := "ca-app-pub-3940256099942544/1033173712"
const TEST_INTERSTITIAL_IOS := "ca-app-pub-3940256099942544/4411468910"

var _mock_active := false
var _mock_kind := ""
var _mock_timer := 0.0
var _levels_since_interstitial := 0
var _first_ad_delay_elapsed := false
var _session_seconds := 0.0

const INTERSTITIAL_EVERY_N_LEVELS := 3   # natural break: level-complete screen
const FIRST_AD_DELAY := 75.0             # seconds before the first interstitial
const MIN_INTERSTITIAL_GAP := 120.0      # seconds between interstitials
var _last_interstitial := -9999.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_session_seconds += delta
	if not _first_ad_delay_elapsed and _session_seconds >= FIRST_AD_DELAY:
		_first_ad_delay_elapsed = true
	if _mock_active:
		_mock_timer -= delta
		if _mock_timer <= 0.0:
			_finish_mock(true)

func is_mobile() -> bool:
	return OS.get_name() == "Android" or OS.get_name() == "iOS"

func _has_admob() -> bool:
	return ClassDB.class_exists("MobileAds") and is_mobile()

# ------------------------------------------------------------ rewarded ---- #
## kind: "booster" (pre-race) | "double_coins" (post-race) | "revive"
func show_rewarded(kind: String) -> void:
	Audio.play("ui")
	if _has_admob():
		_admob_rewarded(kind)
	elif OS.get_name() == "Web":
		_web_rewarded(kind)
	else:
		_mock_rewarded(kind)

func _admob_rewarded(kind: String) -> void:
	# Real AdMob path. Guarded so the project still runs without the plugin.
	if not ClassDB.class_exists("RewardedAdLoader"):
		_mock_rewarded(kind)
		return
	var unit_id := TEST_REWARDED_ANDROID if OS.get_name() == "Android" else TEST_REWARDED_IOS
	var loader = ClassDB.instantiate("RewardedAdLoader")
	var cb = ClassDB.instantiate("RewardedAdLoadCallback")
	cb.on_ad_loaded = func(ad) -> void:
		ad.show()
		rewarded_finished.emit(kind, true)
	cb.on_ad_failed_to_load = func(err) -> void:
		push_warning("Rewarded load failed: %s" % str(err))
		rewarded_finished.emit(kind, false)
	loader.load(unit_id, ClassDB.instantiate("AdRequest"), cb)

func _web_rewarded(kind: String) -> void:
	# Web ads are optional; if no bridge is present we fall back to the mock so
	# the WebGL build stays fully playable.
	if JavaScriptBridge.has_method("get_interface") and JavaScriptBridge.get_interface("TurboRushAds") != null:
		var bridge = JavaScriptBridge.get_interface("TurboRushAds")
		JavaScriptBridge.create_callback(func(_ok): rewarded_finished.emit(kind, true))
		bridge.showRewarded(kind)
	else:
		_mock_rewarded(kind)

func _mock_rewarded(kind: String) -> void:
	_mock_active = true
	_mock_kind = kind
	_mock_timer = 1.2

func _finish_mock(success: bool) -> void:
	_mock_active = false
	rewarded_finished.emit(_mock_kind, success)

# -------------------------------------------------------- interstitial ---- #
func maybe_show_interstitial() -> void:
	_levels_since_interstitial += 1
	if not _first_ad_delay_elapsed:
		return
	if _levels_since_interstitial < INTERSTITIAL_EVERY_N_LEVELS:
		return
	if _session_seconds - _last_interstitial < MIN_INTERSTITIAL_GAP:
		return
	_levels_since_interstitial = 0
	_last_interstitial = _session_seconds
	show_interstitial()

func show_interstitial() -> void:
	if _has_admob() and ClassDB.class_exists("InterstitialAdLoader"):
		var unit_id := TEST_INTERSTITIAL_ANDROID if OS.get_name() == "Android" else TEST_INTERSTITIAL_IOS
		var loader = ClassDB.instantiate("InterstitialAdLoader")
		var cb = ClassDB.instantiate("InterstitialAdLoadCallback")
		cb.on_ad_loaded = func(ad) -> void:
			ad.show()
			interstitial_closed.emit()
		cb.on_ad_failed_to_load = func(_e) -> void:
			interstitial_closed.emit()
		loader.load(unit_id, ClassDB.instantiate("AdRequest"), cb)
	else:
		# mock / web: emit immediately
		interstitial_closed.emit()

# -------------------------------------------------------------- banner ---- #
func show_banner() -> void:
	# Banners only ever appear on menus, never during active gameplay.
	if _has_admob() and ClassDB.class_exists("AdView"):
		pass  # banner creation handled by the AdMob addon's own scene

func hide_banner() -> void:
	pass
