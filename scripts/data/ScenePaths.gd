## Registry path terpusat khusus file scene (*.tscn).
class_name ScenePaths
extends RefCounted

# ==============================================================================
# 1. UI SCREENS
# ==============================================================================
class Screens:
	const INTRO: String            = "res://scenes/ui/screens/intro/Intro.tscn"
	const MAIN_MENU: String        = "res://scenes/ui/screens/main_menu/MainMenu.tscn"
	const LOAD_GAME: String        = "res://scenes/ui/screens/load_game/LoadGame.tscn"
	const SETTINGS: String         = "res://scenes/ui/screens/settings/Settings.tscn"
	const LOADING_SCREEN: String   = "res://scenes/ui/screens/LoadingScreen.tscn"

# ==============================================================================
# 2. UI COMPONENTS & MODALS
# ==============================================================================
class UIComponents:
	const MENU_BUTTON: String      = "res://scenes/components/interface/buttons/GameMenuButton.tscn"
	const INFO_MODAL: String       = "res://scenes/components/interface/modals/InfoModal.tscn"
	const DIALOGUE_BOX: String     = "res://scenes/components/interface/dialogue/DialogueBox.tscn"

# ==============================================================================
# 3. GAMEPLAY MAPS & LEVELS
# ==============================================================================
class Maps:
	const PROLOGUE: String         = "res://scenes/gameplay/prologue/Prologue.tscn"

# ==============================================================================
# 4. ENTITIES & PREFABS
# ==============================================================================
class Entities:
	const DOOR: String             = "res://scenes/entities/interactables/Door.tscn"
