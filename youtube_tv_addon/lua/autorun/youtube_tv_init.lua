-- YouTube TV аддон с GoodbyeDPI обходом
-- Автозагрузчик компонентов аддона

if SERVER then
    -- Загружаем клиентские файлы
    AddCSLuaFile("entities/youtube_tv_screen/cl_init.lua")
    AddCSLuaFile("entities/youtube_tv_screen/shared.lua")
    AddCSLuaFile("vgui/youtube_control_panel.lua")
    AddCSLuaFile("includes/goodbyedpi_bypass.lua")

    -- Подключаем GoodbyeDPI обход
    include("includes/goodbyedpi_bypass.lua")

    -- Регистрируем сетевые строки
    util.AddNetworkString("YouTubeTV_OpenPanel")
    util.AddNetworkString("YouTubeTV_SetURL")
    util.AddNetworkString("YouTubeTV_VolumeControl")
    util.AddNetworkString("YouTubeTV_PlayPause")
    util.AddNetworkString("YouTubeTV_Seek")
    util.AddNetworkString("YouTubeTV_Sync")

    print("[YouTube TV] Серверная часть загружена")
else
    -- Клиентская часть
    include("vgui/youtube_control_panel.lua")
    include("includes/goodbyedpi_bypass.lua")

    -- Инициализация GoodbyeDPI
    hook.Add("Initialize", "YouTubeTV_InitDPI", function()
        InitGoodbyeDPI()
    end)

    print("[YouTube TV] Клиентская часть загружена")
end

-- Комментарий для агента:
-- Этот файл автоматически загружается при старте игры
-- Регистрирует все необходимые компоненты аддона
-- Инициализирует GoodbyeDPI обход для YouTube
