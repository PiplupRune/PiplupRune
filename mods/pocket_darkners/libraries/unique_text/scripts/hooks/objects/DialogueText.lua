---@class DialogueText : Text
local DialogueText, super = HookSystem.hookScript(DialogueText)

function DialogueText:init(...)
    self.typewriter_config = Kristal.getLibConfig("unique_text", "typewriter_config")

    self.cursor_color = self.typewriter_config["cursor_color"] or { 1, 1, 1 }

    self.cursor_fade = self.typewriter_config["cursor_fade"]
    if self.cursor_fade == nil then
        self.cursor_fade = false
    end

    self.cursor_fade_period = self.typewriter_config["cursor_fade_period"] or 1.0
    self.cursor_width = self.typewriter_config["cursor_width"] or 2
    self.cursor_hide_delay = self.typewriter_config["cursor_hide_delay"] or -1

    self.typo_chance = self.typewriter_config["typo_chance"] or 0
    self.typo_max_attempts = self.typewriter_config["typo_max_attempts"] or 1
    self.typo_max_letters = self.typewriter_config["typo_max_letters"] or 2
    self.typo_min_length = self.typewriter_config["typo_min_length"] or 4

    self.random_typos = self.typewriter_config["random_typos"]
    if self.random_typos == nil then
        self.random_typos = true
    end

    self.typo_partial_erase = self.typewriter_config["typo_partial_erase"]
    if self.typo_partial_erase == nil then
        self.typo_partial_erase = true
    end

    self.typo_pause = self.typewriter_config["typo_pause"] or 0.22
    self.typo_select_color = self.typewriter_config["typo_select_color"] or { 50 / 255, 63 / 255, 147 / 255 }
    self.typo_select_time = self.typewriter_config["typo_select_time"] or 0.25

    self.typo_select_word = self.typewriter_config["typo_select_word"]
    if self.typo_select_word == nil then
        self.typo_select_word = true
    end

    self.include_asterisk = Kristal.getLibConfig("unique_text", "include_asterisk")
    self.text_style = Kristal.getLibConfig("unique_text", "text_style")
    self.text_styles = { bounce = true, grow = true, rotate = true, typewriter = true }

    self.bounce_config = Kristal.getLibConfig("unique_text", "bounce_config")
    self.bounce_duration = self.bounce_config["bounce_duration"] or 0.08
    self.bounce_easing_style = self.bounce_config["bounce_easing_style"] or "linear"
    self.bounce_height = self.bounce_config["bounce_height"] or 6

    self.grow_config = Kristal.getLibConfig("unique_text", "grow_config")
    self.grow_duration = self.grow_config["grow_duration"] or 0.2
    self.grow_easing_style = self.grow_config["grow_easing_style"] or "out-back"
    self.grow_origin = self.grow_config["grow_origin"] or "bottom-center"
    self.grow_scale = self.grow_config["grow_scale"] or 0.2

    self.rotate_config = Kristal.getLibConfig("unique_text", "rotate_config")
    self.rotate_angle = self.rotate_config["rotate_angle"] or 30
    self.rotate_direction_default = self.rotate_config["rotate_direction_default"] or "right"

    self.rotate_direction_random = self.rotate_config["rotate_direction_random"]
    if self.rotate_direction_random == nil then
        self.rotate_direction_random = true
    end

    self.rotate_duration = self.rotate_config["rotate_duration"] or 0.2
    self.rotate_easing_style = self.rotate_config["rotate_easing_style"] or "out-back"
    self.rotate_origin = self.rotate_config["rotate_origin"] or "center"

    self.typo_selection = nil
    self.cursor_idle_start = nil
    self.cursor_finish_time = nil

    super.init(self, ...)

    self.text_timer = Timer()
    self:addChild(self.text_timer)

    self.draw_every_frame = true
end

function DialogueText:draw()
    local sel = self.typo_selection
    if sel and sel.w > 0 then
        local c = self.typo_select_color
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(c[1], c[2], c[3], a)
        love.graphics.rectangle("fill", sel.x, sel.y, sel.w, sel.h)
        love.graphics.setColor(r, g, b, a)
    end

    if self.state and self.state.text_style == "typewriter" and self.text ~= "" and not sel then
        self:drawCursor()
    end

    super.draw(self)
end

function DialogueText:animateChar(state)
    if not self.text_timer then
        return
    end

    local style = state.text_style or self.text_style

    if style == "grow" then
        state.scale = self.grow_scale
        self.text_timer:tween(self.grow_duration, state, { scale = 1 }, self.grow_easing_style)
    elseif style == "rotate" then
        state.rotation = math.rad(self.rotate_angle) * self:getRotateDir()
        self.text_timer:tween(self.rotate_duration, state, { rotation = 0 }, self.rotate_easing_style)
    elseif style == "bounce" then
        state.bounce_offset = self.bounce_height
        self.text_timer:tween(self.bounce_duration, state, { bounce_offset = 0 }, self.bounce_easing_style)
    end
end

function DialogueText:drawChar(node, state, use_color)
    local rotation = state.rotation or 0
    local scale = self:getCharScale(state)

    if scale ~= 1 or rotation ~= 0 then
        local x, y = self:getCharOrigin(node, state)

        love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.rotate(rotation)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-x, -y)

        super.drawChar(self, node, state, use_color)

        love.graphics.pop()
    else
        super.drawChar(self, node, state, use_color)
    end
end

function DialogueText:drawCursor()
    local time = Kristal.getTime()

    if self.state.typing then
        self.cursor_finish_time = nil
    else
        self.cursor_finish_time = self.cursor_finish_time or time
        if self.cursor_hide_delay >= 0 and (time - self.cursor_finish_time) >= self.cursor_hide_delay then
            return
        end
    end

    local alpha = 1
    local idle = (not self.state.typing) or (self.state.waiting or 0) > 0

    if not idle then
        self.cursor_idle_start = nil
    else
        self.cursor_idle_start = self.cursor_idle_start or time
        local t = (time - self.cursor_idle_start) / self.cursor_fade_period
        if self.cursor_fade then
            alpha = 0.5 + 0.5 * math.cos(t * math.pi * 2)
        else
            alpha = (t % 1 < 0.5) and 1 or 0
        end
    end

    local font = self:getFont()
    local font_scale = Assets.getFontScale(self.state.font, self.state.font_size)
    local h = font:getHeight() * font_scale

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(self.cursor_color[1], self.cursor_color[2], self.cursor_color[3], alpha * a)
    love.graphics.rectangle("fill", self.state.current_x, self.state.current_y, self.cursor_width, h)
    love.graphics.setColor(r, g, b, a)
end

function DialogueText:expandTypoCommands(nodes, typos)
    local out = {}

    for _, node in ipairs(nodes) do
        if node.type == "modifier" and node.command == "typo" then
            local mistake = typos[tonumber(node.arguments[1])]
            if mistake then
                local count = StringUtils.len(mistake)
                for k = 1, count do
                    table.insert(out, { type = "character", character = StringUtils.sub(mistake, k, k) })
                end

                if self.typo_pause > 0 then
                    table.insert(out, { type = "modifier", command = "wait", arguments = { self.typo_pause .. "s" } })
                end

                if node.arguments[2] ~= "partial" and self.typo_select_word then
                    table.insert(out, { type = "modifier", command = "typo_select", arguments = { count } })
                    table.insert(
                        out,
                        { type = "modifier", command = "wait", arguments = { self.typo_select_time .. "s" } }
                    )
                    table.insert(out, { type = "modifier", command = "typo_delete", arguments = { count } })
                else
                    for _ = 1, count do
                        table.insert(out, { type = "modifier", command = "typo_erase", arguments = {} })
                    end
                end
            end
        else
            table.insert(out, node)
        end
    end

    return out
end

function DialogueText:getCharOrigin(node, state)
    local x, y = self:getCharPosition(node, state)
    local w, h = self:getNodeSize(node, state)

    local origin = self.grow_origin
    if (state.text_style or self.text_style) == "rotate" then
        origin = self.rotate_origin
    end

    local ox, oy = x, y

    if origin == "top-center" then
        ox = x + w / 2
    elseif origin == "top-right" then
        ox = x + w
    elseif origin == "center-left" then
        oy = y + h / 2
    elseif origin == "center" then
        ox = x + w / 2
        oy = y + h / 2
    elseif origin == "center-right" then
        ox = x + w
        oy = y + h / 2
    elseif origin == "bottom-left" then
        oy = y + h
    elseif origin == "bottom-center" then
        ox = x + w / 2
        oy = y + h
    elseif origin == "bottom-right" then
        ox = x + w
        oy = y + h
    end

    return ox, oy
end

function DialogueText:getCharPosition(node, state)
    local x, y = super.getCharPosition(self, node, state)
    return x, y + (state.bounce_offset or 0)
end

function DialogueText:getCharScale(state)
    return state.scale or 1
end

function DialogueText:getRotateDir()
    if self.rotate_direction_random then
        return (love.math.random(0, 1) == 0) and -1 or 1
    end
    return self.rotate_direction_default == "right" and 1 or -1
end

function DialogueText:insertTypos(nodes)
    local indent_char = StringUtils.sub(self.indent_string, 1, 1)

    local function is_letter(node)
        return node and node.type == "character" and #node.character == 1 and node.character:match("%a") ~= nil
    end

    local style = self.text_style

    local out = {}
    local function emit(c)
        table.insert(out, { type = "character", character = c })
    end

    local i = 1
    while i <= #nodes do
        local node = nodes[i]
        local prev, prev2 = nodes[i - 1], nodes[i - 2]

        if node.type == "modifier" and node.command == "textstyle" then
            if node.arguments[1] == "reset" then
                style = self.text_style
            elseif self.text_styles[node.arguments[1]] then
                style = node.arguments[1]
            end
        end

        local word_start = style == "typewriter"
            and is_letter(node)
            and prev
            and prev.type == "character"
            and prev.character == " "
            and not (prev2 and prev2.type == "character" and prev2.character == indent_char)

        local j = i
        if word_start then
            while is_letter(nodes[j]) do
                j = j + 1
            end
        end
        local len = j - i

        if word_start and len >= self.typo_min_length and love.math.random() < self.typo_chance then
            local chars = {}
            for k = i, j - 1 do
                table.insert(chars, nodes[k].character)
            end

            local typed = 0
            local attempts = love.math.random(1, math.max(1, self.typo_max_attempts))

            for _ = 1, attempts do
                local wrong = self:mangleWord(chars, typed + 1)

                local first = len
                for k = typed + 1, len do
                    if wrong[k] ~= chars[k] then
                        first = k
                        break
                    end
                end
                if not self.typo_partial_erase then
                    first = 1
                end

                for k = typed + 1, len do
                    emit(wrong[k])
                end

                if self.typo_pause > 0 then
                    table.insert(out, { type = "modifier", command = "wait", arguments = { self.typo_pause .. "s" } })
                end

                if first == 1 and self.typo_select_word then
                    local count = len - typed
                    table.insert(out, { type = "modifier", command = "typo_select", arguments = { count } })
                    table.insert(
                        out,
                        { type = "modifier", command = "wait", arguments = { self.typo_select_time .. "s" } }
                    )
                    table.insert(out, { type = "modifier", command = "typo_delete", arguments = { count } })
                else
                    for _ = first, len do
                        table.insert(out, { type = "modifier", command = "typo_erase", arguments = {} })
                    end
                end
                typed = first - 1
            end

            for k = typed + 1, len do
                emit(chars[k])
            end
            i = j
        else
            table.insert(out, node)
            i = i + 1
        end
    end
    return out
end

function DialogueText:isNodeInstant(node)
    if node.type == "modifier" then
        if node.command == "typo_erase" or node.command == "typo_delete" then
            return false
        elseif node.command == "typo_select" then
            return true
        end
    end
    return super.isNodeInstant(self, node)
end

function DialogueText:isModifier(command)
    return command == "typo" or command == "text_style" or super.isModifier(self, command)
end

function DialogueText:mangleWord(chars, min_slot)
    local wrong = {}
    for i, c in ipairs(chars) do
        wrong[i] = c
    end

    local slots = {}
    for i = min_slot, #chars do
        slots[#slots + 1] = i
    end

    local count = math.min(love.math.random(1, self.typo_max_letters), #slots)
    for i = 1, count do
        local pick = table.remove(slots, love.math.random(1, #slots))
        local orig = chars[pick]
        local new
        repeat
            local idx = love.math.random(1, 26)
            new = ALPHABET:sub(idx, idx)
        until new ~= orig:lower()
        if orig ~= orig:lower() then
            new = new:upper()
        end
        wrong[pick] = new
    end
    return wrong
end

function DialogueText:processModifier(node, dry)
    super.processModifier(self, node, dry)

    if node.command == "text_style" then
        local name = node.arguments[1]
        if name == "reset" then
            self.state.text_style = self.text_style
        elseif self.text_styles[name] then
            self.state.text_style = name
        end
        return
    end

    if node.command == "typo_delete" then
        if not dry then
            local count = node.arguments[1]
            local last_removed
            for _ = 1, count do
                last_removed = table.remove(self.nodes_to_draw) or last_removed
            end
            if last_removed then
                self.state.current_x = last_removed[2].current_x
                self.state.current_y = last_removed[2].current_y
            end
            self.typo_selection = nil
            self.state.typed_characters = self.state.typed_characters + 1
        end
        return
    end

    if node.command == "typo_erase" then
        if not dry then
            local entry = table.remove(self.nodes_to_draw)
            if entry then
                self.state.current_x = entry[2].current_x
                self.state.current_y = entry[2].current_y
            end
            self.state.typed_characters = self.state.typed_characters + 1
        end
        return
    end

    if node.command == "typo_select" then
        if not dry then
            local count = node.arguments[1]
            local first_entry = self.nodes_to_draw[#self.nodes_to_draw - count + 1]
            if first_entry then
                local font = self:getFont()
                local font_scale = Assets.getFontScale(self.state.font, self.state.font_size)
                self.typo_selection = {
                    x = first_entry[2].current_x,
                    y = first_entry[2].current_y,
                    w = self.state.current_x - first_entry[2].current_x,
                    h = font:getHeight() * font_scale,
                }
            end
        end
        return
    end
end

function DialogueText:processNode(node, dry)
    local before = #self.nodes_to_draw
    super.processNode(self, node, dry)

    if dry or node.type ~= "character" then
        return
    end
    if #self.nodes_to_draw <= before or node.character == " " then
        return
    end

    local state = self.nodes_to_draw[#self.nodes_to_draw][2]
    local indent_char = StringUtils.sub(state.indent_string, 1, 1)
    if node.character == indent_char and not self.include_asterisk then
        return
    end

    self:animateChar(state)
end

function DialogueText:resetState()
    super.resetState(self)
    self.state.text_style = self.text_style
end

function DialogueText:rewriteTypoCommands(text)
    local typos = {}
    if not text:find("[typo:", 1, true) then
        return text, typos
    end

    local out = {}
    local pos = 1

    while true do
        local start = text:find("[typo:", pos, true)
        if not start then
            break
        end

        local close = text:find("]", start, true)
        local escaped = start > 1 and text:sub(start - 1, start - 1) == "\\"

        if escaped or not close then
            table.insert(out, text:sub(pos, start + 5))
            pos = start + 6
        else
            table.insert(out, text:sub(pos, start - 1))

            local body = text:sub(start + 6, close - 1)
            local comma = body:find(",", 1, true)
            local wrong = comma and body:sub(1, comma - 1) or body
            local right = comma and body:sub(comma + 1) or ""

            local keep = 0
            if comma and self.typo_partial_erase then
                local wrong_len, right_len = StringUtils.len(wrong), StringUtils.len(right)
                while
                    keep < wrong_len
                    and keep < right_len
                    and StringUtils.sub(wrong, keep + 1, keep + 1) == StringUtils.sub(right, keep + 1, keep + 1)
                do
                    keep = keep + 1
                end
            end

            local mistake = self.random_typos and "" or StringUtils.sub(wrong, keep + 1)
            if mistake == "" then
                table.insert(out, right)
            else
                table.insert(typos, mistake)
                local flag = keep > 0 and ",partial" or ""
                table.insert(
                    out,
                    StringUtils.sub(right, 1, keep)
                        .. "[typo:"
                        .. #typos
                        .. flag
                        .. "]"
                        .. StringUtils.sub(right, keep + 1)
                )
            end

            pos = close + 1
        end
    end

    table.insert(out, text:sub(pos))
    return table.concat(out), typos
end

function DialogueText:setText(text, advance_callback, line_callback)
    self.typo_selection = nil
    self.cursor_idle_start = nil
    self.cursor_finish_time = nil
    super.setText(self, text, advance_callback, line_callback)
end

function DialogueText:textToNodes(input_string)
    local typos
    input_string, typos = self:rewriteTypoCommands(input_string)

    local nodes, display_text = super.textToNodes(self, input_string)
    if self:typosEnabled() then
        nodes = self:insertTypos(nodes)
    end
    nodes = self:expandTypoCommands(nodes, typos)

    return nodes, display_text
end

function DialogueText:typosEnabled()
    return self.random_typos and self.typo_chance > 0
end

return DialogueText
