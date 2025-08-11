-- Серверная часть YouTube TV экрана

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Устанавливаем размер экрана по умолчанию
    local size = self.ScreenSizes[self.DefaultSize]
    self:SetModel(size.model)

    -- Настройка физики
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(50) -- Делаем экран легче для удобства
    end

    -- Сетевые переменные для синхронизации
    self:SetNWString("YouTubeURL", self.DefaultURL)
    self:SetNWString("ScreenSize", self.DefaultSize)
    self:SetNWInt("Volume", self.DefaultVolume)
    self:SetNWBool("IsPlaying", true)
    self:SetNWFloat("CurrentTime", 0)
    self:SetNWBool("IsMuted", false)

    -- Настройки экрана
    self:SetNWInt("ScreenWidth", size.width)
    self:SetNWInt("ScreenHeight", size.height)
    self:SetNWFloat("ScreenScale", size.scale)

    print("[YouTube TV] Экран создан: " .. size.name)
end

-- Взаимодействие с игроком (клавиша E)
function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    -- Отправляем сигнал открыть панель управления
    net.Start("YouTubeTV_OpenPanel")
    net.WriteEntity(self)
    net.Send(activator)

    print("[YouTube TV] " .. activator:GetName() .. " открыл панель управления")
end

-- Изменение размера экрана
function ENT:SetScreenSize(sizeName)
    if not self.ScreenSizes[sizeName] then return false end

    local size = self.ScreenSizes[sizeName]
    self:SetModel(size.model)
    self:SetNWString("ScreenSize", sizeName)
    self:SetNWInt("ScreenWidth", size.width)
    self:SetNWInt("ScreenHeight", size.height)
    self:SetNWFloat("ScreenScale", size.scale)

    -- Обновляем физику
    self:PhysicsInit(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    return true
end

-- Обработка сетевых сообщений
net.Receive("YouTubeTV_SetURL", function(len, ply)
    local screen = net.ReadEntity()
    local url = net.ReadString()

    if not IsValid(screen) or not IsValid(ply) then return end

    -- Валидация YouTube URL
    if not screen:ValidateYouTubeURL(url) then
        ply:ChatPrint("[YouTube TV] Недопустимый URL!")
        return
    end

    screen:SetNWString("YouTubeURL", url)

    -- Синхронизация с клиентами
    net.Start("YouTubeTV_Sync")
    net.WriteEntity(screen)
    net.WriteString("url")
    net.WriteString(url)
    net.Broadcast()

    print("[YouTube TV] URL изменен: " .. url)
end)

net.Receive("YouTubeTV_VolumeControl", function(len, ply)
    local screen = net.ReadEntity()
    local volume = net.ReadInt(8)

    if not IsValid(screen) or not IsValid(ply) then return end

    volume = math.Clamp(volume, 0, screen.MaxVolume)
    screen:SetNWInt("Volume", volume)

    net.Start("YouTubeTV_Sync")
    net.WriteEntity(screen)
    net.WriteString("volume")
    net.WriteInt(volume, 8)
    net.Broadcast()
end)

-- Валидация YouTube URL
function ENT:ValidateYouTubeURL(url)
    local allowedDomains = {
        "youtube%.com",
        "youtu%.be",
        "m%.youtube%.com"
    }

    for _, domain in ipairs(allowedDomains) do
        if string.find(url, domain) then
            return true
        end
    end

    return false
end

-- Комментарий для агента:
-- Управляет экраном на сервере
-- Обрабатывает команды игроков
-- Синхронизирует состояние между всеми клиентами
-- Включает валидацию безопасности для URL
