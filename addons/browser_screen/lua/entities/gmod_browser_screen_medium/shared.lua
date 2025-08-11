-- Inherit from the base browser screen
ENT.Base = "gmod_browser_screen"

-- Override properties for the medium screen
ENT.PrintName = "Средний Браузер Экран"
ENT.Category = "Развлечения"
ENT.Spawnable = true
ENT.AdminOnly = false

-- We can omit ScreenWidth, ScreenHeight, and Model since we want to use the defaults from the base class.
-- The base class already has:
-- ENT.Model = "models/hunter/plates/plate2x2.mdl"
-- ENT.ScreenWidth = 1024
-- ENT.ScreenHeight = 768
