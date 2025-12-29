local u = {}
---@param func function
---@param tname string
---@return any, integer?
function u.upvfind(func, tname)
  local i = 1
  while true do
    local name, value = debug.getupvalue(func, i)
    if not name then break end
    if name == tname then return value, i end
    i = i + 1
  end
  return nil
end

---START INJECT hlv.lua

local M = {}
local api, fn = vim.api, vim.fn

local group = 'u.hlv'
local ns = api.nvim_create_namespace(group)
local last_curswant, id ---@type integer?, integer?
local maxcol = vim.v.maxcol
local last_view ---@type vim.fn.winsaveview.ret?

local block_width = function(pos1, pos2)
  local left = math.min(pos1[3] + pos1[4], pos2[3] + pos2[4])
  return fn.max(fn.map(fn.range(pos1[2], pos2[2]), "col([v:val, '$'])")) - left
end

local hlv = function() -- TODO: https://github.com/vim/vim/issues/18888
  local pos1, pos2 = fn.getpos("'<"), fn.getpos("'>")
  local visualmode = fn.visualmode()
  local width = visualmode == '\022' and last_curswant == maxcol and block_width(pos1, pos2) or ''
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

---@param lnum integer
local hll = function(lnum)
  last_view = last_view or fn.winsaveview()
  lnum = math.min(lnum, api.nvim_buf_line_count(0))
  pcall(api.nvim_win_set_cursor, 0, { lnum, 0 })
  local opts = { end_line = lnum, hl_group = 'Visual', hl_eol = true }
  pcall(api.nvim_buf_set_extmark, 0, ns, lnum - 1, 0, opts)
end

M.hlv = hlv

local parse_range = function(cmd) -- TODO: https://github.com/neovim/neovim/pull/36665
  local res = vim.F.npcall(api.nvim_parse_cmd, cmd, {})
    or vim.F.npcall(api.nvim_parse_cmd, cmd .. 'a', {})
  return res and res.range or nil
end

local hl_callback = function(ev, ...)
  ---@type CmdContent, any, string
  local content, _, firstc, _ = ...
  if ev == 'cmdline_show' and firstc == ':' then
    local cmd = vim.iter(content):map(function(chunk) return chunk[2] end):join('')
    pcall(api.nvim_buf_clear_namespace, 0, ns, 0, -1)
    local lnum = tonumber(cmd:match('^%s*(%d+)%s*$')) ---@as integer?
    if lnum then return hll(lnum) end
    if last_view then pcall(fn.winrestview, last_view) end
    if cmd:match('^%s*%%') then return end
    if cmd:match("^%s*'<%s*,%s*'>%s*") or cmd:match('^%s*%*%s*$') then
      hlv()
    else
      hlr(parse_range(cmd))
    end
  end
end

---@return boolean
local has_ui2 = function()
  return vim.F.npcall(
    function() return (next(api.nvim_get_autocmds({ group = 'nvim._ext_ui' }))) end
  ) and true or false
end

---@type function?, function?, integer?
local ui2_enable, ui_callback, i

function M.enable()
  if not has_ui2() then return end
  ui2_enable = vim.F.npcall(function() return require('vim._extui').enable end)
  if not ui2_enable then return end
  ui_callback, i = u.upvfind(ui2_enable, 'ui_callback')
  if not ui_callback or not i then return end
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
  debug.setupvalue(ui2_enable, i, function(...)
    hl_callback(...)
    ui_callback(...)
  end)
  api.nvim_create_autocmd('CmdlineLeave', {
    group = group,
    callback = function(ev)
      if last_view then
        pcall(fn.winrestview, last_view)
        if not vim.v.event.abort then vim.cmd('norm! m`') end
      end
      last_view = nil
      pcall(api.nvim_buf_clear_namespace, ev.buf, ns, 0, -1)
    end,
  })
end

M.enable = vim.schedule_wrap(M.enable)

function M.disable()
  pcall(api.nvim_del_augroup_by_name, group)
  if ui2_enable and i and ui_callback then debug.setupvalue(ui2_enable, i, ui_callback) end
end

return M
