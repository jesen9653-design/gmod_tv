-- Этот файл загружается автоматически при старте сервера/клиента
if SERVER then
    -- Добавляем клиентские файлы для загрузки
    -- Base class files
    AddCSLuaFile("entities/gmod_browser_screen/cl_init.lua")
    AddCSLuaFile("entities/gmod_browser_screen/shared.lua")

    -- Child class files
    AddCSLuaFile("entities/gmod_browser_screen_small/cl_init.lua")
    AddCSLuaFile("entities/gmod_browser_screen_small/shared.lua")
    AddCSLuaFile("entities/gmod_browser_screen_medium/cl_init.lua")
    AddCSLuaFile("entities/gmod_browser_screen_medium/shared.lua")
    AddCSLuaFile("entities/gmod_browser_screen_large/cl_init.lua")
    AddCSLuaFile("entities/gmod_browser_screen_large/shared.lua")

    -- VGUI
    AddCSLuaFile("vgui/browser_frame.lua")

    -- Регистрируем сетевые строки для передачи данных между сервером и клиентом
    util.AddNetworkString("BrowserOpenPanel")    -- Открыть панель браузера
    util.AddNetworkString("BrowserSetURL")       -- Установить URL
    util.AddNetworkString("BrowserSync")         -- Синхронизация между игроками

    print("[Browser Screen] Серверная часть загружена")
else
    -- Клиентская часть
    include("vgui/browser_frame.lua")
    print("[Browser Screen] Клиентская часть загружена")
end
