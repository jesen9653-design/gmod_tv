-- Базовая конфигурация YouTube TV экрана

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "YouTube TV Экран"
ENT.Author = "YouTube TV Team"
ENT.Category = "Развлечения"
ENT.Spawnable = true
ENT.AdminOnly = false

-- Типы экранов и их размеры
ENT.ScreenSizes = {
    ["small"] = {
        width = 512,
        height = 288,
        scale = 0.05,
        model = "models/hunter/plates/plate1x1.mdl",
        name = "Маленький экран"
    },
    ["medium"] = {
        width = 1024,
        height = 576,
        scale = 0.08,
        model = "models/hunter/plates/plate2x2.mdl",
        name = "Средний экран"
    },
    ["large"] = {
        width = 1920,
        height = 1080,
        scale = 0.12,
        model = "models/hunter/plates/plate4x4.mdl",
        name = "Большой экран"
    },
    ["custom"] = {
        width = 1600,
        height = 900,
        scale = 0.1,
        model = "models/hunter/plates/plate3x3.mdl",
        name = "Кастомный экран"
    }
}

-- Настройки по умолчанию
ENT.DefaultSize = "medium"
ENT.DefaultURL = "https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1"
ENT.MaxVolume = 100
ENT.DefaultVolume = 50

-- Комментарий для агента:
-- Определяет 4 типа экранов с разными размерами
-- Каждый размер имеет свою модель и масштаб
-- Можно легко добавить новые размеры
