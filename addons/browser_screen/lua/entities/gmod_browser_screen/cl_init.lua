include("shared.lua")

-- RenderGroup определяет когда рендерить энтити
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
    -- Создаем DHTML панель (встроенный браузер)
    self.Browser = vgui.Create("DHTML")
    self.Browser:SetSize(self.ScreenWidth, self.ScreenHeight)
    self.Browser:SetVisible(false)  -- Скрываем панель (будем рендерить на экран)

    -- Загружаем начальный URL
    local url = self:GetNWString("URL", self.DefaultURL)
    self.Browser:OpenURL(url)

    -- Обработчик успешной загрузки страницы
    self.Browser.OnDocumentReady = function(panel)
        print("[Browser Screen] Страница загружена: " .. url)
    end

    -- Обработчик изменения URL
    self.Browser.OnChangeTitle = function(panel, title)
        print("[Browser Screen] Заголовок изменен: " .. title)
    end

    print("[Browser Screen] Клиентская часть инициализирована")
end

-- Основной рендеринг модели
function ENT:Draw()
    self:DrawModel()  -- Рисуем базовую модель
end

-- Рендеринг прозрачных элементов (наш браузер)
function ENT:DrawTranslucent()
    if not IsValid(self.Browser) then return end

    -- Получаем позицию и углы экрана
    local pos = self:GetPos()
    local ang = self:GetAngles()

    -- Поворачиваем на 90 градусов для правильного отображения
    ang:RotateAroundAxis(ang:Up(), 90)

    -- Начинаем 3D2D рендеринг (рисование 2D на 3D поверхности)
    cam.Start3D2D(pos + ang:Up() * 0.1, ang, 0.1)
        -- Получаем материал из DHTML панели
        local mat = self.Browser:GetHTMLMaterial()
        if mat then
            surface.SetDrawColor(255, 255, 255, 255)  -- Белый цвет
            surface.SetMaterial(mat)                   -- Устанавливаем материал браузера
            surface.DrawTexturedRect(0, 0, self.ScreenWidth, self.ScreenHeight)
        else
            -- Если браузер не загрузился, показываем заглушку
            surface.SetDrawColor(50, 50, 50, 255)
            surface.DrawRect(0, 0, self.ScreenWidth, self.ScreenHeight)

            draw.SimpleText("Загрузка...", "DermaLarge",
                          self.ScreenWidth/2, self.ScreenHeight/2,
                          Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end

-- Обновление данных с сервера
function ENT:Think()
    -- Проверяем изменился ли URL
    local newURL = self:GetNWString("URL", self.DefaultURL)
    if self.LastURL ~= newURL then
        self.LastURL = newURL
        if IsValid(self.Browser) then
            self.Browser:OpenURL(newURL)
            print("[Browser Screen] URL обновлен: " .. newURL)
        end
    end
end

-- Обработка сетевых сообщений
net.Receive("BrowserSync", function()
    local screen = net.ReadEntity()
    local url = net.ReadString()

    if IsValid(screen) and IsValid(screen.Browser) then
        screen.Browser:OpenURL(url)
        print("[Browser Screen] Синхронизация URL: " .. url)
    end
end)

net.Receive("BrowserOpenPanel", function()
    local screen = net.ReadEntity()

    if IsValid(screen) then
        -- Открываем панель управления браузером
        local frame = vgui.Create("BrowserFrame")
        frame:SetScreen(screen)
        frame:MakePopup()  -- Делаем окно активным
        print("[Browser Screen] Панель управления открыта")
    end
end)
