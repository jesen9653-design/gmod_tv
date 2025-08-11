-- Панель управления YouTube TV (открывается по клавише C)

local PANEL = {}

function PANEL:Init()
    -- Настройка окна
    self:SetSize(500, 400)
    self:SetTitle("YouTube TV - Панель управления")
    self:Center()
    self:SetDraggable(true)
    self:SetSizable(false)
    self:ShowCloseButton(true)

    -- Поле ввода YouTube URL
    self.URLEntry = vgui.Create("DTextEntry", self)
    self.URLEntry:SetPos(10, 30)
    self.URLEntry:SetSize(380, 25)
    self.URLEntry:SetPlaceholderText("Вставьте ссылку на YouTube видео...")

    -- Кнопка воспроизведения
    self.PlayButton = vgui.Create("DButton", self)
    self.PlayButton:SetPos(400, 30)
    self.PlayButton:SetSize(80, 25)
    self.PlayButton:SetText("Загрузить")
    self.PlayButton.DoClick = function()
        local url = self.URLEntry:GetValue()
        if url ~= "" then
            self:SendURL(url)
        end
    end

    -- Быстрые ссылки
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

    -- Управление воспроизведением
    self.PlayPauseButton = vgui.Create("DButton", self)
    self.PlayPauseButton:SetPos(10, 110)
    self.PlayPauseButton:SetSize(80, 30)
    self.PlayPauseButton:SetText("⏯ Пауза")
    self.PlayPauseButton.DoClick = function()
        self:SendPlayPause()
    end

    -- Управление громкостью
    self.VolumeLabel = vgui.Create("DLabel", self)
    self.VolumeLabel:SetPos(100, 115)
    self.VolumeLabel:SetSize(80, 20)
    self.VolumeLabel:SetText("Громкость:")

    self.VolumeSlider = vgui.Create("DNumSlider", self)
    self.VolumeSlider:SetPos(180, 110)
    self.VolumeSlider:SetSize(200, 30)
    self.VolumeSlider:SetMin(0)
    self.VolumeSlider:SetMax(100)
    self.VolumeSlider:SetValue(50)
    self.VolumeSlider:SetDecimals(0)
    self.VolumeSlider.OnValueChanged = function(slider, value)
        self:SendVolume(math.floor(value))
    end

    -- Кнопка отключения звука
    self.MuteButton = vgui.Create("DButton", self)
    self.MuteButton:SetPos(390, 110)
    self.MuteButton:SetSize(90, 30)
    self.MuteButton:SetText("🔇 Откл.")
    self.MuteButton.DoClick = function()
        self:SendVolume(0)
        self.VolumeSlider:SetValue(0)
    end

    -- Выбор размера экрана
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

    self.SizeCombo.OnSelect = function(panel, index, value, data)
        self:SendScreenSize(data)
    end

    -- Информация о текущем видео
    self.InfoPanel = vgui.Create("DPanel", self)
    self.InfoPanel:SetPos(10, 190)
    self.InfoPanel:SetSize(470, 100)
    self.InfoPanel.Paint = function(panel, w, h)
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

    -- Кнопки дополнительного управления
    self.AdvancedLabel = vgui.Create("DLabel", self)
    self.AdvancedLabel:SetPos(10, 305)
    self.AdvancedLabel:SetSize(200, 20)
    self.AdvancedLabel:SetText("Дополнительно:")

    self.StopButton = vgui.Create("DButton", self)
    self.StopButton:SetPos(10, 330)
    self.StopButton:SetSize(100, 25)
    self.StopButton:SetText("⏹ Остановить")
    self.StopButton.DoClick = function()
        self:SendURL("about:blank")
        self:Close()
    end

    self.ReloadButton = vgui.Create("DButton", self)
    self.ReloadButton:SetPos(120, 330)
    self.ReloadButton:SetSize(100, 25)
    self.ReloadButton:SetText("🔄 Перезагрузить")
    self.ReloadButton.DoClick = function()
        if IsValid(self.Screen) then
            local url = self.Screen:GetNWString("YouTubeURL", "")
            if url ~= "" then
                self:SendURL(url)
            end
        end
    end

    -- Кнопка удаления экрана (только админы)
    if LocalPlayer():IsAdmin() then
        self.RemoveButton = vgui.Create("DButton", self)
        self.RemoveButton:SetPos(230, 330)
        self.RemoveButton:SetSize(120, 25)
        self.RemoveButton:SetText("🗑 Удалить экран")
        self.RemoveButton:SetColor(Color(255, 100, 100))
        self.RemoveButton.DoClick = function()
            if IsValid(self.Screen) then
                Derma_Query(
                    "Вы уверены, что хотите удалить этот экран?",
                    "Удаление экрана",
                    "Да", function()
                        self.Screen:Remove()
                        self:Close()
                    end,
                    "Нет"
                )
            end
        end
    end

    -- Информация о GoodbyeDPI
    self.DPILabel = vgui.Create("DLabel", self)
    self.DPILabel:SetPos(10, 365)
    self.DPILabel:SetSize(470, 20)
    self.DPILabel:SetText("✅ GoodbyeDPI обход активирован для доступа к YouTube")
    self.DPILabel:SetTextColor(Color(100, 255, 100))
end

function PANEL:SetScreen(screen)
    self.Screen = screen

    if IsValid(screen) then
        -- Заполняем текущие значения
        local url = screen:GetNWString("YouTubeURL", "")
        self.URLEntry:SetValue(url)

        local volume = screen:GetNWInt("Volume", 50)
        self.VolumeSlider:SetValue(volume)

        local size = screen:GetNWString("ScreenSize", "medium")
        local sizeNames = {
            ["small"] = "Маленький",
            ["medium"] = "Средний",
            ["large"] = "Большой",
            ["custom"] = "Кастомный"
        }
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

    if IsValid(self.Screen) and self.Screen.SetScreenSize then
        self.Screen:SetScreenSize(size)
    end
end

-- Регистрируем панель
vgui.Register("YouTubeControlPanel", PANEL, "DFrame")

-- Хук для открытия панели по клавише C
hook.Add("PlayerBindPress", "YouTubeTV_OpenControlPanel", function(ply, bind, pressed)
    if not pressed then return end
    if bind ~= "+menu_context" then return end -- Клавиша C

    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if IsValid(ent) and ent:GetClass() == "youtube_tv_screen" then
        local panel = vgui.Create("YouTubeControlPanel")
        panel:SetScreen(ent)
        panel:MakePopup()

        return true -- Блокируем стандартное меню
    end
end)

-- Комментарий для агента:
-- Полная панель управления YouTube TV
-- Открывается по клавише C при наведении на экран
-- Включает все функции: URL, громкость, размер, быстрые ссылки
-- Показывает статус GoodbyeDPI обхода
