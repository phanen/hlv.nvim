local api, fn = vim.api, vim.fn
---START INJECT hlv.lua

local group = 'u.hlv'

local M = {}

local ns = api.nvim_create_namespace('visual_range_highlight')

local hlv = function() -- TODO: https://github.com/vim/vim/issues/18888
  local pos1, pos2 = fn.getpos("'<"), fn.getpos("'>")
  local max_col1 = fn.col({ pos1[2], '$' })
  pos1[3] = math.min(pos1[3], max_col1)
  local max_col2 = fn.col({ pos2[2], '$' })
  pos2[3] = math.min(pos2[3], max_col2)
  local visualmode = fn.visualmode()
  local width = (pos1[3] >= max_col2 or pos2[3] >= max_col2)
      and visualmode == '\022'
      and fn.max(fn.map(fn.range(pos1[2], pos2[2]), "col([v:val, '$'])")) - math.abs(
        pos1[3] - pos2[3]
      )
    or ''
  local _, _ = vim.hl.range(0, ns, 'Visual', "'<", "'>", {
    regtype = fn.visualmode() .. width,
    inclusive = vim.o.sel:sub(1, 1) ~= 'e',
  })
end

function M.enable()
  api.nvim_create_augroup(group, { clear = true })
  api.nvim_create_autocmd({ 'CmdlineEnter', 'CmdlineChanged' }, {
    group = group,
    callback = function(ev)
      pcall(api.nvim_buf_clear_namespace, ev.buf, ns, 0, -1)
      if fn.getcmdline():match("^'%<,'>") then hlv() end
    end,
  })
  api.nvim_create_autocmd('CmdlineLeave', {
    group = group,
    callback = function(ev) pcall(api.nvim_buf_clear_namespace, ev.buf, ns, 0, -1) end,
  })
end

function M.disable() pcall(api.nvim_del_augroup_by_name, group) end

return M
