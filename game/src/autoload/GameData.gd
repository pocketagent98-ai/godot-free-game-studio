extends Node
## GameData — deterministic, data-driven content generator.
## Produces 120 cars, 120 paints, 72 wheels and 1000+ levels from seeds,
## so the game ships no giant hand-written data files.

const CAR_COUNT := 120
const PAINT_COUNT := 120
const WHEEL_COUNT := 72
const LEVEL_COUNT := 1000

## Position rewards for a 6-car race (index 0 = 1st place).
const POSITION_COINS := [250, 200, 150, 100, 70, 50]
## Diamonds are deliberately scarce.
const POSITION_DIAMONDS := [3, 2, 1, 0, 0, 0]

var cars: Array[Dictionary] = []
var paints: Array[Dictionary] = []
var wheels: Array[Dictionary] = []
var levels: Array[Dictionary] = []

const BRANDS := ["Vortex", "Nitro", "Apex", "Bolt", "Cyclone", "Falcon", "Havoc", "Inferno",
	"Jaguar", "Kestrel", "Lynx", "Mamba", "Onyx", "Phantom", "Quasar", "Raptor",
	"Sabre", "Titan", "Viper", "Wraith"]
const MODELS := ["GT", "RS", "XR", "Turbo", "S-Type", "V12", "Evo", "Max", "Prime", "Elite",
	"Sport", "Race", "Storm", "Blaze", "Aero", "Drift", "Nova", "Zenith"]
const RARITY := ["Common", "Rare", "Epic", "Legendary"]

const PAINT_FINISH := ["Gloss", "Metallic", "Matte", "Pearl", "Chrome", "Neon"]

const WHEEL_STYLES := ["Five-Spoke", "Split-Spoke", "Mesh", "Deep-Dish", "Multi-Spoke", "Star",
	"Turbine", "Blade", "Y-Spoke", "Concave", "Forged", "Retro"]

const THEMES := ["City", "Suburban", "Industrial", "Highway", "Circuit", "Downtown"]

func _ready() -> void:
	_generate_cars()
	_generate_paints()
	_generate_wheels()
	_generate_levels()

# ---------------------------------------------------------------- cars ---- #
func _generate_cars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261002
	for i in CAR_COUNT:
		var tier: int = clampi(i / 24, 0, 4)          # 5 performance tiers
		var rarity: int = clampi(i / 30, 0, 3)
		var brand: String = BRANDS[i % BRANDS.size()]
		var model: String = MODELS[(i * 7 + 3) % MODELS.size()]
		var top_speed: float = 150.0 + tier * 28.0 + rng.randf_range(-6.0, 10.0)
		var accel: float = 18.0 + tier * 3.4 + rng.randf_range(-1.5, 2.0)
		var handling: float = 0.62 + tier * 0.06 + rng.randf_range(-0.03, 0.04)
		var grip: float = 0.70 + tier * 0.05 + rng.randf_range(-0.03, 0.03)
		var weight: float = 1100.0 + rng.randf_range(-120.0, 260.0)
		var price: int = int(1200 + pow(float(i), 1.7) * 9.0)
		cars.append({
			"id": i,
			"name": "%s %s" % [brand, model],
			"brand": brand,
			"tier": tier,
			"rarity": RARITY[rarity],
			"top_speed": top_speed,
			"acceleration": accel,
			"handling": handling,
			"grip": grip,
			"braking": 26.0 + tier * 2.0,
			"boost_power": 1.25 + tier * 0.12,
			"weight": weight,
			"steering": 0.90 + tier * 0.05,
			"suspension": 0.55 + rng.randf_range(-0.05, 0.08),
			"price_coins": price,
			"unlock_level": i * 3,
			"starter": i == 0,
		})

# --------------------------------------------------------------- paints ---- #
func _generate_paints() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777001
	for i in PAINT_COUNT:
		var finish: String = PAINT_FINISH[i % PAINT_FINISH.size()]
		var col := Color.from_hsv(fposmod(float(i) / float(PAINT_COUNT) * 1.618, 1.0),
			0.35 + 0.55 * float(i % 3) / 2.0,
			0.30 + 0.65 * float((i / 3) % 3) / 2.0)
		var premium: bool = finish in ["Pearl", "Chrome", "Neon"]
		paints.append({
			"id": i,
			"name": "%s %s" % [finish, "%02d" % (i + 1)],
			"finish": finish,
			"color": col,
			"metallic": 0.9 if finish == "Metallic" else (1.0 if finish == "Chrome" else 0.2),
			"roughness": 0.85 if finish == "Matte" else (0.12 if finish in ["Chrome", "Pearl"] else 0.42),
			"price_coins": int(0 if i < 8 else 400 + pow(float(i), 1.4) * 12.0),
			"price_diamonds": 0 if not premium else int(2 + (i % 5)),
			"starter": i < 8,
		})

# --------------------------------------------------------------- wheels ---- #
func _generate_wheels() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in WHEEL_COUNT:
		var style: String = WHEEL_STYLES[i % WHEEL_STYLES.size()]
		var rim := Color.from_hsv(fposmod(float(i) / float(WHEEL_COUNT) * 2.4, 1.0), 0.08, 0.75)
		wheels.append({
			"id": i,
			"name": "%s %d\"" % [style, 15 + (i % 4)],
			"style": style,
			"rim_color": rim,
			"spokes": 5 + (i % 6),
			"size": 0.34 + 0.02 * float(i % 4),
			"price_coins": int(0 if i < 6 else 300 + pow(float(i), 1.3) * 10.0),
			"price_diamonds": 0 if i % 6 != 0 else int(1 + (i % 4)),
			"starter": i < 6,
		})

# --------------------------------------------------------------- levels ---- #
func _generate_levels() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 990011
	for i in LEVEL_COUNT:
		var tier: int = clampi(i / 200, 0, 4)
		levels.append({
			"id": i,
			"number": i + 1,
			"theme": THEMES[(i * 3 + 1) % THEMES.size()],
			"seed": 100000 + i * 131,
			"laps": 2 if i < 400 else 3,
			"ai_count": 5,                              # player + 5 = 6 racers
			"ai_skill": clampf(0.35 + float(tier) * 0.14 + rng.randf_range(-0.04, 0.06), 0.2, 0.98),
			"curviness": clampf(0.35 + float(i % 250) / 250.0 * 0.55, 0.3, 0.95),
			"length_segments": 26 + (i % 7) * 4,
			"tier": tier,
			"base_coins": 120 + i * 3,
			"diamond_chance": 0.10 if i % 10 == 0 else 0.0,
		})

# ------------------------------------------------------------- helpers ---- #
func car(id: int) -> Dictionary:
	return cars[clampi(id, 0, cars.size() - 1)]

func paint(id: int) -> Dictionary:
	return paints[clampi(id, 0, paints.size() - 1)]

func wheel(id: int) -> Dictionary:
	return wheels[clampi(id, 0, wheels.size() - 1)]

func level(id: int) -> Dictionary:
	return levels[clampi(id, 0, levels.size() - 1)]

func coins_for_position(pos: int) -> int:
	if pos >= 0 and pos < POSITION_COINS.size():
		return POSITION_COINS[pos]
	return 25

func diamonds_for_position(pos: int) -> int:
	if pos >= 0 and pos < POSITION_DIAMONDS.size():
		return POSITION_DIAMONDS[pos]
	return 0
