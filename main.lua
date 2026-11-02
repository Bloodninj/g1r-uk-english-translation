-- english_uk: a translation of the game into English (UK).
--
-- Nothing here is translated yet.  Every table under lang/ starts with
-- empty strings; fill one in and it takes effect on the next boot, and
-- anything still empty keeps rendering in English.  That means a
-- half-finished translation is always playable, so you can ship early and
-- fill the long tail in later.
--
-- Read TRANSLATING.md before the first edit; the font is the part people
-- get wrong.
return function(mod)
  -- mod:read is the supported way into your own directory; the catalogs are
  -- plain Lua tables, so read and run them rather than require()ing them.
  local function catalog(name)
    local rel = "lang/" .. name .. ".lua"
    local body = mod:read(rel)
    if not body then return {} end
    local chunk, err = loadstring(body, rel)
    if not chunk then
      mod.log:warn("%s has a syntax error: %s", rel, tostring(err))
      return {}
    end
    local ok, table_ = pcall(chunk)
    if not ok or type(table_) ~= "table" then
      mod.log:warn("%s did not return a table: %s", rel, tostring(table_))
      return {}
    end
    return table_
  end

  -- An empty value means "not translated yet", never "translate to blank".
  local function each(name, apply)
    local n = 0
    for key, value in pairs(catalog(name)) do
      if type(value) == "string" and value ~= "" then
        apply(key, value)
        n = n + 1
      end
    end
    return n
  end

  -- ---- glyphs -------------------------------------------------------
  -- Text rendering through the bundled Plain Pixel TTF ("Plain Pixel
  -- Font" by Douglas Vautour (Burpy Fresh), CC-BY 4.0 -- see
  -- assets/fonts/plainpixel/README.md).  Registered, it replaces the tile
  -- font for ordinary characters, so a translation needs no glyph sheet
  -- at all; box borders and <PK>-style macros keep their tiles.  Options:
  -- { file = mod.assets:path("myfont.ttf"), size = 15, spacing = 0,
  --   yOffset = -6, bold = true } -- size is the font's design em (Plain
  -- Pixel only rasterizes cleanly at multiples of 15), bold thickens a
  -- 1px-stroke font that reads too light.
  -- mod.content.font:register("ttf", {})

  -- Register the sheet BEFORE anything asks for a glyph on it.  base is
  -- the first code the page owns; 0x100 and up is free space above the
  -- vanilla pages, so a new alphabet never collides with them.
--   for id, page in pairs(catalog("font")) do
--     mod.content.font:register(id, page)
--   end
--   -- charmap: which byte sequence draws which code
--   for seq, code in pairs(catalog("charmap")) do
--     mod.content.font:register("charmap:" .. seq, { seq = seq, code = code })
--   end

  -- ---- text ---------------------------------------------------------
  local counts = {}

  local gameGen = 1
  local gameVer = "red"
  local okV, GameVersion = pcall(require, "src.core.GameVersion")
  if okV and GameVersion and GameVersion.generation and GameVersion.get then
    gameGen = GameVersion.generation()
    gameVer = GameVersion.get()
  end

  counts.dialogue = each("text", function(id, value)
    mod.content.text:override(id, value)
  end)
  -- counts.strings = each("strings", function(source, value)
  --   mod.content.strings:override(source, value)
  -- end)
  -- counts.species = each("species_names", function(id, value)
  --   mod.content.pokemon:patch(id, { name = value })
  -- end)
  -- counts.moves = each("move_names", function(id, value)
  --   mod.content.moves:patch(id, { name = value })
  -- end)

  -- Item names
  counts.items = each("item_names", function(id, value)
    mod.content.items:patch(id, { name = value })
  end)

  -- Item descriptions
  if gameGen == 2 then
    mod.log:info("translating gen 2 rom_text")
      counts.items = each("rom_text_gen2", function(id, value)
      local ok, err = mod.content.rom_text:override(id, value)
      if not ok then mod.log:error("English (UK): %s", err) end
    end)
    mod.log:info("translating gen 2 Pokédex entries")
      counts.items = each("pokedex_gen2", function(id, value)
      local ok, err = mod.content.pokemon:patch(id, value)
      if not ok then mod.log:error("English (UK): %s", err) end
    end)
    mod.log:info("translating gen 2 item descriptions")
    counts.items = each("item_descriptions_gen2", function(id, value)
      local ok, err = mod.content.items:patch(id, { description = value })
      if not ok then mod.log:error("English (UK): %s", err) end
    end)
    mod.log:info("translating gen 2 moves names")
    counts.items = each("move_names_gen2", function(id, value)
      local ok, err = mod.content.moves:patch(id, { name = value })
      if not ok then mod.log:error("English (UK): %s", err) end
    end)
    mod.log:info("translating gen 2 move descriptions")
      counts.items = each("move_descriptions_gen2", function(id, value)
      local ok, err = mod.content.moves:patch(id, { description = value })
      if not ok then mod.log:error("English (UK): %s", err) end
    end)
  elseif gameGen == 3 then
    if gameVer == "ruby" or gameVer == "sapphire" or gameVer == "emerald" then
      mod.log:info("translating RSE item descriptions")
      counts.items = each("item_descriptions_rse", function(id, value)
        local ok, err = mod.content.items:patch(id, { description = value })
        if not ok then mod.log:error("English (UK): %s", err) end
      end)
    elseif gameVer == "firered" or gameVer == "leafgreen" then
      mod.log:info("translating FRLG item descriptions")
      counts.items = each("item_descriptions_frlg", function(id, value)
        local ok, err = mod.content.items:patch(id, { description = value })
        if not ok then mod.log:error("English (UK): %s", err) end
      end)
    end
  end

-- TODO: Find out how to change floor names to match UK standard
-- mod.log:info("patching floor names")
-- -- attempt to change floor names
-- local ok, err = mod.events:patch("floorNames", {
--   ["1F"] = "G"
-- })
-- if not ok then
--   mod.log:error("Error patching floorNames: %s", err)
-- end


  -- counts.trainers = each("trainer_names", function(id, value)
  --   mod.content.trainers:patch(id, { name = value })
  -- end)
  -- counts.statuses = each("status_labels", function(id, value)
  --   mod.content.statuses:patch(id, { label = value })
  -- end)

  -- ---- name entry ---------------------------------------------------
  -- The naming screen's letter grid.  Leave lang/naming.lua returning nil
  -- to keep the English alphabet.
  local grid = catalog("naming")
  if grid.upper then
    mod.hooks:on("ui.naming.grid", function(base, ctx)
      local want = ctx.lower and grid.lower or grid.upper
      return want or base
    end)
  end

  mod.events:on("game.ready", function()
    local total = 0
    for _, n in pairs(counts) do total = total + n end
    mod.log:info("English (UK): %d total strings translated", total)
  end)
end
