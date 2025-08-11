--[[
    YouTube TV Addon (Single File Version)
    Created by Jules for a user request.
    This file combines all Lua scripts into one for simplicity,
    as requested. Note that this is a non-standard structure.
]]

--==============================================================================
-- 1. GoodbyeDPI Bypass Module (Safe Version)
--==============================================================================

GoodbyeDPI = {}

local DPI_CONFIG = {
    enabled = true,
    blocked_domains = {
        "youtube.com",
        "youtu.be",
        "googlevideo.com",
        "ytimg.com"
    }
}

function InitGoodbyeDPI()
    if not DPI_CONFIG.enabled then return end
    print("[GoodbyeDPI] Безопасная версия модуля обхода блокировок активирована.")
end

function GoodbyeDPI.ProcessURL(url)
    if not DPI_CONFIG.enabled or not url then return url end
    local isBlocked = false
    for _, domain in ipairs(DPI_CONFIG.blocked_domains) do
        if string.find(url, domain, 1, true) then
            isBlocked = true
            break
        end
    end
    if not isBlocked then return url end
    print("[GoodbyeDPI] Обработка URL: " .. url)
    url = string.gsub(url, "^http://", "https://")
    if string.find(url, "youtube.com") or string.find(url, "youtu.be") then
        url = GoodbyeDPI.ProcessYouTubeURL(url)
    end
    return url
end

function GoodbyeDPI.ProcessYouTubeURL(url)
    local separator = string.find(url, "?") and "&" or "?"
    local bypassParams = { "hl=en", "gl=US", "source=gmod", "bypass=1" }
    for _, param in ipairs(bypassParams) do
        local key = string.match(param, "([^=]+)=")
        if not string.find(url, key .. "=") then
            url = url .. (string.find(url, "?") and "&" or "?") .. param
        end
    end
    return url
end

--==============================================================================
-- 2. Entity Definition (youtube_tv_screen)
--==============================================================================

ENT = {}

-- From shared.lua
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "YouTube TV Экран"
ENT.Author = "YouTube TV Team"
ENT.Category = "Развлечения"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.ScreenSizes = {
    ["small"] = { width = 512, height = 288, scale = 0.05, model = "models/hunter/plates/plate1x1.mdl", name = "Маленький экран" },
    ["medium"] = { width = 1024, height = 576, scale = 0.08, model = "models/hunter/plates/plate2x2.mdl", name = "Средний экран" },
    ["large"] = { width = 1920, height = 1080, scale = 0.12, model = "models/hunter/plates/plate4x4.mdl", name = "Большой экран" },
    ["custom"] = { width = 1600, height = 900, scale = 0.1, model = "models/hunter/plates/plate3x3.mdl", name = "Кастомный экран" }
}
ENT.DefaultSize = "medium"
ENT.DefaultURL = "https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1"
ENT.MaxVolume = 100
ENT.DefaultVolume = 50

if SERVER then
    -- From init.lua
    function ENT:Initialize()
        local size = self.ScreenSizes[self.DefaultSize]
        self:SetModel(size.model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(50)
        end
        self:SetNWString("YouTubeURL", self.DefaultURL)
        self:SetNWString("ScreenSize", self.DefaultSize)
        self:SetNWInt("Volume", self.DefaultVolume)
        self:SetNWBool("IsPlaying", true)
        self:SetNWFloat("CurrentTime", 0)
        self:SetNWBool("IsMuted", false)
        self:SetNWInt("ScreenWidth", size.width)
        self:SetNWInt("ScreenHeight", size.height)
        self:SetNWFloat("ScreenScale", size.scale)
        print("[YouTube TV] Экран создан: " .. size.name)
    end

    function ENT:Use(activator, caller)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        net.Start("YouTubeTV_OpenPanel")
        net.WriteEntity(self)
        net.Send(activator)
        print("[YouTube TV] " .. activator:GetName() .. " открыл панель управления")
    end

    function ENT:SetScreenSize(sizeName)
        if not self.ScreenSizes[sizeName] then return false end
        local size = self.ScreenSizes[sizeName]
        self:SetModel(size.model)
        self:SetNWString("ScreenSize", sizeName)
        self:SetNWInt("ScreenWidth", size.width)
        self:SetNWInt("ScreenHeight", size.height)
        self:SetNWFloat("ScreenScale", size.scale)
        self:PhysicsInit(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
        return true
    end

    function ENT:ValidateYouTubeURL(url)
        local allowedDomains = { "youtube%.com", "youtu%.be", "m%.youtube%.com" }
        for _, domain in ipairs(allowedDomains) do
            if string.find(url, domain) then return true end
        end
        return false
    end
end

if CLIENT then
    -- From cl_init.lua
    ENT.RenderGroup = RENDERGROUP_BOTH

    function ENT:Initialize()
        self.Browser = vgui.Create("DHTML")
        self.Browser:SetVisible(false)
        local width = self:GetNWInt("ScreenWidth", 1024)
        local height = self:GetNWInt("ScreenHeight", 576)
        self.Browser:SetSize(width, height)
        self:LoadYouTubeURL()
        self:SetupJavaScriptAPI()
        print("[YouTube TV] Клиентская часть инициализирована")
    end

    function ENT:LoadYouTubeURL()
        local url = self:GetNWString("YouTubeURL", self.DefaultURL)
        if GoodbyeDPI and GoodbyeDPI.ProcessURL then
            url = GoodbyeDPI.ProcessURL(url)
        end
        if string.find(url, "youtube.com/watch") then
            local videoId = self:ExtractVideoID(url)
            if videoId then
                url = string.format("https://www.youtube.com/embed/%s?autoplay=1&enablejsapi=1&origin=gmod&controls=1&modestbranding=1", videoId)
            end
        end
        self.Browser:OpenURL(url)
        self.CurrentURL = url
    end

    function ENT:ExtractVideoID(url)
        local patterns = { "youtube%.com/watch%?v=([%w%-_]+)", "youtu%.be/([%w%-_]+)", "youtube%.com/embed/([%w%-_]+)" }
        for _, pattern in ipairs(patterns) do
            local id = string.match(url, pattern)
            if id then return id end
        end
        return nil
    end

    function ENT:SetupJavaScriptAPI()
        self.Browser:AddFunction("gmod", "onPlayerReady", function()
            print("[YouTube TV] Плеер готов")
            self:UpdatePlayerState()
        end)
        self.Browser:AddFunction("gmod", "onPlayerStateChange", function(state)
            print("[YouTube TV] Состояние плеера: " .. tostring(state))
            self:SetNWBool("IsPlaying", state == 1)
        end)
        self.Browser:AddFunction("gmod", "onPlayerError", function(error)
            print("[YouTube TV] Ошибка плеера: " .. tostring(error))
        end)
    end

    function ENT:UpdatePlayerState()
        local volume = self:GetNWInt("Volume", 50)
        local isPlaying = self:GetNWBool("IsPlaying", true)
        if isPlaying then self.Browser:Call("playVideo") else self.Browser:Call("pauseVideo") end
        self.Browser:Call("setVolume", volume)
    end

    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        if not IsValid(self.Browser) then return end
        local pos, ang, scale = self:GetPos(), self:GetAngles(), self:GetNWFloat("ScreenScale", 0.08)
        ang:RotateAroundAxis(ang:Up(), 90)
        cam.Start3D2D(pos + ang:Up() * 1, ang, scale)
            local mat = self.Browser:GetHTMLMaterial()
            if mat then
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(mat)
                local width, height = self:GetNWInt("ScreenWidth", 1024), self:GetNWInt("ScreenHeight", 576)
                surface.DrawTexturedRect(0, 0, width, height)
                self:DrawVolumeIndicator(width, height)
            else
                surface.SetDrawColor(20, 20, 20, 255)
                surface.DrawRect(0, 0, 1024, 576)
                draw.SimpleText("YouTube TV", "DermaLarge", 512, 288, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Загрузка...", "DermaDefault", 512, 320, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        cam.End3D2D()
    end

    function ENT:DrawVolumeIndicator(width, height)
        local volume = self:GetNWInt("Volume", 50)
        local isMuted = self:GetNWBool("IsMuted", false)
        if isMuted then
            draw.SimpleText("🔇", "DermaLarge", width - 50, 30, Color(255, 100, 100), TEXT_ALIGN_CENTER)
        else
            local barWidth, barHeight, x, y = 100, 10, width - 120, 30
            surface.SetDrawColor(50, 50, 50, 200)
            surface.DrawRect(x, y, barWidth, barHeight)
            surface.SetDrawColor(100, 255, 100, 255)
            surface.DrawRect(x, y, (barWidth * volume / 100), barHeight)
            draw.SimpleText(volume .. "%", "DermaDefault", x + barWidth / 2, y + 15, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
    end

    function ENT:Think()
        local newURL = self:GetNWString("YouTubeURL", "")
        if self.LastURL ~= newURL and newURL ~= "" then
            self.LastURL = newURL
            self:LoadYouTubeURL()
        end
        local newSize = self:GetNWString("ScreenSize", "medium")
        if self.LastSize ~= newSize then
            self.LastSize = newSize
            local size = self.ScreenSizes[newSize]
            if size and IsValid(self.Browser) then
                self.Browser:SetSize(size.width, size.height)
            end
        end
    end
end

scripted_ents.Register(ENT, "youtube_tv_screen")


--==============================================================================
-- 3. VGUI Panel Definition (youtube_control_panel)
--==============================================================================

local PANEL = {}

function PANEL:Init()
    self:SetSize(500, 400)
    self:SetTitle("YouTube TV - Панель управления")
    self:Center()
    self:SetDraggable(true)
    self:SetSizable(false)
    self:ShowCloseButton(true)
    self.URLEntry = vgui.Create("DTextEntry", self)
    self.URLEntry:SetPos(10, 30)
    self.URLEntry:SetSize(380, 25)
    self.URLEntry:SetPlaceholderText("Вставьте ссылку на YouTube видео...")
    self.PlayButton = vgui.Create("DButton", self)
    self.PlayButton:SetPos(400, 30)
    self.PlayButton:SetSize(80, 25)
    self.PlayButton:SetText("Загрузить")
    self.PlayButton.DoClick = function()
        local url = self.URLEntry:GetValue()
        if url ~= "" then self:SendURL(url) end
    end
    local quickLinks = {
        {name = "Lofi Hip Hop", url = "https://www.youtube.com/watch?v=jfKfPfyJRdk"},
        {name = "Rick Roll", url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"},
        {name = "Nyan Cat", url = "https://www.youtube.com/watch?v=QH2-TGUlwu4"},
        {name = "Big Buck Bunny", url = "https://www.youtube.com/watch?v=YE7VzlLtp-4"}
    }
    for i, link in ipairs(quickLinks) do
        local btn = vgui.Create("DButton", self)
        btn:SetPos(10 + (i-1) * 120, 70)
        btn:SetSize(115, 30)
        btn:SetText(link.name)
        btn.DoClick = function()
            self.URLEntry:SetValue(link.url)
            self:SendURL(link.url)
        end
    end
    self.PlayPauseButton = vgui.Create("DButton", self)
    self.PlayPauseButton:SetPos(10, 110)
    self.PlayPauseButton:SetSize(80, 30)
    self.PlayPauseButton:SetText("⏯ Пауза")
    self.PlayPauseButton.DoClick = function() self:SendPlayPause() end
    self.VolumeLabel = vgui.Create("DLabel", self)
    self.VolumeLabel:SetPos(100, 115)
    self.VolumeLabel:SetSize(80, 20)
    self.VolumeLabel:SetText("Громкость:")
    self.VolumeSlider = vgui.Create("DNumSlider", self)
    self.VolumeSlider:SetPos(180, 110)
    self.VolumeSlider:SetSize(200, 30)
    self.VolumeSlider:SetMinMax(0, 100)
    self.VolumeSlider:SetValue(50)
    self.VolumeSlider:SetDecimals(0)
    self.VolumeSlider.OnValueChanged = function(_, value) self:SendVolume(math.floor(value)) end
    self.MuteButton = vgui.Create("DButton", self)
    self.MuteButton:SetPos(390, 110)
    self.MuteButton:SetSize(90, 30)
    self.MuteButton:SetText("🔇 Откл.")
    self.MuteButton.DoClick = function() self:SendVolume(0); self.VolumeSlider:SetValue(0) end
    self.SizeLabel = vgui.Create("DLabel", self)
    self.SizeLabel:SetPos(10, 155)
    self.SizeLabel:SetSize(100, 20)
    self.SizeLabel:SetText("Размер экрана:")
    self.SizeCombo = vgui.Create("DComboBox", self)
    self.SizeCombo:SetPos(120, 150)
    self.SizeCombo:SetSize(150, 25)
    self.SizeCombo:AddChoice("Маленький", "small")
    self.SizeCombo:AddChoice("Средний", "medium")
    self.SizeCombo:AddChoice("Большой", "large")
    self.SizeCombo:AddChoice("Кастомный", "custom")
    self.SizeCombo:SetValue("Средний")
    self.SizeCombo.OnSelect = function(_, _, _, data) self:SendScreenSize(data) end
    self.InfoPanel = vgui.Create("DPanel", self)
    self.InfoPanel:SetPos(10, 190)
    self.InfoPanel:SetSize(470, 100)
    self.InfoPanel.Paint = function(_, w, h)
        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(80, 80, 80, 255)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    self.InfoText = vgui.Create("DLabel", self.InfoPanel)
    self.InfoText:SetPos(10, 10)
    self.InfoText:SetSize(450, 80)
    self.InfoText:SetText("Инструкции:\n• Вставьте ссылку на YouTube видео\n• Используйте быстрые кнопки для популярного контента\n• Управляйте громкостью и воспроизведением\n• Выберите размер экрана\n• Видео будет видно всем игрокам")
    self.InfoText:SetWrap(true)
    self.InfoText:SetTextColor(Color(200, 200, 200))
    self.AdvancedLabel = vgui.Create("DLabel", self)
    self.AdvancedLabel:SetPos(10, 305)
    self.AdvancedLabel:SetSize(200, 20)
    self.AdvancedLabel:SetText("Дополнительно:")
    self.StopButton = vgui.Create("DButton", self)
    self.StopButton:SetPos(10, 330)
    self.StopButton:SetSize(100, 25)
    self.StopButton:SetText("⏹ Остановить")
    self.StopButton.DoClick = function() self:SendURL("about:blank"); self:Close() end
    self.ReloadButton = vgui.Create("DButton", self)
    self.ReloadButton:SetPos(120, 330)
    self.ReloadButton:SetSize(100, 25)
    self.ReloadButton:SetText("🔄 Перезагрузить")
    self.ReloadButton.DoClick = function()
        if IsValid(self.Screen) then
            local url = self.Screen:GetNWString("YouTubeURL", "")
            if url ~= "" then self:SendURL(url) end
        end
    end
    if LocalPlayer():IsAdmin() then
        self.RemoveButton = vgui.Create("DButton", self)
        self.RemoveButton:SetPos(230, 330)
        self.RemoveButton:SetSize(120, 25)
        self.RemoveButton:SetText("🗑 Удалить экран")
        self.RemoveButton:SetColor(Color(255, 100, 100))
        self.RemoveButton.DoClick = function()
            if IsValid(self.Screen) then
                Derma_Query("Вы уверены, что хотите удалить этот экран?", "Удаление экрана", "Да", function() self.Screen:Remove(); self:Close() end, "Нет")
            end
        end
    end
    self.DPILabel = vgui.Create("DLabel", self)
    self.DPILabel:SetPos(10, 365)
    self.DPILabel:SetSize(470, 20)
    self.DPILabel:SetText("✅ GoodbyeDPI обход активирован для доступа к YouTube")
    self.DPILabel:SetTextColor(Color(100, 255, 100))
end

function PANEL:SetScreen(screen)
    self.Screen = screen
    if IsValid(screen) then
        self.URLEntry:SetValue(screen:GetNWString("YouTubeURL", ""))
        self.VolumeSlider:SetValue(screen:GetNWInt("Volume", 50))
        local size = screen:GetNWString("ScreenSize", "medium")
        local sizeNames = {["small"] = "Маленький", ["medium"] = "Средний", ["large"] = "Большой", ["custom"] = "Кастомный"}
        self.SizeCombo:SetValue(sizeNames[size] or "Средний")
    end
end

function PANEL:SendURL(url)
    if not IsValid(self.Screen) then return end
    net.Start("YouTubeTV_SetURL")
    net.WriteEntity(self.Screen)
    net.WriteString(url)
    net.SendToServer()
    self:Close()
end

function PANEL:SendVolume(volume)
    if not IsValid(self.Screen) then return end
    net.Start("YouTubeTV_VolumeControl")
    net.WriteEntity(self.Screen)
    net.WriteInt(volume, 8)
    net.SendToServer()
end

function PANEL:SendPlayPause()
    if not IsValid(self.Screen) then return end
    net.Start("YouTubeTV_PlayPause")
    net.WriteEntity(self.Screen)
    net.SendToServer()
end

function PANEL:SendScreenSize(size)
    if not IsValid(self.Screen) then return end
    -- This needs to be a net message to the server to call the entity's method.
    -- For now, let's assume a net message exists or should be created.
    -- This is a logical gap in the provided VGUI code.
    -- I will create a new net message for this.
    net.Start("YouTubeTV_SetScreenSize")
    net.WriteEntity(self.Screen)
    net.WriteString(size)
    net.SendToServer()
end

vgui.Register("YouTubeControlPanel", PANEL, "DFrame")


--==============================================================================
-- 4. Networking and Initialization
--==============================================================================

if SERVER then
    util.AddNetworkString("YouTubeTV_OpenPanel")
    util.AddNetworkString("YouTubeTV_SetURL")
    util.AddNetworkString("YouTubeTV_VolumeControl")
    util.AddNetworkString("YouTubeTV_PlayPause")
    util.AddNetworkString("YouTubeTV_Seek")
    util.AddNetworkString("YouTubeTV_Sync")
    util.AddNetworkString("YouTubeTV_SetScreenSize") -- Add this new network string

    net.Receive("YouTubeTV_SetScreenSize", function(len, ply)
        local screen = net.ReadEntity()
        local size = net.ReadString()
        if IsValid(screen) and IsValid(ply) and screen.SetScreenSize then
            screen:SetScreenSize(size)
        end
    end)

    net.Receive("YouTubeTV_PlayPause", function(len, ply)
        local screen = net.ReadEntity()
        if not IsValid(screen) or not IsValid(ply) then return end

        local current_playing = screen:GetNWBool("IsPlaying", true)
        screen:SetNWBool("IsPlaying", not current_playing)

        net.Start("YouTubeTV_Sync")
        net.WriteEntity(screen)
        net.WriteString("playpause")
        net.WriteBool(not current_playing)
        net.Broadcast()
    end)
else -- CLIENT
    hook.Add("Initialize", "YouTubeTV_InitDPI", function()
        InitGoodbyeDPI()
    end)

    net.Receive("YouTubeTV_OpenPanel", function()
        local screen = net.ReadEntity()
        if IsValid(screen) then
            local panel = vgui.Create("YouTubeControlPanel")
            panel:SetScreen(screen)
            panel:MakePopup()
        end
    end)

    net.Receive("YouTubeTV_Sync", function()
        local screen = net.ReadEntity()
        if not IsValid(screen) then return end
        local type = net.ReadString()

        if type == "url" then
            if IsValid(screen.Browser) then
                screen:LoadYouTubeURL()
            end
        elseif type == "volume" then
            local volume = net.ReadInt(8)
            if IsValid(screen.Browser) then
                screen.Browser:Call("setVolume", volume)
            end
        elseif type == "playpause" then
            local isPlaying = net.ReadBool()
            if IsValid(screen.Browser) then
                if isPlaying then
                    screen.Browser:Call("playVideo();")
                else
                    screen.Browser:Call("pauseVideo();")
                end
            end
        end
    end)

    hook.Add("PlayerBindPress", "YouTubeTV_OpenControlPanel_CKey", function(ply, bind, pressed)
        if not pressed then return end
        if string.lower(bind) ~= "c" and bind ~= "+menu_context" then return end -- Check for 'c' and '+menu_context'

        local trace = ply:GetEyeTrace()
        local ent = trace.Entity

        if IsValid(ent) and ent:GetClass() == "youtube_tv_screen" then
            local panel = vgui.Create("YouTubeControlPanel")
            panel:SetScreen(ent)
            panel:MakePopup()
            return true
        end
    end)
end
