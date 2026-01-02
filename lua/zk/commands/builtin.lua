local zk = require("zk")
local api = require("zk.api")
local util = require("zk.util")
local commands = require("zk.commands")

commands.add("ZkIndex", zk.index)

commands.add("ZkNew", function(options)
  options = options or {}

  if options.inline == true then
    options.inline = nil
    options.dryRun = true
    options.insertContentAtLocation = util.get_lsp_location_from_caret()
  end

  zk.new(options)
end)

commands.add("ZkNewFromTitleSelection", function(options)
  local location = util.get_lsp_location_from_selection()
  local selected_text = util.get_selected_text()
  assert(selected_text ~= nil, "No selected text")

  options = options or {}
  options.title = selected_text

  if options.inline == true then
    options.inline = nil
    options.dryRun = true
    options.insertContentAtLocation = location
  else
    options.insertLinkAtLocation = location
  end

  zk.new(options)
end, { needs_selection = true })

commands.add("ZkNewFromContentSelection", function(options)
  local location = util.get_lsp_location_from_selection()
  local selected_text = util.get_selected_text()
  assert(selected_text ~= nil, "No selected text")

  options = options or {}
  options.content = selected_text

  if options.inline == true then
    options.inline = nil
    options.dryRun = true
    options.insertContentAtLocation = location
  else
    options.insertLinkAtLocation = location
  end

  zk.new(options)
end, { needs_selection = true })

commands.add("ZkCd", zk.cd)

commands.add("ZkNotes", function(options)
  zk.edit(options, { title = "Zk Notes" })
end)

commands.add("ZkBuffers", function(options)
  local hrefs = util.get_buffer_paths()
  options = vim.tbl_extend("force", { hrefs = hrefs }, options or {})
  zk.edit(options, { title = "Zk Buffers" })
end)

commands.add("ZkBacklinks", function(options)
  options = vim.tbl_extend("force", { linkTo = { vim.api.nvim_buf_get_name(0) } }, options or {})
  zk.edit(options, { title = "Zk Backlinks" })
end)

commands.add("ZkLinks", function(options)
  options = vim.tbl_extend("force", { linkedBy = { vim.api.nvim_buf_get_name(0) } }, options or {})
  zk.edit(options, { title = "Zk Links" })
end)

local function insert_link(selected, opts)
  opts = vim.tbl_extend("force", {}, opts or {})

  local location = util.get_lsp_location_from_selection()
  local selected_text = ""

  if not selected then
    location = util.get_lsp_location_from_caret()
  else
    selected_text = util.get_selected_text()
    if opts["matchSelected"] then
      opts = vim.tbl_extend("force", { match = { selected_text } }, opts or {})
    end
  end

  zk.pick_notes(opts, { title = "Zk Insert link", multi_select = false }, function(note)
    assert(note ~= nil, "Picker failed before link insertion: note is nil")

    local link_opts = {}

    if selected and selected_text ~= nil then
      link_opts.title = selected_text
    end

    api.link(note.path, location, nil, link_opts, function(err, res)
      if not res then
        error(err)
      end
    end)
  end)
end

commands.add("ZkInsertLink", function(opts)
  insert_link(false, opts)
end, { title = "Insert Zk link" })
commands.add("ZkInsertLinkAtSelection", function(opts)
  insert_link(true, opts)
end, { title = "Insert Zk link", needs_selection = true })

commands.add("ZkMatch", function(options)
  local selected_text = util.get_selected_text()
  assert(selected_text ~= nil, "No selected text")
  options = vim.tbl_extend("force", { match = { selected_text } }, options or {})
  zk.edit(options, { title = "Zk Notes matching " .. vim.inspect(selected_text) })
end, { needs_selection = true })

commands.add("ZkTags", function(options)
  zk.pick_tags(options, { title = "Zk Tags" }, function(tags)
    tags = vim.tbl_map(function(v)
      return v.name
    end, tags)
    options = vim.tbl_extend("keep", { tags = tags }, options or {})
    zk.edit(options, { title = "Zk Notes for tag(s) " .. vim.inspect(tags) })
  end)
end)

commands.add("ZkTagsSort", function(options)
  options = options or {}

  local tag_sort_options = {}
  local edit_sort_options = {}
  if options.sort ~= nil and vim.tbl_contains(options.sort, "note-count") then
    if #options.sort == 1 then
      tag_sort_options = options.sort
    else
      for _, v in ipairs(options.sort) do
        if v == "note-count" then
          table.insert(tag_sort_options, v)
        else
          table.insert(edit_sort_options, v)
        end
      end
    end
  end

  local tag_options = vim.tbl_extend("force", options, { sort = tag_sort_options })
  zk.pick_tags(tag_options, { title = "Zk Tags" }, function(tags)
    tags = vim.tbl_map(function(v)
      return v.name
    end, tags)

    local edit_options = vim.tbl_extend("force", options, { tags = tags, sort = edit_sort_options })
    print(vim.inspect(edit_options))
    zk.edit(edit_options, { title = "Zk Notes for tag(s) " .. vim.inspect(tags) })
  end)
end)
