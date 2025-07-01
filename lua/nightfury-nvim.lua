local M = {}

-- local unistd = require("posix.unistd");
local socket = require("posix.sys.socket")
local json = require("deps.json")

local night_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM, 0)
local knownCapabilities = {}

local xdgrtd = os.getenv("XDG_RUNTIME_DIR") or ("/run/user/" .. os.getenv("EUID"))
local conn_res = socket.connect(night_socket, { family = socket.AF_UNIX, path = xdgrtd .. "/nightfury.sock" })
if conn_res ~= 0 then
  print("xdgrtd: " .. xdgrtd)
  print("Couldn't connect: " .. tostring(conn_res))
  return nil
end

local function read_until_null()
  local ret = ""
  local tmp = socket.recv(night_socket, 1)
  while tmp ~= "\0" do
    ret = ret .. tmp
    tmp = socket.recv(night_socket, 1)
  end
  if type(tmp) == "string" and tmp ~= "\0" then
    print("Error while reading: " .. tmp)
    return nil
  end
  return ret
end

function M.getCapabilities()
  local msg = "\"GetCapabilities\"\0"
  if socket.send(night_socket, msg) ~= 18 then
    print("Couldn't send message!")
  end

  local res = read_until_null()
  if res then
    knownCapabilities = json.decode(res).Capabilities
  end
  return res
end

local function contains(table, val)
  for i = 1, #table do
    if table[i] == val then
      return true
    end
  end
  return false
end

local function buf_attach(buf)
  vim.api.nvim_buf_attach(buf, true, {
    on_bytes = function(_, bufnr, changedtick, start_row, start_col, start_byte, old_end_row, old_end_col, old_end_byte,
                        new_end_row, new_end_col, new_end_byte)
      -- if contains(knownCapabilities, vim.bo.filetype) then
      print(start_row .. "," .. new_end_row .. "," .. start_byte .. "," .. new_end_byte)
      if new_end_byte < 1 then
        return nil
      end
      local lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, start_row + new_end_row,
        start_col + new_end_col, {})
      for i = 1, #lines do
        print(lines[i])
      end
      -- end
    end
  })
end

vim.api.nvim_create_autocmd({ "BufAdd" }, {
  callback = function(args)
    print("Added buffer!")
    buf_attach(args.buf)
  end
})



return M
