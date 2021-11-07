-- SPDX-FileCopyrightText: 2021 Michael Weimann <mail@michael-weimann.eu>
--
-- SPDX-License-Identifier: MIT

local telescope = require("telescope")
local pickers = require "telescope.pickers"
local sorters = require('telescope.sorters')
local conf = require('telescope.config').values
local make_entry = require('telescope.make_entry')
local finders = require "telescope.finders"

local parse_prompt = function(prompt)
  local prev_was_space = true
  local prev_was_quote = false
  local in_group = false
  local group_delimiter = ""
  local group = ""
  local parts = {}

  for c in prompt:gmatch"." do
    local is_quote

    if (in_group) then
      is_quote = c == group_delimiter
    else
      is_quote = c == '"' or c == "'"

      if (is_quote) then
        group_delimiter = c
      end
    end

    local is_space = c == " "

    if (is_space and prev_was_space and not in_group) then
      -- skip consecutive spaces
      goto endfor
    end

    if (prev_was_space == true and is_quote) then
      in_group = true
      group_delimiter = c
      goto endfor
    end

    if (in_group and prev_was_quote and is_space) then
      -- close group
      table.insert(parts, string.sub(group, 0, string.len(group) - 1))
      group = ""
      in_group = false
      group_delimiter = ""
      goto endfor
    end

    if (is_space and not in_group) then
      table.insert(parts, group)
      group = ""
      goto endfor
    end

    group = group .. c

    ::endfor::
    prev_was_space = is_space
    prev_was_quote = is_quote
  end

  if (in_group) then
    table.insert(parts, string.sub(group, 0, string.len(group) - 1))
  else
    table.insert(parts, group)
  end

  return parts
end

local tbl_clone = function(original)
  local copy = {}
  for key, value in pairs(original) do
    copy[key] = value
  end
  return copy
end

local grep_highlighter_only = function(opts)
  return sorters.Sorter:new {
    scoring_function = function() return 0 end,

    highlighter = function(_, prompt, display)
      return {}
    end,
  }
end

local live_grep_raw = function(opts)
  opts = opts or {}

  opts.vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd)

  local cmd_generator = function(prompt)
    if not prompt or prompt == "" then
      return nil
    end

    local args = tbl_clone(opts.vimgrep_arguments)
    local prompt_parts = parse_prompt(prompt)

    local cmd = vim.tbl_flatten { args, prompt_parts }
    return cmd
  end

  pickers.new(opts, {
    prompt_title = 'Live Grep Raw',
    finder = finders.new_job(cmd_generator, opts.entry_maker, opts.max_results, opts.cwd),
    previewer = conf.grep_previewer(opts),
    sorter = grep_highlighter_only(opts),
  }):find()
end

return telescope.register_extension {
  exports = { live_grep_raw = live_grep_raw },
}
