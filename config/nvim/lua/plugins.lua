-- capturing upvalues
-- https://github.com/wbthomason/packer.nvim/issues/1001#issuecomment-1206609769

--- @param id string
--- @param what "'fg'" | "'bg'"
--- @param mode "'gui'" | "'cterm'" | "'term'"
--- @return string
_G.hiof = function(id, what, mode)
  return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(id)), what, mode)
end

--- @generic K, V
--- @param tbl table<K, V>
--- @return K[]
_G.keys = function(tbl)
  local ks = {}
  for k, _ in pairs(tbl) do
    ks[#ks + 1] = k
  end
  return ks;
end

--- @generic K, V
--- @param tbl table<K, V>
--- @return V[]
_G.values = function(tbl)
  local vals = {}
  for _, v in pairs(tbl) do
    vals[#vals + 1] = v;
  end
  return vals
end

--- @generic T
--- @param object T
--- @return T
_G.trace = function(object)
  local inspect = require('inspect')
  print(inspect(object));
  return object
end

---Pretty print lua table
function _G.dump(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  assert(objects ~= nil)
  print(table.unpack(objects))
end

if _VERSION == "Lua 5.1" or _VERSION == "LuaJIT" then
  ---@diagnostic disable: deprecated
  table.unpack = unpack
end

--- @generic T
--- @param x T
--- @return T
function _G.id(x) return x end

-- Use nvim-treesitter instead of vim-polyglot for:
-- filetype => module
_G.treesitter_ft_mod = {
  cmake           = 'cmake',
  comment         = 'comment',
  css             = 'css',
  ejs             = 'embedded_template',
  gitattributes   = 'gitattributes',
  haskell         = 'haskell',
  hcl             = 'hcl',
  helm            = 'helm',
  html            = 'html',
  -- lua             = 'lua',
  nix             = 'nix',
  proto           = 'proto',
  python          = 'python',
  regex           = 'regex',
  sql             = 'sql',
  toml            = 'toml',
  typescript      = 'typescript',
  vim             = 'vim',
  vue             = 'vue',
  yaml            = 'yaml',
  zig             = 'zig',
  markdown        = 'markdown',
  markdown_inline = 'markdown_inline',
};

--- @module 'lazy'
--- @type LazySpec
return {
  {
    'tamton-aquib/duck.nvim',
    lazy = true,
    event = 'VeryLazy',
    config = function()
      vim.api.nvim_create_user_command('Duck', function() require("duck").hatch() end, {})
      vim.api.nvim_create_user_command('DuckCook', function() require("duck").cook() end, {})
      vim.api.nvim_create_user_command('DuckCookAll', function() require("duck").cook_all() end, {})
    end
  },
  -- {
  --     'glacambre/firenvim',
  --     config = function()
  --         vim.g.firenvim_config = {
  --             globalSettings = {
  --                 alt = 'all',
  --             },
  --             localSettings = {
  --                 ['.*'] = {
  --                     takeover = 'never',
  --                     priority = 0,
  --                 },
  --                 ['https?:..leetcode.com.*'] = {
  --                     selector = 'div.ReactCodeMirror div.CodeMirror textarea:not([readonly])',
  --                     filename = '/tmp/{hostname}_{pathname%32}.{extension}',
  --                     takeover = 'always',
  --                     priority = 1,
  --                 }
  --             }
  --         }
  --         vim.cmd [[au BufEnter leetcode.com_* set guifont=monospace:h16]] -- no longer italic
  --     end,
  --     build = function() vim.fn['firenvim#install'](0) end,
  --     lazy = true,
  --     event = 'VeryLazy',
  -- },
  {
    'lukas-reineke/indent-blankline.nvim',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = function()
      require('ibl').setup();
      vim.g.indent_blankline_filetype_exclude = { 'help', 'neo-tree' }
      vim.g.indent_blankline_char = '│';

      -- Actually need something like the freground color of the text
      vim.cmd([[autocmd ColorScheme hi IndentBlanklineChar guifg=synIDattr(synIDtrans(hlID('Normal')), 'fg', 'gui')]])
    end,
    lazy = true,
    event = "ColorScheme",
  },
  {
    -- basically `hi Normal guibg=none` but with more hl groups
    'xiyaowong/transparent.nvim',
    config = function()
      require("transparent").setup({
        extra_groups = {
          "NeoTreeNormal",
          "NeoTreeNormalNC",
        }
      })
    end,
    lazy = true,
    event = 'UIEnter',
  },
  {
    "EdenEast/nightfox.nvim",
    -- "olivercederborg/poimandres.nvim",
    -- "nyoom-engineering/oxocarbon.nvim",
    lazy = true,
    event = 'VeryLazy',
    config = vim.schedule_wrap(function()
      vim.cmd [[colorscheme carbonfox]]
      vim.cmd [[hi Operator gui=None ]] -- no longer italic

      -- make indent area contrast
      vim.o.guicursor = table.concat({
        'n-v-c:block',
        'i-ci-ve:hor100',
        'r-cr:hor20',
        'o:hor50',
        'a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor',
        'sm:block-blinkwait175-blinkoff150-blinkon175',
      }, ',');
      vim.cmd [[hi Cursor guifg=NONE guibg=NONE gui=nocombine ]]
    end),
    enabled = function() return vim.fn.has('mac') == 1 end,
  },
  {
    'olimorris/onedarkpro.nvim',
    event = 'VeryLazy',
    config = vim.schedule_wrap(function()
      local onedarkpro = require('onedarkpro')
      local colors = require('onedarkpro.helpers').get_colors()
      onedarkpro.setup({
        options = { transparency = true },
        hlgroups = {
          Normal = { fg = '#abb2bf' },
          DiffAdd = { fg = 'green', bg = 'NONE' },
          DiffDelete = { fg = 'red', bg = 'NONE' },
          DiffChange = { fg = '#d2a8ff', bg = 'NONE' },
          diffChanged = { fg = '#d2a8ff', bg = 'NONE' },
          CocFloating = { link = 'Pmenu' }, -- originally NormalFloat
          -- CocUnusedHighlight -> CocFadeOut -> Conceal
          CocUnusedHighlight = { fg = colors.gray, bg = 'NONE' },
          CocInfoSign = { fg = 'LightBlue' },
          CocHintSign = { fg = colors.cyan },
        },
      })
      vim.cmd [[autocmd ColorScheme * ++once hi diffChanged guifg=#61afef]]
      vim.cmd [[colorscheme onedark ]]
      vim.cmd [[hi Operator gui=None ]] -- no longer italic
      vim.cmd [[hi @variable guifg=clear ]]

      -- make indent area contrast
      vim.o.guicursor = table.concat({
        'n-v-c:block',
        'i-ci-ve:hor100',
        'r-cr:hor20',
        'o:hor50',
        'a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor',
        'sm:block-blinkwait175-blinkoff150-blinkon175',
      }, ',');
      vim.cmd [[hi Cursor guifg=NONE guibg=NONE gui=nocombine ]]
    end),
    enabled = function() return vim.fn.has('linux') == 1 end,
  },

  {
    'rhysd/clever-f.vim', -- leap.nvim is clunky
    lazy = true,
    event = 'VeryLazy',
    config = function()
      vim.g.clever_f_across_no_line = 1
      vim.g.clever_f_not_overwrites_standard_mappings = 1
      -- make it work with macros
      local check = function(ch)
        local rec = vim.fn.reg_recording() .. vim.fn.reg_executing() == ""
        return rec and ("<Plug>(clever-f-" .. ch .. ")") or ch
      end

      local opts = { silent = true, remap = true, expr = true }
      vim.keymap.set('n', 'f', function() return check('f') end, opts)
      vim.keymap.set('n', 'F', function() return check('F') end, opts)
      vim.keymap.set('n', 't', function() return check('t') end, opts)
      vim.keymap.set('n', 'T', function() return check('T') end, opts)
      vim.cmd [[
        map ;     <Plug>(clever-f-repeat-forward)
        map <M-,> <Plug>(clever-f-repeat-back)
      ]]
    end
  },

  {
    'qxxxb/vim-searchhi',
    lazy = true,
    event = 'VeryLazy',
  },
  {
    "dmtrKovalenko/fff.nvim",
    dependencies = { 'assistcontrol/readline.nvim' },
    -- build = "nix run .#release",
    opts = {},
    keys = {
      {
        "<C-P>", -- try it if you didn't it is a banger keybinding for a picker
        function()
          require("fff").find_files() -- or find_in_git_root() if you only want git files
          local keys = {
            ["<c-k>"] = function() require('readline').kill_line() end,
            ["<c-f>"] = '<Right>',
            ["<a-f>"] = function() require('readline').forward_word() end,
            ["<a-d>"] = function() require('readline').kill_word() end,
            ["<c-d>"] = '<Delete>',
            ["<c-b>"] = '<Left>',
            ["<c-a>"] = function() require('readline').beginning_of_line() end,
            ["<c-u>"] = function() require('readline').backward_kill_line() end,
          };
          local buf = require('fff.picker_ui').state.input_buf;
          local opts = { buffer = buf, noremap = true, silent = true };
          for key, action in pairs(keys) do
            vim.keymap.set('i', key, action, opts)
          end
        end,
        desc = "Open file picker",
      },
    },
  },
  {
    "folke/snacks.nvim",
    dependencies = {
      'assistcontrol/readline.nvim',
    },
    --- @module 'snacks'
    --- @type snacks.Config
    opts = {
      image = { doc = { inline = false } },
      picker = {
        enabled = true,
        layout = {
          preset = 'telescope',
        },
        win = {
          input = {
            keys = {
              ["<c-k>"] = function() require('readline').kill_line() end,
              ["<c-f>"] = { '<Right>', expr = true, mode = { 'i' } },
              ["<a-f>"] = function() require('readline').forward_word() end,
              ["<a-d>"] = function() require('readline').kill_word() end,
              ["<c-d>"] = { '<Delete>', expr = true, mode = { 'i' } },
              ["<c-b>"] = { '<Left>', expr = true, mode = { 'i' } },
              ["<c-a>"] = function() require('readline').beginning_of_line() end,
              ["<c-u>"] = function() require('readline').backward_kill_line() end,
            }
          }
        },
      },
    },
    keys = {
      -- goodby 'gennaro-tedesco/nvim-peekup',
      { '""', function() Snacks.picker.registers() end, desc = "Registers" },
      -- { '<C-P>', function() Snacks.picker.smart() end, desc = "Smart Find Files" },
      { [[<C-\>]], function() Snacks.picker() end, desc = "Snacks Picker" },
      { '<LocalLeader>d', function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { '<Leader>/', function() Snacks.picker.grep() end, desc = "Live Grep" },
    },
  },
  {
    'pwntester/octo.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'folke/snacks.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    --- @module 'octo'
    --- @type OctoConfig
    --- @diagnostic disable-next-line: missing-fields
    opts = {
      default_to_projects_v2 = true,
      picker = 'snacks',
    },
    lazy = true,
    event = 'VeryLazy',
  },
  { 'rafcamlet/nvim-luapad',                    lazy = true,   ft = "lua" },

  {
    'folke/todo-comments.nvim',
    lazy = true,
    event = 'VeryLazy',
    config = function()
      require('todo-comments').setup {
        highlight = { keyword = "bg", multiline = true }
      }
      vim.cmd [[syntax keyword Todo contained NOTE NOTES]] -- w/o treesitter
    end
  },
  {
    "folke/ts-comments.nvim", -- No block comment gbc. Comment.nvim supports it
    opts = {},
    event = "VeryLazy",
  },
  {
    'kylechui/nvim-surround',
    opts = {},
    lazy = true,
    event = "VeryLazy",
  },
  {
    'junegunn/vim-easy-align',
    config = function()
      vim.cmd [[
        xmap ga <Plug>(EasyAlign)
        nmap ga <Plug>(EasyAlign)
      ]]
      -- https://github.com/junegunn/vim-easy-align?tab=readme-ov-file#ignoring-delimiters-in-comments-or-strings
      vim.g.easy_align_ignore_groups = {};
    end,
    lazy = true,
    event = "VeryLazy",
  },

  -- See also
  -- https://github.com/AckslD/nvim-trevJ.lua
  -- https://github.com/aarondiel/spread.nvim
  -- https://github.com/AndrewRadev/splitjoin.vim
  {
    'FooSoft/vim-argwrap',
    config = function() vim.g.argwrap_tail_comma = 1 end,
    lazy = true,
    cmd = 'ArgWrap',
  },

  {
    'stevearc/conform.nvim',
    cmd = { "ConformInfo" },
    keys = {
      {
        -- Customize or remove this keymap to your liking
        "<leader>ft",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    --- @module 'conform'
    --- @type conform.setupOpts
    opts = {
      default_format_opts = { lsp_format = 'prefer', },
      formatters_by_ft = {
        lua = { "stylua" },
        vue = { "prettierd", "prettier" },
        javascript = { 'clang_format' },
        typescript = { 'prettierd', 'prettier' },
        python = { 'isort' },
        yaml = { command = 'yamlfmt', args = { '-i', '-n' } },
        ["*"] = { "trim_whitespace" },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          vim.api.nvim_set_option_value("formatexpr", "v:lua.require'conform'.formatexpr({'timeout_ms': 1000})", { buf = args.buf })
        end
      });
    end,
    lazy = true,
    event = { "BufWritePre" },
  },

  {
    'iamcco/markdown-preview.nvim',
    ft = { 'markdown' },
    build = 'cd app && yarn install',
    cmd = 'MarkdownPreview',
    config = function()
      vim.g.mkdp_open_ip = 'localhost'
      -- To debug
      -- vim.env.NVIM_MKDP_LOG_FILE = '/tmp/mkdp.log'
      -- vim.env.NVIM_MKDP_LOG_LEVEL = 'debug'

      -- wsl2
      if vim.fn.has('wsl') == 1 then
        vim.cmd([[
            function! g:OpenBrowser(url)
              silent exe '!/mnt/c/Windows/System32/cmd.exe /c start' a:url
            endfunction
        ]]);
        vim.g.mkdp_browserfunc = 'g:OpenBrowser'
      end
    end
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    --- @module 'render-markdown'
    --- @type render.md.Config
    --- @diagnostic disable: missing-fields
    opts = {
      completions = { blink = { enabled = true } },
      image = {},
    },
    --- @diagnostic enable: missing-fields
  },
  {
    'obsidian-nvim/obsidian.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      ui = { enable = false },  -- render-markdown.nvim instaed
      workspaces = {
        {
          name = "Obsidian",
          path = "~/OneDrive/Apps/remotely-save/Obsidian",
        },
      },
      attachments = {
        img_folder = "~/assets/images",
      },
      legacy_commands = false,
      open = { use_advanced_uri = true },
      completion = { nvim_cmp = false },
      picker = { name = 'snacks.pick' },
    };
    ft = "markdown",
  },
  {
    'assistcontrol/readline.nvim',
    config = function()
      local readline = require 'readline'
      vim.keymap.set('!', '<C-k>', readline.kill_line)
      vim.keymap.set('!', '<C-u>', readline.backward_kill_line)
      vim.keymap.set('!', '<M-d>', readline.kill_word)
      vim.keymap.set('!', '<M-BS>', readline.unix_word_rubout)
      vim.keymap.set('!', '<C-w>', readline.backward_kill_word)
      vim.keymap.set('!', '<C-d>', '<Delete>')  -- delete-char
      vim.keymap.set('!', '<C-h>', '<BS>')      -- backward-delete-char
      vim.keymap.set('!', '<C-a>', readline.beginning_of_line)
      vim.keymap.set('!', '<C-e>', readline.end_of_line)
      vim.keymap.set('!', '<M-f>', readline.forward_word)
      vim.keymap.set('!', '<M-b>', readline.backward_word)
      vim.keymap.set('!', '<C-f>', '<Right>') -- forward-char
      vim.keymap.set('!', '<C-b>', '<Left>')  -- backward-char
    end,
    lazy = true,
    event = 'VeryLazy',
  },
  {
    'chrisbra/unicode.vim',
    lazy = true,
    event = 'VeryLazy',
  },
  {
    'tpope/vim-dadbod', -- for SQL. TODO: help exrc
    dependencies = 'kristijanhusak/vim-dadbod-ui',
    lazy = true,
    cmd = "DB",
  },
  {
    'dhruvasagar/vim-table-mode',
    lazy = true,
    event = 'VeryLazy',
  },
  {
    'linrongbin16/gitlinker.nvim',
    lazy = true,
    event = 'VeryLazy',
    opts = {},
  },
  {
    'rhysd/git-messenger.vim',
    keys = { '<leader>gm', '<cmd>GitMessenger<cr>' },
    config = function() vim.g.git_messenger_include_diff = "current" end
  },

  -- use 'jbyuki/instant.nvim'  -- coediting

  -- https://github.com/rhysd/conflict-marker.vim
  -- https://github.com/akinsho/git-conflict.nvim
  {
    'rhysd/conflict-marker.vim',
    lazy = true,
    event = 'VeryLazy',
    config = function()
      vim.g.conflict_marker_enable_highlight = 0;
      vim.g.conflict_marker_enable_matchit = 1;
      vim.g.conflict_marker_enable_mappings = 0;
    end,
    keys = {
      {
        '<LocalLeader>ct',
        function() vim.cmd [[ ConflictMarkerThemselves ]] end,
        mode = 'n',
        desc = "ConflictMarkerThemselves",
      },
      {
        '<LocalLeader>co',
        function() vim.cmd [[ ConflictMarkerOurselves ]] end,
        mode = 'n',
        desc = "ConflictMarkerOurselves",
      },
      {
        '<LocalLeader>cb',
        function() vim.cmd [[ ConflictMarkerBoth ]] end,
        mode = 'n',
        desc = "ConflictMarkerBoth",
      },
      {
        '<LocalLeader>cn',
        function() vim.cmd [[ ConflictMarkerNone ]] end,
        mode = 'n',
        desc = "ConflictMarkerNone",
      },
    },
  },
  {
    'tpope/vim-fugitive',
    lazy = true,
    event = "VeryLazy",
  },
  {
    'cohama/agit.vim',
    lazy = true,
    cmd = 'Agit',
  },

  -- The default netrw#BrowseX() is broken. It always opens `file:///...` in
  -- vim despite netrw#CheckIfRemote() returns 1.
  --
  -- So may be xdg-open.
  -- xdg-open uses both Chromium and Firefox🤷, and it does not care about
  -- fragments in a url.
  {
    'tyru/open-browser.vim',
    lazy = true,
    event = 'VeryLazy',
    config = function()
      vim.g.netrw_nogx = 1
      if vim.fn.has('linux') == 1 then
        vim.g.openbrowser_browser_commands = {
          { name = "firefox",       args = { "{browser}", "{uri}" } },
          { name = "xdg-open",      args = { "{browser}", "{uri}" } },
          { name = "x-www-browser", args = { "{browser}", "{uri}" } },
          { name = "w3m",           args = { "{browser}", "{uri}" } },
        }
      end
      vim.cmd [[ nmap gx <Plug>(openbrowser-smart-search) ]]
      vim.cmd [[ vmap gx <Plug>(openbrowser-smart-search) ]]
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    --- @module 'gitsigns'
    --- @type Gitsigns.Config
    --- @diagnostic disable-next-line: missing-fields
    opts = {
      -- Options passed to nvim_open_win
      preview_config = {
        border = 'none',
        style = 'minimal',
        relative = 'cursor',
      },
      on_attach = function(bufnr)
        --- @module 'gitsigns'
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({']c', bang = true})
          else
            gs.nav_hunk('next', { navigation_message = false })
          end
        end)

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({'[c', bang = true})
          else
            gs.nav_hunk('prev', { navigation_message = false })
          end
        end)

        -- self:ensure_file_in_index() is called too early
        -- https://github.com/lewis6991/gitsigns.nvim/blob/c3070fcc2e7da1798041219fde8d88f2e4bf7eb5/lua/gitsigns/git.lua#L178
        vim.api.nvim_create_autocmd('User', {
          pattern = 'GitSignsChanged',
          callback = function(args)
            vim.cmd('silent write');
            vim.schedule(function() vim.system({ 'git', 'diff', '--no-ext-diff', '--quiet', '--', args.data.file }) end);
          end,
        })

        -- Actions
        map('n', '<leader>hs', gs.stage_hunk)
        map('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')}; end)
        map('n', '<leader>hr', gs.reset_hunk)
        map('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
        map('n', '<leader>hS', gs.stage_buffer)
        map('n', '<leader>hu', gs.undo_stage_hunk)
        map('n', '<leader>hR', gs.reset_buffer)
        map('n', '<leader>hp', gs.preview_hunk_inline)
        map('n', '<leader>hb', function() gs.blame_line { full = true } end)
        map('n', '<leader>tb', gs.toggle_current_line_blame)
        map('n', '<leader>hd', gs.diffthis)
        map('n', '<leader>hD', function() gs.diffthis('~') end)
        map('n', '<leader>td', gs.toggle_deleted)

        -- Text object
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
      end
    },
    --- @diagnostic enable: missing-fields
    lazy = true,
    event = "UIEnter",
  },
  {
    -- 'johmsalas/text-case.nvim',
    'chiedo/vim-case-convert',
    lazy = true,
    event = "VeryLazy",
  },
  {
    'gyim/vim-boxdraw',
    lazy = true,
    event = "VeryLazy",
  },
  {
    'SirVer/ultisnips', -- TODO: try LuaSnip + cmp_luasnip
    dependencies = { 'honza/vim-snippets' },
    config = function()
      vim.g.UltiSnipsListSnippets        = "<c-tab>"
      vim.g.UltiSnipsJumpForwardTrigger  = "<tab>"
      vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"
      vim.g.snips_author                 = "Congee"
    end,
    lazy = true,
    event = "VeryLazy",
  },

  {
    'neomake/neomake',
    config = function()
      vim.g.neomake_cmake_maker = {
        name = 'cmake',
        exe = 'cmake',
        args = { '--build' },
        append_file = 0
      }
      vim.g.neomake_cpp_enabled_makers = { 'cmake', 'makeprg' }
    end,
    ft = { 'python', 'cpp', 'typescript', 'rust' },
    lazy = true,
  },
  { -- or 'stevearc/overseer.nvim'
    'skywind3000/asyncrun.vim',
    enabled = false,
    lazy = true,
    event = "VeryLazy",
  },
  {
    'mattn/emmet-vim',
    enabled = false,
    ft = { 'html', 'hbs', 'typescript', 'typescriptreact', 'vue' },
    config = function()
      vim.g.user_emmet_settings = { typescript = { extends = 'jsx' } }
    end
  },

  -- color picker
  { 'KabbAmine/vCoolor.vim', ft = { 'less', 'sass', 'css', 'typescriptreact' } },
  {
    'rhysd/vim-grammarous',  -- maybe migrate to nvim-lint
    lazy = true,
    event = "VeryLazy",
  },
  {
    'brenoprata10/nvim-highlight-colors',
    ft = {
      'css',
      'javascript',
      'typescript',
      'html',
      'less',
      'sass',
      'typescriptreact',
      'Onedarkpro',
    },
    opts = {}
  },
  -- { 'ray-x/navigator.lua' },
  {
    'oskarrrrrrr/symbols.nvim',
    dependencies = { 'onsails/lspkind.nvim' },
    lazy = true,
    event = 'VeryLazy',
    opts = { layout = { width = 20 }, },
    config = function()
      local r = require("symbols.recipes")
      require("symbols").setup(
        r.DefaultFilters,
        r.FancySymbols,
        {
          sidebar = {
            open_direction = 'right',
          }
        }
      )
      vim.keymap.set("n", "<leader>vt", "<cmd>SymbolsToggle!<CR>");
    end,
  },
  {
    'rebelot/heirline.nvim',
    enabled = true,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'olimorris/onedarkpro.nvim',
      'SmiteshP/nvim-navic',
    },
    config = function() require('statusline'); require('wezterm_bar'); end,
    event = "VeryLazy",
  },
  {
    'mrcjkb/rustaceanvim',
    -- version = '^3', -- Recommended
    ft = { 'rust' },
    dependencies = { 'mfussenegger/nvim-dap' },
    config = function()
      local exe = vim.fn.resolve(vim.fn.exepath('codelldb'))
      local dir = vim.fn.fnamemodify(exe, ':h')
      local lib = vim.fn.resolve(dir .. '/../lldb/lib/liblldb.so')
      vim.g.rustaceanvim = {
        tools = {
          hover_actions = {
            replace_builtin_hover = false,
          },
        },
        server = {
          capabilities = vim.lsp.protocol.make_client_capabilities(),
          cmd = { 'ra-multiplex'},
          settings = {
            ['rust-analyzer'] = {
              files = { excludeDirs = { ".direnv" } },
              rustfmt = {
                -- require `rustfmt` binary
                overrideCommand = { "rustfmt", "--" },
                rangeFormatting = { enable = true },
                extraArgs = { "+nightly" },
              },
              cargo = { buildScripts = { enable = true } }
            },
          },
        },
        dap = {
          -- calling require('rustaceanvim.dap') here cause recursion
          -- so, copy the code
          -- https://github.com/mrcjkb/rustaceanvim/blob/a355a08d566aaac33374e24b12009cbe0f6a5b90/lua/rustaceanvim/dap.lua#L32-L46
          adapter = {
            type = 'server',
            host = '127.0.0.1',
            port = '${port}',
            executable = {
              command = 'codelldb',
              args = { '--liblldb', lib, '--port', '${port}' }
            },
          }
        },
      }
    end
  },
  {
    "andrewferrier/debugprint.nvim",
    version = "*",
    lazy = true,
    event = 'VeryLazy',
    opts = {},
  },
  {
    'saecki/crates.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = { "BufRead Cargo.toml" },
    opts = { complete = { cmp = { enabled = true } } },
  },
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'nvim-telescope/telescope-dap.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-neotest/nvim-nio',
      'rcarriga/nvim-dap-ui',
    },
    config = function()
      -- local dap, dapui = require("dap"), require("dapui")
      -- require('telescope').load_extension('dap')
      -- dapui.setup()
      --
      -- dap.listeners.after.event_initialized["dapui_config"] = function()
      --   dapui.open()
      -- end
      -- dap.listeners.before.event_terminated["dapui_config"] = function()
      --   dapui.close()
      -- end
      -- dap.listeners.before.event_exited["dapui_config"] = function()
      --   dapui.close()
      -- end
      --
      -- vim.keymap.set('n', '<Leader>db', function() dap.toggle_breakpoint() end)
      -- vim.keymap.set('n', '<Leader>dr', function() dap.repl.open() end)
      -- vim.keymap.set('n', '<Leader>dl', function() dap.run_last() end)
      -- vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
      --   require('dap.ui.widgets').hover()
      -- end)
      -- vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
      --   require('dap.ui.widgets').preview()
      -- end)
      -- vim.keymap.set('n', '<Leader>df', function()
      --   local widgets = require('dap.ui.widgets')
      --   widgets.centered_float(widgets.frames)
      -- end)
      -- vim.keymap.set('n', '<Leader>ds', function()
      --   local widgets = require('dap.ui.widgets')
      --   widgets.centered_float(widgets.scopes)
      -- end)

    end,
    enabled = false,
    lazy = true,
    event = 'VeryLazy',
  },
  {
    'SmiteshP/nvim-navic',
    dependencies = { 'neovim/nvim-lspconfig' },
    event = 'LspAttach',
    opts = {
      lsp = {
        auto_attach = true,
        preference = { 'vue_ls' }, -- later be higher
      },
      navic_lazy_update_context = true,
    },
  },
  {
    "SmiteshP/nvim-navbuddy",
    dependencies = {
      'neovim/nvim-lspconfig',
      "SmiteshP/nvim-navic",
      "MunifTanjim/nui.nvim"
    },
    event = 'LspAttach',
    opts = { lsp = { auto_attach = true } },
  },
  {
    'j-hui/fidget.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    event = "LspAttach",
    opts = {},
  },
  {
    "folke/lazydev.nvim",
    dependencies = {
      { 'gonstoll/wezterm-types', lazy = true },
      { "Bilal2453/luvit-meta", lazy = true },
    },
    ft = "lua", -- only load on lua files
    --- @module 'lazydev'
    --- @type lazydev.Config
    --- @diagnostic disable: missing-fields
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "wezterm-types", mods = { "wezterm" } },
      },
    },
    --- @diagnostic enable: missing-fields
  },
  {
    'saghen/blink.compat',
    event = 'LspAttach',
    lazy = true,
    opts = {},
  },
  {
    'saghen/blink.cmp',
    version = '*',
    build = 'nix run .#build-plugin',
    lazy = true,
    keys = {
      {
        '<C-x><C-o>',
        function()
          require('blink.cmp').show({ providers = { 'lsp', 'snippets' } })
          require('blink.cmp').show_documentation()
          require('blink.cmp').hide_documentation()
        end,
        mode = 'i',
        desc = "Blink Complete",
      },
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      signature = { enabled = true },
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release
        use_nvim_cmp_as_default = true,
      },
      keymap = {
        preset = 'default',
        ['<C-space>'] = {},
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<C-y>'] = { 'select_and_accept', 'fallback' },
      },
      cmdline = {
        keymap = {
          preset = 'cmdline',
          ['<Tab>'] = { 'show_and_insert', 'select_next', 'fallback' },
          ['<S-Tab>'] = { 'select_prev', 'fallback' },
        }
      },
      fuzzy = {
        -- prebuilt_binaries = { download = true },
        sorts = {
          'score', 'kind', 'label',
          --- @type blink.cmp.SortFunction
          [4] = function (a, b)
            if a.client_name ~= 'lua_ls' then return nil end

            local aunderscore = a.label:find('^_') ~= nil;
            local bunderscore = b.label:find('^_') ~= nil;

            if aunderscore and not bunderscore then
              return false;
            elseif not aunderscore and bunderscore then
              return false;
            else
              return a.label < b.label
            end
          end
        },
      },
      completion = {
        list = {
          selection = {
            auto_insert = true,
            preselect = false,
          },
        },
        trigger = {
          prefetch_on_insert = true,
          show_on_keyword = false,
          show_on_trigger_character = false,
        },
        menu = {
          draw = { treesitter = { 'lsp' } },
          auto_show = false,
        },
        documentation = {
          auto_show = true,
          window = { border = 'none' },
        },
        ghost_text = { enabled = true },
      },
      sources = {
        transform_items = function(_, items)
          return vim.tbl_filter(
            function(item)
              if item.client_name == 'vtsls' then
                return item.kind ~= require("blink.cmp.types").CompletionItemKind.Property
              else
                return item end
            end,
            items
          );
        end,
        default = {
          'lazydev',
          'lsp',
          'path',
          'snippets',
          -- 'buffer',
          'crates',
          'ultisnips',
        },
        providers = {
          lsp = {
            name = 'lsp',
            module = 'blink.cmp.sources.lsp',
          },
          lazydev = {
            name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 4,
          },
          crates = {
            name = 'crates', module = 'blink.compat.source',
          },
          ultisnips = {
            name = 'ultisnips', module = 'blink.compat.source',
          },
          sshconfig = {
            name = 'sshconfig', module = 'blink.compat.source',
          },
        },
      },
    },
  },
  { 'MrcJkb/haskell-tools.nvim', ft = { "haskell" }, },
  {
    'p00f/clangd_extensions.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'nvim-lua/lsp-status.nvim' },
    event = 'VeryLazy';
    -- event = { 'BufReadPre', 'BufNewFile' },
    opts = { inlay_hints = { enabled = true } },
    config = function()

      for server, config in pairs(require('lsp.configs')) do
        -- vim.lsp.config(server, config);
        -- vim.lsp.enable(server);
        require('lspconfig')[server].setup(config)
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.definitionProvider then
            vim.api.nvim_buf_set_option(args.buf, "tagfunc", "v:lua.vim.lsp.tagfunc")
          end

          if client and client:supports_method('textDocument/documentColor') then
            vim.lsp.document_color.enable(true, args.buf, { style = 'foreground' })
          end
        end
      });

      vim.cmd 'LspStart'; -- to be VeryLazy
      require('lsp.keymaps')
    end
  },
  {
    'mfussenegger/nvim-lint',
    config = function()
      require('lint').linters_by_ft = {
        -- javascript = {'eslint_d'},
        python = {'ruff'},
      }
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function() require("lint").try_lint() end,
      })
    end,
    lazy = true,
  },
  {
    -- TODO: remove noice once https://github.com/neovim/neovim/issues/25718 is resolved
    --
    -- regarding the issue of very long output from :messages
    -- noice.nvim is too intrusive.
    -- https://github.com/neovim/neovim/pull/5189 would be btter
    'folke/noice.nvim',
    event = 'LspAttach',
    opts = {
      cmdline = { enabled = false },
      messages = { enabled = false },
      popupmenu = { enabled = false },
      notify = { enabled = false },
      smart_move = { enabled = false },
      lsp = {
        progress = { enabled = false },
        hover = { enabled = true, opts = { border = 'none' } },
        signature = { enabled = false },
        message = { enabled = false },
      }
    }
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      "s1n7ax/nvim-window-picker",
    },
    lazy = true,
    event = 'VeryLazy',
    config = function()
      require("neo-tree").setup({
        window = {
          mappings = {
            Z = "expand_all_nodes",
            h = "close_node",
            l = "open",
          }
        },
        filesystem = {
          follow_current_file = { enabled = true },
          window = {
            mappings = {
              ["[c"] = "prev_git_modified",
              ["]c"] = "next_git_modified",
            }
          }
        }
      });
      vim.g.neo_tree_remove_legacy_commands = 1
      local cmd = ':Neotree action=show toggle=true reveal <CR>'
      vim.keymap.set('n', '<Leader>e', cmd, { silent = true })
    end,
  },
  {
    'akinsho/bufferline.nvim',
    dependencies = 'folke/snacks.nvim',
    config = function()
      local sidebar = 'neo-tree';
      require('bufferline').setup {
        options = {
          show_buffer_icons = false,
          show_buffer_close_icons = false,
          show_close_icon = false,
          show_tab_indicators = false,
          separator_style = "thin",
          always_show_bufferline = false,
          offsets = {
            {
              filetype = sidebar,
              highlight = "Directory",
              text_align = "center"
            }
          },
          numbers = "none",
          left_mouse_command = function(bufnr)
            if vim.bo.filetype ~= sidebar then
              vim.cmd("buffer " .. bufnr)
            end
          end,
          middle_mouse_command = function(bufnr)
            require('snacks.bufdelete').delete(bufnr)
          end,
          right_mouse_command = function() end,
          indicator = { style = "none" },
        },
      }

      local map = function(key, bufnr)
        local fn = function()
          if vim.bo.filetype ~= sidebar then
            require('bufferline').go_to_buffer(bufnr, true)
          end
        end

        vim.keymap.set('n', key, fn, { silent = true })
      end
      map("<M-1>", 1)
      map("<M-2>", 2)
      map("<M-3>", 3)
      map("<M-4>", 4)
      map("<M-5>", 5)
      map("<M-6>", 6)
      map("<M-7>", 7)
      map("<M-8>", 8)
      map("<M-9>", 9)
      map("<M-0>", -1)

      vim.keymap.set('n', '<leader>q', function()
        if vim.bo.filetype == sidebar then
          vim.api.nvim_win_close(0, false)
        else
          require('snacks.bufdelete').delete()
        end
      end, { silent = true })
      vim.keymap.set('n', '<M-n>', ':bnext<CR>', { silent = true })
      vim.keymap.set('n', '<M-p>', ':bprev<CR>', { silent = true })
    end,
    lazy = true,
    event = 'VeryLazy',
  },
  {
    'voldikss/vim-floaterm',
    lazy = true,
    event = 'UIEnter',
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-vim-test",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim"
    },
    enabled = false,
    config = function()
      require('neotest').setup({
        adapters = {
          require('neotest-python')({}),
          require('neotest-vim-test')({
            ignore_file_types = { "python", "vim" }
          }),
        }
      });
    end,
    ft = { "python" },
  },
  { 'qvalentin/helm-ls.nvim', lazy = true, ft = 'helm', opts = {} },
  -- use 'heavenshell/vim-pydocstring', {'for': 'python'}
  { 'wookayin/semshi', build = ':UpdateRemotePlugins', lazy = true, ft = "python" },
  {
    'nvim-treesitter/nvim-treesitter',
    build = function()
      vim.env.ALL_EXTENSIONS = 1;
      vim.cmd('TSUpdate');
    end,
    config = function() require('nvim-treesitter.configs').setup({
      modules = {},
      sync_install = false,
      compilers = { "clang++", "zig" },
      ensure_installed = vim.tbl_values(_G.treesitter_ft_mod),
      auto_install = false,
      ignore_install = {'lua'},
      highlight = {
        enable = true,
        disable = { "cpp", "bash", "python", "typescript", "go", "yaml" },
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
        disable = { "python" },
      },
      incremental_selection = { enable = true },
      embedded_template = { enable = true, }
    }) end,
    lazy = true,
    event = 'UIEnter',
  },

  {
    'windwp/nvim-autopairs',
    config = function() require('nvim-autopairs').setup {}; end,
    enabled = false,
    lazy = true,
    event = 'VeryLazy',
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = function()
      --- @diagnostic disable: missing-fields
      require('nvim-treesitter.configs').setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
          swap = {
            enable = true,
            swap_next = { ["<LocalLeader>xp"] = "@parameter.inner" },
            swap_previous = { ["<LocalLeader>px"] = "@parameter.inner" },
          },
        },
      })
    end,
    lazy = true,
    event = "VeryLazy",
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
    lazy = true,
    event = 'VeryLazy',
  },
  {
    'nvim-treesitter/nvim-treesitter-refactor',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = function()
      --- @diagnostic disable: missing-fields
      require('nvim-treesitter.configs').setup({
        refactor = {
          highlight_current_scope = { enable = false },
          highlight_definitions = { enable = true },
          smart_rename = {
            enable = true,
            keymaps = {
              smart_rename = "<LocalLeader>rn",
            },
          },
        },
      })
    end,
    lazy = true,
    event = "VeryLazy",
  },

  {
    'andymass/vim-matchup',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    lazy = true,
    event = 'VeryLazy',
  },

  -- vim.fn.synstack(...) no longer works under treesitter
  -- use :TSHighlightCapturesUnderCursor instead
  {
    'nvim-treesitter/playground',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    lazy = true,
    event = "VeryLazy",
  },
}
