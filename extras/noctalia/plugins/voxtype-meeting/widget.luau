--!nonstrict
-- Voxtype meeting widget
--
-- Meeting status doesn't get printed in voxtype status command, so query
-- $XDG_RUNTIME_DIR/voxtype/meeting_state

local STATES = {
  idle = {
    glyph = noctalia.getConfig("idle_glyph") or "friends-off",
    color = noctalia.getConfig("idle_color") or "on_surface",
    tooltip = "Voxtype meeting - None active",
  },
  paused = {
    glyph = noctalia.getConfig("paused_glyph") or "friends",
    color = noctalia.getConfig("paused_color") or "error",
    tooltip = "Paused",
  },
  recording = {
    glyph = noctalia.getConfig("recording_glyph") or "friends",
    color = noctalia.getConfig("recording_color") or "error",
    tooltip = "Active",
  },
}

local function meeting_info(id)
  local process = noctalia.exec("voxtype meeting status", { id or "latest" })
end

local function render(name, id)
  local state = STATES[name]
  if state == nil then
    noctalia.log("voxtype: ignored unknown meeting state " .. tostring(name))
    return
  end

  barWidget.setGlyph(state.glyph)
  barWidget.setGlyphColor(state.color)

  if name ~= "idle" then
    local process = noctalia.runAsync({ "voxtype", "meeting", "show", id or "latest" }, function(result)
        -- Meeting title
        -- =============
        --
        -- ID:       9cc4ad66-8292-42e6-8f30-727445fcac16
        -- Started:  2026-10-07 02:13 UTC
        -- Status:   Active
        -- Chunks:   0
        --
        -- Transcript:
        -- -----------
        -- Segments: 0
        -- Words:    0
        -- Speakers:
      local lines = {}
      for line in result.stdout:gmatch("[^\r\n]+") do
          lines[#lines + 1] = line
      end
      local title = lines[1]
      local started = lines[4]
      local finalTooltip = "Voxtype meeting - " .. state.tooltip .. "\n" .. title .. "\n" ..  started
      barWidget.setTooltip(finalTooltip)
    end)
  else
      barWidget.setTooltip(state.tooltip)
  end
end

function update()
  local xdgRuntime = noctalia.getenv("XDG_RUNTIME_DIR")
  local command = "cat " .. xdgRuntime .. "/voxtype/meeting_state;"
  local filePath = xdgRuntime .. "/voxtype/meeting_state"

  -- meeting_state gets updated on state change with `status\nmeeting_id`
  local process = noctalia.runAsync({ "cat", filePath }, function(result)
      local status = {}
      for line in result.stdout:gmatch("[^\r\n]+") do
          table.insert(status, line)
      end

      local name = status[1]
      local meetingId = status[2]

      if name then
          render(name, meetingId)
      end
  end)
end

-- Use the configured idle appearance while waiting for the command's initial
-- status line.
barWidget.setGlyph(STATES.idle.glyph)
barWidget.setGlyphColor(STATES.idle.color)
barWidget.setText("")
barWidget.setTooltip(noctalia.tr("widget.waiting"))

if not noctalia.commandExists("voxtype") then
  barWidget.setGlyph("friends-off")
  barWidget.setGlyphColor("error")
  barWidget.setTooltip(noctalia.tr("widget.unavailable"))
else
    noctalia.setUpdateInterval(2000)
end
