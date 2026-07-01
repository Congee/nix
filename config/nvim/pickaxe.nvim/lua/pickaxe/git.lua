local config = require('pickaxe.config')

local M = {}

--- @class pickaxe.Entry
--- @field root string            Repository top-level.
--- @field rev string|nil         Revision the blame was taken at (nil = working tree).
--- @field hash string            Commit that introduced the blamed line.
--- @field orig_line integer      Line number in `hash`'s version of the file.
--- @field final_line integer     Line number in the blamed revision.
--- @field filename string        Path of the file as of `hash`.
--- @field previous_rev string|nil  Parent commit reported by blame porcelain.
--- @field previous_file string|nil Path in the parent commit (follows renames).
--- @field author string|nil
--- @field author_mail string|nil
--- @field author_time integer|nil
--- @field author_tz string|nil    Git tz offset (e.g. "-0500") for author_time.
--- @field committer string|nil
--- @field committer_mail string|nil
--- @field committer_time integer|nil
--- @field committer_tz string|nil Git tz offset for committer_time.
--- @field summary string|nil     First line of the commit message.
--- @field text string|nil        The blamed source line.
--- @field _older pickaxe.Entry|nil     Memoized older entry (see older_entry).
--- @field _older_resolved boolean|nil  Whether _older has been computed yet.
--- @field _body string[]|nil           Memoized commit body (see commit_body).
--- @field _diff string[]|nil           Memoized commit diff (see commit_diff).

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'pickaxe' })
end

--- Turn a completed git result into stdout|nil, notifying on failure.
--- @param args string[]
--- @param result vim.SystemCompleted
--- @param quiet boolean|nil
--- @return string|nil stdout
local function handle_result(args, result, quiet)
  if result.code ~= 0 then
    if not quiet then
      local err = vim.trim(result.stderr or '')
      M.notify(err ~= '' and err or table.concat(args, ' ') .. ' failed', vim.log.levels.WARN)
    end
    return nil
  end
  return result.stdout or ''
end

--- Run a git command synchronously.
--- @param args string[]
--- @param opts { cwd?: string, quiet?: boolean, stdin?: string }?
--- @return string|nil stdout, vim.SystemCompleted result
local function system(args, opts)
  opts = opts or {}
  local result = vim.system(args, { cwd = opts.cwd, text = true, stdin = opts.stdin }):wait()
  return handle_result(args, result, opts.quiet), result
end
M.system = system

--- Run a git command asynchronously; `on_done(stdout|nil)` runs on the main loop.
--- @param args string[]
--- @param opts { cwd?: string, quiet?: boolean }?
--- @param on_done fun(stdout: string|nil)
local function system_async(args, opts, on_done)
  opts = opts or {}
  vim.system(args, { cwd = opts.cwd, text = true }, function(result)
    vim.schedule(function()
      on_done(handle_result(args, result, opts.quiet))
    end)
  end)
end

--- @param file string  Absolute path to a buffer file.
--- @return string|nil  Repository top-level, or nil if not in a repo.
function M.git_root(file)
  local dir = vim.fn.fnamemodify(file, ':h')
  local out = system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' }, { quiet = true })
  if not out then
    M.notify('Not inside a git repository', vim.log.levels.WARN)
    return nil
  end
  return vim.trim(out)
end

--- @param root string
--- @param file string
--- @return string  Path relative to `root`, or `file` unchanged if outside.
function M.relpath(root, file)
  local full = vim.fn.fnamemodify(file, ':p')
  root = vim.fn.fnamemodify(root, ':p'):gsub('/$', '')
  if full:sub(1, #root + 1) == root .. '/' then
    return full:sub(#root + 2)
  end
  return file
end

--- @param args string[]
--- @param root string
local function add_ignore_revs(args, root)
  local ignore = root .. '/' .. config.options.ignore_revs_file
  local uv = vim.uv or vim.loop
  if uv.fs_stat(ignore) then
    table.insert(args, '--ignore-revs-file')
    table.insert(args, config.options.ignore_revs_file)
  end
end

--- Decode git's C-style quoted path. With core.quotePath on (the default) git
--- wraps paths containing special or non-ASCII bytes in double quotes and escapes
--- them (\\, \", \t … and octal \NNN per byte). Plain paths pass through unchanged.
--- @param path string
--- @return string
local function unquote_path(path)
  if path:sub(1, 1) ~= '"' then
    return path
  end
  local inner = path:sub(2, -2)
  local out, i, n = {}, 1, #inner
  local simple = { a = '\a', b = '\b', f = '\f', n = '\n', r = '\r', t = '\t', v = '\v', ['"'] = '"', ['\\'] = '\\' }
  while i <= n do
    local c = inner:sub(i, i)
    if c ~= '\\' then
      out[#out + 1] = c
      i = i + 1
    else
      local oct = inner:match('^[0-7][0-7]?[0-7]?', i + 1)
      local nxt = inner:sub(i + 1, i + 1)
      if oct then
        out[#out + 1] = string.char(tonumber(oct, 8) % 256)
        i = i + 1 + #oct
      elseif simple[nxt] then
        out[#out + 1] = simple[nxt]
        i = i + 2
      else
        out[#out + 1] = nxt ~= '' and nxt or '\\'
        i = i + 2
      end
    end
  end
  return table.concat(out)
end

--- @param out string
--- @param root string
--- @param fallback_file string
--- @param rev string|nil
--- @return pickaxe.Entry|nil
local function parse_blame_porcelain(out, root, fallback_file, rev)
  local lines = vim.split(out or '', '\n', { plain = true })
  local header = lines[1] or ''
  local hash, orig_line, final_line = header:match('^(%x+)%s+(%d+)%s+(%d+)')
  if not hash then
    return nil
  end

  --- @type pickaxe.Entry
  local entry = {
    root = root,
    rev = rev,
    hash = hash,
    orig_line = tonumber(orig_line),
    final_line = tonumber(final_line),
    filename = fallback_file,
  }

  for _, line in ipairs(lines) do
    if line:sub(1, 1) == '\t' then
      entry.text = line:sub(2)
      break
    end
    local key, value = line:match('^([%w-]+)%s+(.+)$')
    if key == 'filename' then
      entry.filename = unquote_path(value)
    elseif key == 'previous' then
      local prev_rev, prev_file = value:match('^(%x+)%s+(.+)$')
      entry.previous_rev = prev_rev
      entry.previous_file = prev_file and unquote_path(prev_file)
    elseif key == 'author' then
      entry.author = value
    elseif key == 'author-mail' then
      entry.author_mail = value:gsub('^<', ''):gsub('>$', '')
    elseif key == 'author-time' then
      entry.author_time = tonumber(value)
    elseif key == 'author-tz' then
      entry.author_tz = value
    elseif key == 'committer' then
      entry.committer = value
    elseif key == 'committer-mail' then
      entry.committer_mail = value:gsub('^<', ''):gsub('>$', '')
    elseif key == 'committer-time' then
      entry.committer_time = tonumber(value)
    elseif key == 'committer-tz' then
      entry.committer_tz = value
    elseif key == 'summary' then
      entry.summary = value
    end
  end

  return entry
end

--- @param root string
--- @param rev string|nil
--- @param file string
--- @param line integer
--- @param contents string|nil  Buffer contents to blame via `--contents -`.
--- @return string[]
local function blame_args(root, rev, file, line, contents)
  local args = { 'git', '-C', root, 'blame', '--line-porcelain' }
  vim.list_extend(args, config.options.blame_args)
  add_ignore_revs(args, root)
  table.insert(args, '-L')
  table.insert(args, tostring(line) .. ',+1')
  if rev then
    table.insert(args, rev)
  elseif contents then
    -- Blame the (unsaved) buffer contents rather than the on-disk file, so line
    -- numbers track the live buffer and uncommitted edits read as "not committed".
    table.insert(args, '--contents')
    table.insert(args, '-')
  end
  table.insert(args, '--')
  table.insert(args, file)
  return args
end

--- Blame a single line at a given revision.
--- @param root string
--- @param rev string|nil
--- @param file string
--- @param line integer
--- @param quiet boolean|nil
--- @param contents string|nil  Buffer contents to blame instead of the working tree (rev=nil only).
--- @return pickaxe.Entry|nil
function M.blame_at(root, rev, file, line, quiet, contents)
  local out = system(blame_args(root, rev, file, line, contents), { quiet = quiet, stdin = contents })
  if not out then
    return nil
  end
  return parse_blame_porcelain(out, root, file, rev)
end

--- Async variant of blame_at for history traversal (no buffer contents).
--- @param on_done fun(entry: pickaxe.Entry|nil)
local function blame_at_async(root, rev, file, line, quiet, on_done)
  system_async(blame_args(root, rev, file, line, nil), { quiet = quiet }, function(out)
    on_done(out and parse_blame_porcelain(out, root, file, rev) or nil)
  end)
end

--- Step one commit older in the blame stack, following renames/refactors.
---
--- Primary path blames the parent (`<hash>^`) at the introducing line; when the
--- file was renamed in `hash` that parent path is gone, so we fall back to the
--- `previous` rev/file reported by blame porcelain. This is what makes the stack
--- survive moves that plain blame would dead-end on.
---
--- The result is memoized on the entry (shared with older_entry_async), so the
--- "is there older history?" probe and the actual navigation step blame once.
--- @param entry pickaxe.Entry
--- @return pickaxe.Entry|nil
function M.older_entry(entry)
  if entry._older_resolved then
    return entry._older
  end
  local next_entry = M.blame_at(entry.root, entry.hash .. '^', entry.filename, entry.orig_line, true)
  if not next_entry and entry.previous_rev and entry.previous_file then
    next_entry = M.blame_at(entry.root, entry.previous_rev, entry.previous_file, entry.orig_line, true)
  end
  entry._older = next_entry
  entry._older_resolved = true
  return next_entry
end

--- Async older_entry: fills the same memo in the background and calls
--- `on_done(older|nil)` on the main loop (synchronously if already resolved).
--- Lets the popup prefetch the next commit without blocking the UI thread.
--- @param entry pickaxe.Entry
--- @param on_done fun(older: pickaxe.Entry|nil)
function M.older_entry_async(entry, on_done)
  if entry._older_resolved then
    on_done(entry._older)
    return
  end
  local function settle(next_entry)
    entry._older = next_entry
    entry._older_resolved = true
    on_done(next_entry)
  end
  blame_at_async(entry.root, entry.hash .. '^', entry.filename, entry.orig_line, true, function(parent)
    if parent then
      settle(parent)
    elseif entry.previous_rev and entry.previous_file then
      blame_at_async(entry.root, entry.previous_rev, entry.previous_file, entry.orig_line, true, settle)
    else
      settle(nil)
    end
  end)
end

--- Cached older-history check that never triggers a blame: true/false once the
--- memo is resolved, or nil while still unknown (the async prefetch resolves it).
--- Drives the History counter without blocking the first paint.
--- @param entry pickaxe.Entry
--- @return boolean|nil
function M.has_older_cached(entry)
  if not M.is_committed(entry) then
    return false
  end
  if entry._older_resolved then
    return entry._older ~= nil
  end
  return nil
end

--- @param entry pickaxe.Entry
--- @return boolean  Whether the line is committed (not the all-zero working-tree hash).
function M.is_committed(entry)
  return entry.hash ~= nil and not entry.hash:match('^0+$')
end

--- @param entry pickaxe.Entry
--- @return string[]
local function body_args(entry)
  return { 'git', '-C', entry.root, 'show', '--no-patch', '--format=%b', entry.hash }
end

--- @param out string|nil
--- @return string[]
local function parse_body(out)
  if not out then
    return {}
  end
  local body = vim.split(vim.trim(out), '\n', { plain = true })
  if #body == 1 and body[1] == '' then
    return {}
  end
  return body
end

--- @param entry pickaxe.Entry
--- @param scoped boolean  Limit the diff to entry.filename.
--- @return string[]
local function diff_args(entry, scoped)
  local args = {
    'git', '-C', entry.root, 'show', '--format=', '--no-ext-diff',
    '--find-renames', '--find-copies', '--patch', entry.hash,
  }
  if scoped then
    table.insert(args, '--')
    table.insert(args, entry.filename)
  end
  return args
end

--- @param out string|nil
--- @return string[]
local function parse_diff(out)
  if not out then
    return {}
  end
  local lines = vim.split(out, '\n', { plain = true })
  local limit = config.options.max_diff_lines
  if #lines > limit then
    local truncated = {}
    for i = 1, limit do
      truncated[i] = lines[i]
    end
    truncated[#truncated + 1] = ('… diff truncated after %d lines'):format(limit)
    return truncated
  end
  return lines
end

--- Commit body (message minus the summary line), memoized on the entry.
--- @param entry pickaxe.Entry
--- @return string[]
function M.commit_body(entry)
  if entry._body then
    return entry._body
  end
  if not M.is_committed(entry) then
    entry._body = {}
    return entry._body
  end
  entry._body = parse_body(system(body_args(entry), { quiet = true }))
  return entry._body
end

--- Async commit_body; fills the same memo and calls on_done() when ready.
--- @param entry pickaxe.Entry
--- @param on_done fun()
function M.commit_body_async(entry, on_done)
  if entry._body or not M.is_committed(entry) then
    entry._body = entry._body or {}
    on_done()
    return
  end
  system_async(body_args(entry), { quiet = true }, function(out)
    entry._body = parse_body(out)
    on_done()
  end)
end

--- Unified diff for this commit, scoped to the file when possible, memoized.
--- @param entry pickaxe.Entry
--- @return string[]
function M.commit_diff(entry)
  if entry._diff then
    return entry._diff
  end
  if not M.is_committed(entry) then
    entry._diff = {}
    return entry._diff
  end
  local out = system(diff_args(entry, true), { quiet = true })
  if not out or vim.trim(out) == '' then
    out = system(diff_args(entry, false), { quiet = true })
  end
  entry._diff = parse_diff(out)
  return entry._diff
end

--- Async commit_diff; fills the same memo and calls on_done() when ready.
--- @param entry pickaxe.Entry
--- @param on_done fun()
function M.commit_diff_async(entry, on_done)
  if entry._diff or not M.is_committed(entry) then
    entry._diff = entry._diff or {}
    on_done()
    return
  end
  system_async(diff_args(entry, true), { quiet = true }, function(out)
    if out and vim.trim(out) ~= '' then
      entry._diff = parse_diff(out)
      on_done()
      return
    end
    system_async(diff_args(entry, false), { quiet = true }, function(out2)
      entry._diff = parse_diff(out2)
      on_done()
    end)
  end)
end

--- Prefetch an entry's body and diff in the background so stepping to it renders
--- instantly. `on_done` (optional) fires once both memos are warm.
--- @param entry pickaxe.Entry
--- @param on_done fun()|nil
function M.load_details_async(entry, on_done)
  local pending = 2
  local function tick()
    pending = pending - 1
    if pending == 0 and on_done then
      on_done()
    end
  end
  M.commit_body_async(entry, tick)
  M.commit_diff_async(entry, tick)
end

--- Pickaxe search: every commit that changed the number of occurrences of the
--- given text within the file's history. The escape hatch for history plain
--- blame can't follow. Scoping to `path` keeps a common line (e.g. `end`) from
--- dredging up unrelated hits across every file in every ref.
--- @param root string
--- @param text string|nil
--- @param path string|nil  Repo-relative path to scope the search to.
--- @return string[]|nil lines, string|nil needle
function M.pickaxe_log(root, text, path)
  local needle = vim.trim(text or '')
  if needle == '' then
    return nil, nil
  end
  local args = {
    'git', '-C', root, 'log', '--all', '--reverse',
    '--date=short', '--format=%h %ad %an %s', '-S', needle,
  }
  if path then
    table.insert(args, '--')
    table.insert(args, path)
  end
  local out = system(args)
  if not out then
    return nil, needle
  end
  return vim.split(vim.trim(out), '\n', { plain = true }), needle
end

return M
