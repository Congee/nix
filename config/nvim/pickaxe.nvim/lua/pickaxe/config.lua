local M = {}

--- @class pickaxe.Config
M.defaults = {
  --- @type string|false  Normal-mode trigger for :Pickaxe. false leaves mapping to the user / lazy `keys`.
  keymap = false,
  --- @type string[]  Extra args forwarded to `git blame` (rename/copy/whitespace detection).
  blame_args = { '-w', '-M', '-C', '-C' },
  --- @type string  Repo-relative path honored when present (e.g. .git-blame-ignore-revs).
  ignore_revs_file = '.git-blame-ignore-revs',
  --- @type string  Float window border style.
  border = 'rounded',
  --- @type integer  Max popup width (clamped to the editor).
  width = 92,
  --- @type integer  Max popup height (clamped to the editor).
  height = 34,
  --- @type integer  Truncate the embedded commit diff past this many lines.
  max_diff_lines = 180,
  --- @type boolean  Show the commit diff by default.
  show_diff = true,
  --- @type string  os.date() format for commit timestamps.
  date_format = '%c',
}

--- @type pickaxe.Config
M.options = vim.deepcopy(M.defaults)

--- @param opts pickaxe.Config?
--- @return pickaxe.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
  return M.options
end

return M
