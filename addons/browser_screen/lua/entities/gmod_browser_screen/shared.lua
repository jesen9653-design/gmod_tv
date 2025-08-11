-- Базовая информация об энтити (видна и серверу, и клиенту)
ENT.Type = "anim"                    -- Тип: анимированная модель
ENT.Base = "base_gmodentity"         -- Наследуемся от базового энтити
ENT.PrintName = "Base Browser Screen (Not Spawnable)"
ENT.Author = "Jules"
ENT.Category = "Развлечения"
ENT.Spawnable = false                -- This is a base class, don't spawn it directly
ENT.AdminOnly = false                -- Доступно всем игрокам

-- Default model for medium screen and base for others
ENT.Model = "models/hunter/plates/plate2x2.mdl"

-- Настройки экрана
ENT.ScreenWidth = 1024               -- Ширина экрана в пикселях
ENT.ScreenHeight = 768               -- Высота экрана в пикселях
ENT.DefaultURL = "https://www.google.com"  -- URL по умолчанию
