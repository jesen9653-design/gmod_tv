-- Клиентская часть YouTube TV экрана

include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
    -- Создаем DHTML панель для YouTube
    self.Browser = vgui.Create("DHTML")
    self.Browser:SetVisible(false)

    -- Получаем размеры экрана
    local width = self:GetNWInt("ScreenWidth", 1024)
    local height = self:GetNWInt("ScreenHeight", 576)
    self.Browser:SetSize(width, height)

    -- Загружаем YouTube с обходом DPI
    self:LoadYouTubeURL()

    -- Настройка JavaScript API
    self:SetupJavaScriptAPI()

    print("[YouTube TV] Клиентская часть инициализирована")
end

function ENT:LoadYouTubeURL()
    local url = self:GetNWString("YouTubeURL", self.DefaultURL)

    -- Применяем GoodbyeDPI обход перед загрузкой
    if GoodbyeDPI and GoodbyeDPI.ProcessURL then
        url = GoodbyeDPI.ProcessURL(url)
    end

    -- Добавляем параметры для YouTube embed
    if string.find(url, "youtube.com/watch") then
        local videoId = self:ExtractVideoID(url)
        if videoId then
            url = string.format(
                "https://www.youtube.com/embed/%s?autoplay=1&enablejsapi=1&origin=gmod&controls=1&modestbranding=1",
                videoId
            )
        end
    end

    self.Browser:OpenURL(url)
    self.CurrentURL = url
end

function ENT:ExtractVideoID(url)
    -- Извлекаем ID видео из различных форматов YouTube URL
    local patterns = {
        "youtube%.com/watch%?v=([%w%-_]+)",
        "youtu%.be/([%w%-_]+)",
        "youtube%.com/embed/([%w%-_]+)"
    }

    for _, pattern in ipairs(patterns) do
        local id = string.match(url, pattern)
        if id then return id end
    end

    return nil
end

function ENT:SetupJavaScriptAPI()
    -- Связывание JavaScript с Lua для управления плеером
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
    -- Обновляем состояние плеера
    local volume = self:GetNWInt("Volume", 50)
    local isPlaying = self:GetNWBool("IsPlaying", true)

    if isPlaying then
        self.Browser:Call("playVideo")
    else
        self.Browser:Call("pauseVideo")
    end

    self.Browser:Call("setVolume", volume)
end

-- Рендеринг экрана в игровом мире
function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    if not IsValid(self.Browser) then return end

    local pos = self:GetPos()
    local ang = self:GetAngles()
    local scale = self:GetNWFloat("ScreenScale", 0.08)

    -- Поворачиваем для корректного отображения
    ang:RotateAroundAxis(ang:Up(), 90)

    -- 3D2D рендеринг YouTube на экране
    cam.Start3D2D(pos + ang:Up() * 1, ang, scale)
        local mat = self.Browser:GetHTMLMaterial()
        if mat then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(mat)

            local width = self:GetNWInt("ScreenWidth", 1024)
            local height = self:GetNWInt("ScreenHeight", 576)
            surface.DrawTexturedRect(0, 0, width, height)

            -- Индикатор громкости
            self:DrawVolumeIndicator(width, height)
        else
            -- Заглушка при загрузке
            surface.SetDrawColor(20, 20, 20, 255)
            surface.DrawRect(0, 0, 1024, 576)

            draw.SimpleText("YouTube TV", "DermaLarge", 512, 288,
                          Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Загрузка...", "DermaDefault", 512, 320,
                          Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end

function ENT:DrawVolumeIndicator(width, height)
    local volume = self:GetNWInt("Volume", 50)
    local isMuted = self:GetNWBool("IsMuted", false)

    if isMuted then
        -- Иконка "без звука"
        draw.SimpleText("🔇", "DermaLarge", width - 50, 30,
                      Color(255, 100, 100), TEXT_ALIGN_CENTER)
    else
        -- Полоса громкости
        local barWidth = 100
        local barHeight = 10
        local x = width - 120
        local y = 30

        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(x, y, barWidth, barHeight)

        surface.SetDrawColor(100, 255, 100, 255)
        surface.DrawRect(x, y, (barWidth * volume / 100), barHeight)

        draw.SimpleText(volume .. "%", "DermaDefault", x + barWidth/2, y + 15,
                      Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
end

-- Обработка обновлений с сервера
function ENT:Think()
    -- Проверяем изменения URL
    local newURL = self:GetNWString("YouTubeURL", "")
    if self.LastURL ~= newURL and newURL ~= "" then
        self.LastURL = newURL
        self:LoadYouTubeURL()
    end

    -- Обновляем размер если изменился
    local newSize = self:GetNWString("ScreenSize", "medium")
    if self.LastSize ~= newSize then
        self.LastSize = newSize
        local size = self.ScreenSizes[newSize]
        if size and IsValid(self.Browser) then
            self.Browser:SetSize(size.width, size.height)
        end
    end
end

-- Обработка сетевых сообщений
net.Receive("YouTubeTV_Sync", function()
    local screen = net.ReadEntity()
    local type = net.ReadString()

    if not IsValid(screen) then return end

    if type == "url" then
        local url = net.ReadString()
        if IsValid(screen.Browser) then
            screen:LoadYouTubeURL()
        end
    elseif type == "volume" then
        local volume = net.ReadInt(8)
        if IsValid(screen.Browser) then
            screen.Browser:Call("setVolume", volume)
        end
    end
end)

net.Receive("YouTubeTV_OpenPanel", function()
    local screen = net.ReadEntity()

    if IsValid(screen) then
        local panel = vgui.Create("YouTubeControlPanel")
        panel:SetScreen(screen)
        panel:MakePopup()
    end
end)

-- Комментарий для агента:
-- Отображает YouTube видео на 3D экране
-- Обрабатывает JavaScript API YouTube плеера
-- Применяет GoodbyeDPI обход для загрузки
-- Показывает индикаторы громкости и состояния
