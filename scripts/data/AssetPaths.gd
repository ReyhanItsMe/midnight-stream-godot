## Registry path string terpusat untuk semua aset proyek.
##
## Cara pakai:
##   var font = load(AssetPaths.Fonts.PIXEL_DEFAULT)
##   var bg = load(AssetPaths.Sprites.BG_MENU)
##   AudioManager.play_sfx(AssetPaths.Audios.SFX_CLICK)
##   AnimationUtils.build_character_animations(AssetPaths.Sprites.CHAR_RIAN_DIR)
class_name AssetPaths
extends RefCounted

# ==============================================================================
# 1. FONTS (Diubah jadi Fonts agar tidak konflik dengan native class Font)
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
	# BGM
	const BGM_FEAR: String              = "res://assets/audio/bgm/bgm-fear.mp3"
	
	# SFX
	const SFX_CLICK: String             = "res://assets/audio/sfx/clicks/sfx-click-button.mp3"
	const SFX_FOOTSTEP_DIRT: String     = "res://assets/audio/sfx/footsteps/sfx-footsteps-dirt.wav"

# ==============================================================================
# 3. SPRITES
# ==============================================================================
class Sprites:
	# Folder Karakter
	const CHAR_RIAN_DIR: String         = "res://assets/sprites/characters/rian"
	const CHAR_MISTERY_DIR: String       = "res://assets/sprites/characters/mistery"

	# Tekstur Tunggal
	const LIGHT_CONE: String            = "res://assets/sprites/lights/cone_composed_c.png"
	const APP_ICON: String              = "res://assets/sprites/ui/icons/app-icon.png"
	const TITLE_LOGO: String            = "res://assets/sprites/ui/titles/title-games.png"
	const BG_MENU: String               = "res://assets/sprites/ui/backgrounds/menu/background-menu.png"
	const BG_LOAD_GAME: String          = "res://assets/sprites/ui/backgrounds/load-game/background-load-game.png"
	const BG_SETTINGS: String           = "res://assets/sprites/ui/backgrounds/setting/background-setting.png"

# ==============================================================================
# 4. PATTERNS & PROPS
# ==============================================================================
class PropPatterns:
	const KEY6_CURSE: String            = "res://assets/sprites/props/key/key-6/CURSE/Key8-CURSE-frame%04d.png"
	const KEY6_CURSE_COUNT: int         = 27

	const KEY2_GOLD: String             = "res://assets/sprites/props/key/key-2/GOLD/Key2-GOLD-%04d.png"
	const KEY2_GOLD_COUNT: int          = 12
