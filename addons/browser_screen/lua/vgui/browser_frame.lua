-- Создаем новый тип VGUI панели
local PANEL = {}

function PANEL:Init()
    -- Настройки окна
    self:SetSize(400, 350)
    self:SetTitle("Управление браузером")
    self:Center()  -- Центрируем окно
    self:SetDraggable(true)   -- Можно перетаскивать
    self:SetSizable(false)    -- Нельзя изменять размер
    self:ShowCloseButton(true) -- Показываем кнопку закрытия

    -- Поле ввода URL
    self.URLEntry = vgui.Create("DTextEntry", self)
    self.URLEntry:SetPos(10, 30)
    self.URLEntry:SetSize(300, 25)
    self.URLEntry:SetPlaceholderText("Введите URL...")

    -- Кнопка "Перейти"
    self.GoButton = vgui.Create("DButton", self)
    self.GoButton:SetPos(320, 30)
    self.GoButton:SetSize(70, 25)
    self.GoButton:SetText("Перейти")

    -- Обработчик нажатия кнопки "Перейти"
    self.GoButton.DoClick = function()
        local url = self.URLEntry:GetValue()
        if url ~= "" then
            self:SendURL(url)
        end
    end

    -- Обработчик Enter в поле ввода
    self.URLEntry.OnEnter = function()
        self.GoButton:DoClick()
    end

    -- Быстрые кнопки
    local quickButtons = {
        {name = "Google", url = "https://www.google.com"},
        {name = "YouTube", url = "https://www.youtube.com"},
        {name = "Wikipedia", url = "https://ru.wikipedia.org"},
        {name = "GitHub", url = "https://github.com"}
    }

    for i, btn in ipairs(quickButtons) do
        local button = vgui.Create("DButton", self)
        button:SetPos(10 + (i-1) * 95, 70)
        button:SetSize(90, 30)
        button:SetText(btn.name)

        button.DoClick = function()
            self.URLEntry:SetValue(btn.url)
            self:SendURL(btn.url)
        end
    end

    -- Кнопки управления
    self.BackButton = vgui.Create("DButton", self)
    self.BackButton:SetPos(10, 110)
    self.BackButton:SetSize(60, 25)
    self.BackButton:SetText("← Назад")

    self.ForwardButton = vgui.Create("DButton", self)
    self.ForwardButton:SetPos(80, 110)
    self.ForwardButton:SetSize(60, 25)
    self.ForwardButton:SetText("Вперед →")

    self.RefreshButton = vgui.Create("DButton", self)
    self.RefreshButton:SetPos(150, 110)
    self.RefreshButton:SetSize(80, 25)
    self.RefreshButton:SetText("⟳ Обновить")

    -- YouTube Controls
    self.YTLabel = vgui.Create("DLabel", self)
    self.YTLabel:SetPos(10, 145)
    self.YTLabel:SetText("YouTube управление (экспериментальное):")

    self.TogglePlayButton = vgui.Create("DButton", self)
    self.TogglePlayButton:SetPos(10, 165)
    self.TogglePlayButton:SetSize(120, 25)
    self.TogglePlayButton:SetText("▶ Play / || Pause")
    self.TogglePlayButton.DoClick = function()
        if not IsValid(self.Screen) or not IsValid(self.Screen.Browser) then return end
        -- This is a bit of a hack, it finds the first video element on the page. Works for youtube embeds.
        self.Screen.Browser:RunJavascript("var p = document.getElementsByTagName('video')[0]; if (p.paused) { p.play() } else { p.pause(); }")
    end

    self.MuteButton = vgui.Create("DButton", self)
    self.MuteButton:SetPos(140, 165)
    self.MuteButton:SetSize(100, 25)
    self.MuteButton:SetText("Mute / Unmute")
    self.MuteButton.DoClick = function()
        if not IsValid(self.Screen) or not IsValid(self.Screen.Browser) then return end
        self.Screen.Browser:RunJavascript("var p = document.getElementsByTagName('video')[0]; p.muted = !p.muted;")
    end

    -- Информационная панель
    self.InfoLabel = vgui.Create("DLabel", self)
    self.InfoLabel:SetPos(10, 200)
    self.InfoLabel:SetSize(380, 60)
    self.InfoLabel:SetText("Инструкция:\n• Введите URL и нажмите 'Перейти'\n• Используйте быстрые кнопки для популярных сайтов\n• Экран будет виден всем игрокам на сервере")
    self.InfoLabel:SetWrap(true)

    -- Кнопка закрытия экрана
    self.CloseScreenButton = vgui.Create("DButton", self)
    self.CloseScreenButton:SetPos(10, 270)
    self.CloseScreenButton:SetSize(380, 30)
    self.CloseScreenButton:SetText("Показать пустую страницу")
    self.CloseScreenButton.DoClick = function()
        self:SendURL("about:blank")
    end

    -- Кнопка удаления экрана (только для админов)
    if LocalPlayer():IsAdmin() then
        self.RemoveButton = vgui.Create("DButton", self)
        self.RemoveButton:SetPos(10, 310)
        self.RemoveButton:SetSize(380, 25)
        self.RemoveButton:SetText("🗑 Удалить экран (только админ)")
        self.RemoveButton:SetColor(Color(200, 50, 50))

        self.RemoveButton.DoClick = function()
            if IsValid(self.Screen) then
                RunConsoleCommand("say", "/removeent") -- Команда удаления
                self:Close()
            end
        end
    end
end

-- Установка экрана для управления
function PANEL:SetScreen(screen)
    self.Screen = screen

    -- Заполняем поле текущим URL
    if IsValid(screen) then
        local currentURL = screen:GetNWString("URL", "")
        self.URLEntry:SetValue(currentURL)
    end
end

-- Отправка URL на сервер
function PANEL:SendURL(url)
    if not IsValid(self.Screen) then return end

    -- Простая валидация URL
    if not string.match(url, "^https?://") and url ~= "about:blank" then
        url = "http://" .. url
    end

    -- Отправляем на сервер
    net.Start("BrowserSetURL")
    net.WriteEntity(self.Screen)
    net.WriteString(url)
    net.SendToServer()

    -- Закрываем панель
    self:Close()

    print("[Browser Screen] URL отправлен: " .. url)
end

-- Регистрируем панель в системе VGUI
vgui.Register("BrowserFrame", PANEL, "DFrame")
