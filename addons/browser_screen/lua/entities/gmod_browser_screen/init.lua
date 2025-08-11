-- Подключаем общие файлы
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Устанавливаем модель экрана (плоская панель)
    self:SetModel(self.Model)

    -- Настраиваем физику
    self:PhysicsInit(SOLID_VPHYSICS)    -- Физическое тело
    self:SetMoveType(MOVETYPE_VPHYSICS) -- Может двигаться под воздействием физики
    self:SetSolid(SOLID_VPHYSICS)       -- Твердое тело

    -- Активируем физику
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()  -- "Разбудить" физическое тело
    end

    -- Устанавливаем сетевые переменные (видны всем клиентам)
    self:SetNWString("URL", self.DefaultURL)        -- Текущий URL
    self:SetNWInt("ScreenWidth", self.ScreenWidth)  -- Ширина экрана
    self:SetNWInt("ScreenHeight", self.ScreenHeight) -- Высота экрана
    self:SetNWBool("IsPlaying", false)              -- Проигрывается ли видео

    print("[Browser Screen] Экран создан на сервере")
end

-- Вызывается когда игрок использует экран (клавиша E)
function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    -- Отправляем сигнал клиенту открыть панель управления
    net.Start("BrowserOpenPanel")
    net.WriteEntity(self)  -- Передаем ссылку на этот экран
    net.Send(activator)    -- Отправляем только использующему игроку

    print("[Browser Screen] Игрок " .. activator:GetName() .. " открыл браузер")
end

-- Обработка сетевых сообщений от клиентов
net.Receive("BrowserSetURL", function(len, ply)
    local screen = net.ReadEntity()  -- Получаем экран
    local url = net.ReadString()     -- Получаем новый URL

    -- Проверяем валидность
    if not IsValid(screen) or not IsValid(ply) then return end

    -- Check for YouTube URL and convert to embed format
    local videoID = string.match(url, "youtube.com/watch%?v=([%w%-_]+)") or string.match(url, "youtu.be/([%w%-_]+)")
    if videoID then
        url = "https://www.youtube.com/embed/" .. videoID .. "?autoplay=1&enablejsapi=1&iv_load_policy=3&controls=0"
    end

    -- Устанавливаем новый URL
    screen:SetNWString("URL", url)

    -- Синхронизируем со всеми клиентами
    net.Start("BrowserSync")
    net.WriteEntity(screen)
    net.WriteString(url)
    net.Broadcast()  -- Отправляем всем игрокам

    print("[Browser Screen] URL изменен на: " .. url)
end)
