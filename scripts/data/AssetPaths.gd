## Registry path string terpusat untuk semua aset proyek.
class_name AssetPaths
extends RefCounted

# ==============================================================================
# 1. FONTS
# ==============================================================================
class Fonts:
	const GEIST_PIXEL: String           = "res://assets/fonts/Geist-Pixel.ttf"
	const HANDJET_REGULAR: String       = "res://assets/fonts/Handjet-Regular.ttf"
	const HANDJET_BOLD: String          = "res://assets/fonts/Handjet-Bold.ttf"
	const PIX32: String                 = "res://assets/fonts/Pix32.ttf"
	const PIXELIFY_REGULAR: String      = "res://assets/fonts/PixelifySans-Regular.ttf"
	const PIXELIFY_BOLD: String         = "res://assets/fonts/PixelifySans-Bold.ttf"
	const PIXELTA: String               = "res://assets/fonts/Pixelta.ttf"
	const PIXEL_DEFAULT: String         = "res://assets/fonts/pixel.ttf"

# ==============================================================================
# 2. AUDIO
# ==============================================================================
class Audios:
	const BGM_FEAR: String              = "res://assets/audio/bgm/bgm-fear.mp3"
	const SFX_CLICK: String             = "res://assets/audio/sfx/clicks/sfx-click-button.mp3"
	const SFX_FOOTSTEP: String          = "res://assets/audio/sfx/footsteps/sfx-footsteps-dirt.wav"
	const SFX_FOOTSTEP_DIRT: String     = "res://assets/audio/sfx/footsteps/sfx-footsteps-dirt.wav"

# ==============================================================================
# 3. SPRITES
# ==============================================================================
class Sprites:
	# Karakter
	const CHAR_RIAN: String             = "res://assets/sprites/characters/rian/"
	const CHAR_RIAN_DIR: String         = "res://assets/sprites/characters/rian/"
	const CHAR_MISTERY_DIR: String      = "res://assets/sprites/characters/mistery/"
	const CHAR_MISTERY_SPRITE: String   = "res://assets/sprites/characters/mistery/misterius_sprite.png"
	
	# Ekspresi Portrait Dialog
	const RIAN_EXPR_DIR: String         = "res://assets/sprites/characters/rian/expressions/"
	const MISTERY_EXPR_DIR: String      = "res://assets/sprites/characters/mistery/expressions/"

	# Props & Efek Cahaya
	const PROPS_SENTER_DIR: String      = "res://assets/sprites/props/senter/"
	const PROPS_SENTER: String          = "res://assets/sprites/props/senter/"
	const ITEM_SENTER: String           = "res://assets/sprites/props/senter/senter_item.png"
	const LIGHT_CONE: String            = "res://assets/sprites/lights/cone_composed_c.png"

	# Pintu Horror
	const DOORS_HORROR_DIR: String      = "res://assets/sprites/interactables/pintu_horror/"

	# Item & Keys Icons
	const KEY_BRONZE: String            = "res://assets/sprites/props/key/key-1/Key1-BRONZE.png"
	const KEY_GOLD: String              = "res://assets/sprites/props/key/key-1/Key1-GOLD.png"
	const KEY_CURSE: String             = "res://assets/sprites/props/key/key-6/CURSE/Key8-CURSE-frame0000.png"
	const KEY_GREY: String              = "res://assets/sprites/props/key/key-3/Key3-GREY.png"

# ==============================================================================
# 4. USER INTERFACE
# ==============================================================================
class UI:
	const APP_ICON: String              = "res://assets/ui/icons/app-icon.png"
	const TITLE_LOGO: String            = "res://assets/ui/titles/title-games.png"
	const INTRO_CREDITS: String         = "res://assets/ui/intro/intro-credits.png"
	const BG_MENU: String               = "res://assets/ui/backgrounds/menu/background-menu.png"
	const BG_LOAD_GAME: String          = "res://assets/ui/backgrounds/load-game/background-load-game.png"
	const BG_SETTINGS: String           = "res://assets/ui/backgrounds/setting/background-setting.png"

# ==============================================================================
# 5. PATTERNS
# ==============================================================================
class PropPatterns:
	const KEY6_CURSE: String            = "res://assets/sprites/props/key/key-6/CURSE/Key8-CURSE-frame%04d.png"
	const KEY6_CURSE_COUNT: int         = 27
	const KEY2_GOLD: String             = "res://assets/sprites/props/key/key-2/GOLD/Key2-GOLD-%04d.png"
	const KEY2_GOLD_COUNT: int          = 12
