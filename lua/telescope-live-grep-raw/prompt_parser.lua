local M = {}

M.parse = function(prompt)
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

return M
