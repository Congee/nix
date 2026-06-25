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
--- @field committer string|nil
--- @field committer_mail string|nil
--- @field committer_time integer|nil
--- @field summary string|nil     First line of the commit message.
--- @field text string|nil        The blamed source line.
--- @field _older pickaxe.Entry|nil     Memoized older entry (see older_entry).
--- @field _older_resolved boolean|nil  Whether _older has been computed yet.

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'pickaxe' })
end

--- Run a git command synchronously.
--- @param args string[]
--- @param opts { cwd?: string, quiet?: boolean }?
--- @return string|nil stdout, vim.SystemCompleted result
local function system(args, opts)
  opts = opts or {}
  local result = vim.system(args, { cwd = opts.cwd, text = true }):wait()
  if result.code ~= 0 then
    if not opts.quiet then
      local err = vim.trim(result.stderr or '')
      M.notify(err ~= '' and err or table.concat(args, ' ') .. ' failed', vim.log.levels.WARN)
    end
    return nil, result
  end
  return result.stdout or '', result
end
M.system = system

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
      entry.filename = value
    elseif key == 'previous' then
      local prev_rev, prev_file = value:match('^(%x+)%s+(.+)$')
      entry.previous_rev = prev_rev
      entry.previous_file = prev_file
    elseif key == 'author' then
      entry.author = value
    elseif key == 'author-mail' then
      entry.author_mail = value:gsub('^<', ''):gsub('>$', '')
    elseif key == 'author-time' then
      entry.author_time = tonumber(value)
    elseif key == 'committer' then
      entry.committer = value
    elseif key == 'committer-mail' then
      entry.committer_mail = value:gsub('^<', ''):gsub('>$', '')
    elseif key == 'committer-time' then
      entry.committer_time = tonumber(value)
    elseif key == 'summary' then
      entry.summary = value
    end
  end

  return entry
end

--- Blame a single line at a given revision.
--- @param root string
--- @param rev string|nil
--- @param file string
--- @param line integer
--- @param quiet boolean|nil
--- @return pickaxe.Entry|nil
function M.blame_at(root, rev, file, line, quiet)
  local args = { 'git', '-C', root, 'blame', '--line-porcelain' }
  vim.list_extend(args, config.options.blame_args)
  add_ignore_revs(args, root)
  table.insert(args, '-L')
  table.insert(args, tostring(line) .. ',+1')
  if rev then
    table.insert(args, rev)
  end
  table.insert(args, '--')
  table.insert(args, file)

  local out = system(args, { quiet = quiet })
  if not out then
    return nil
  end
  return parse_blame_porcelain(out, root, file, rev)
end

--- Step one commit older in the blame stack, following renames/refactors.
---
--- Primary path blames the parent (`<hash>^`) at the introducing line; when the
--- file was renamed in `hash` that parent path is gone, so we fall back to the
--- `previous` rev/file reported by blame porcelain. This is what makes the stack
--- survive moves that plain blame would dead-end on.
---
--- The result is memoized on the entry, so the cheap "is there older history?"
--- probe (M.has_older) and the actual navigation step share a single blame.
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

--- Whether older history is reachable from `entry`. Reuses older_entry's memo,
--- so probing on the first screen costs the same single blame that stepping
--- older would — letting the History counter appear when history has depth.
--- @param entry pickaxe.Entry
--- @return boolean
function M.has_older(entry)
  return M.is_committed(entry) and M.older_entry(entry) ~= nil
end

--- @param entry pickaxe.Entry
--- @return boolean  Whether the line is committed (not the all-zero working-tree hash).
function M.is_committed(entry)
  return entry.hash ~= nil and not entry.hash:match('^0+$')
end

--- @param entry pickaxe.Entry
--- @return string[]  Commit body (message minus the summary line).
function M.commit_body(entry)
  if not M.is_committed(entry) then
    return {}
  end
  local out = system({
    'git', '-C', entry.root, 'show', '--no-patch', '--date=iso-strict',
    '--format=%b', entry.hash,
  }, { quiet = true })
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
--- @return string[]  Unified diff for this commit, scoped to the file when possible.
function M.commit_diff(entry)
  if not M.is_committed(entry) then
    return {}
  end
  local path = entry.filename
  local out = system({
    'git', '-C', entry.root, 'show', '--format=', '--no-ext-diff',
    '--find-renames', '--find-copies', '--patch', entry.hash, '--', path,
  }, { quiet = true })
  if not out or vim.trim(out) == '' then
    out = system({
      'git', '-C', entry.root, 'show', '--format=', '--no-ext-diff',
      '--find-renames', '--find-copies', '--patch', entry.hash,
    }, { quiet = true })
  end
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

--- Pickaxe search: every commit that changed the number of occurrences of the
--- given text. The escape hatch for history plain blame can't follow.
--- @param root string
--- @param text string|nil
--- @return string[]|nil lines, string|nil needle
function M.pickaxe_log(root, text)
  local needle = vim.trim(text or '')
  if needle == '' then
    return nil, nil
  end
  local out = system({
    'git', '-C', root, 'log', '--all', '--reverse',
    '--date=short', '--format=%h %ad %an %s', '-S', needle,
  })
  if not out then
    return nil, needle
  end
  return vim.split(vim.trim(out), '\n', { plain = true }), needle
end

return M
