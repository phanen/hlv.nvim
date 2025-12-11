local api, fn = vim.api, vim.fn
---START INJECT hlv.lua

local M = {}

local group = 'u.hlv'
local ns = api.nvim_create_namespace(group)
local last_curswant, id ---@type integer?, integer?
local maxcol = vim.v.maxcol

local block_width = function(pos1, pos2)
  local left = math.min(pos1[3] + pos1[4], pos2[3] + pos2[4])
  return fn.max(fn.map(fn.range(pos1[2], pos2[2]), "col([v:val, '$'])")) - left
end

local hlv = function() -- TODO: https://github.com/vim/vim/issues/18888
  local pos1, pos2 = fn.getpos("'<"), fn.getpos("'>")
  local visualmode = fn.visualmode()
  local width = last_curswant == maxcol and block_width(pos1, pos2) or ''
  vim._with(
    { wo = { ve = 'all' } },
    function()
      vim.hl.range(0, ns, 'Visual', "'<", "'>", {
        regtype = visualmode .. width,
        inclusive = vim.o.sel:sub(1, 1) ~= 'e',
      })
    end
  )
end

local hlr = function(range) -- TODO: char/block/mark https://github.com/neovim/neovim/issues/22297
  if not range or not range[1] or not range[2] then return end
  vim.hl.range(0, ns, 'Visual', { range[1] - 1, 0 }, { range[2] - 1, 0 }, { regtype = 'V' })
end

M.hlv = hlv

local parse_range = function(cmd) -- TODO: https://github.com/neovim/neovim/pull/36665
  local res = vim.F.npcall(api.nvim_parse_cmd, cmd, {})
    or vim.F.npcall(api.nvim_parse_cmd, cmd .. 'a', {})
  return res and res.range or nil
end

function M.enable()
  api.nvim_create_augroup(group, { clear = true })
  api.nvim_create_autocmd('ModeChanged', {
    group = group,
    pattern = { '\022:*', '*:\022' },
    callback = function(ev)
      local leave = ev.match:sub(1, 1) == '\022'
      if id then
        pcall(api.nvim_del_autocmd, id)
        id = nil
      end
      if leave then return end
      id = api.nvim_create_autocmd('CursorMoved', {
        group = group,
        callback = function()
          if fn.mode() == '\22' then last_curswant = fn.getcurpos()[5] end
        end,
      })
    end,
  })
  api.nvim_create_autocmd({ 'CmdlineChanged' }, {
    group = group,
    callback = function(ev)
      pcall(api.nvim_buf_clear_namespace, ev.buf, ns, 0, -1)
      local cmd = fn.getcmdline()
      if cmd:match("^%s*'<%s*,%s*'>%s*") then
        hlv()
      else
        hlr(parse_range(cmd))
      end
    end,
  })
  api.nvim_create_autocmd('CmdlineLeave', {
    group = group,
    callback = function(ev) pcall(api.nvim_buf_clear_namespace, ev.buf, ns, 0, -1) end,
  })
end

function M.disable() pcall(api.nvim_del_augroup_by_name, group) end

return M
