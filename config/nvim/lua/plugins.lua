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
    bibtex          = 'bibtex',
    cmake           = 'cmake',
    comment         = 'comment',
    ejs             = 'embedded_template',
    fennel          = 'fennel',
    gitattributes   = 'gitattributes',
    graphql         = 'graphql',
    haskell         = 'haskell',
    hcl             = 'hcl',
    html            = 'html',
    -- lua             = 'lua',
    nix             = 'nix',
    ocaml           = 'ocaml',
    ocaml_interface = 'ocaml_interface',
    proto           = 'proto',
    python          = 'python',
    regex           = 'regex',
    scala           = 'scala',
    sql             = 'sql',
    tla             = 'tlaplus',
    toml            = 'toml',
    typescript      = 'typescript',
    vim             = 'vim',
    yaml            = 'yaml',
    zig             = 'zig',
};

return {
    -- {
    --     'tamton-aquib/duck.nvim',
    --     config = function()
    --         vim.api.nvim_create_user_command('Duck', function() require("duck").hatch() end, {})
    --         vim.api.nvim_create_user_command('DuckCook', function() require("duck").cook() end, {})
    --     end
    -- },
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
    -- {
    --     'sheerun/vim-polyglot',
    --     init = function()
    --         vim.g.polyglot_disabled = { 'sensible', '', table.unpack(vim.tbl_values(treesitter_ft_mod)) }
    --     end,
    --     cond = function()
    --         -- not working with vim-markdown
    --         local set = { 'sensible', '' }
    --         return set[vim.bo.filetype] == nil and _G.treesitter_ft_mod[vim.bo.filetype] == nil;
    --     end,
    --     event = "VeryLazy", -- better than FileType as plugins may set ft
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
                    "NormalFloat",
                }
            })
        end,
        lazy = true,
        event = 'BufEnter',
    },
    {
        "EdenEast/nightfox.nvim",
        config = function()
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
        end,
        enabled = function() return vim.fn.has('mac') == 1 end,
    },
    {
        'olimorris/onedarkpro.nvim',
        config = function()
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
        end,
        enabled = function() return vim.fn.has('linux') == 1 end,
    },

    {
        'folke/todo-comments.nvim',
        config = function()
            require('todo-comments').setup {
                highlight = { keyword = "bg", multiline = true }
            }
            vim.cmd [[syntax keyword Todo contained NOTE NOTES]] -- w/o treesitter
        end
    },

    {
        'rhysd/clever-f.vim', -- leap.nvim is clunky
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

    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    {
        'folke/trouble.nvim',
        config = function()
            local opts = { silent = true, noremap = true }
            vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>", opts)
        end,
        lazy = true,
        event = 'VeryLazy',
    },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'pwntester/octo.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-symbols.nvim',
            'xiyaowong/telescope-emoji.nvim',
            'luc-tielen/telescope_hoogle',
            'MrcJkb/telescope-manix',
            'AckslD/nvim-neoclip.lua',
        },
        config = function()
            require('octo').setup()
            require('neoclip').setup()
            local telescope = require('telescope')
            local actions = require('telescope.actions')

            telescope.setup {
                set_env = { ['COLORTERM'] = 'truecolor' }, -- default = nil,
                extensions = {
                    fzf = {
                        override_filter_sorter = true,
                    }
                },
                defaults = {
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-u>"] = false, -- do not scroll up in preview
                            ["<C-b>"] = actions.preview_scrolling_up,
                            ["<C-f>"] = actions.preview_scrolling_down,
                        },
                        n = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                        }
                    }
                }
            }

            telescope.load_extension('hoogle')
            telescope.load_extension('fzf')
            vim.cmd [[
                nnoremap <C-\> <cmd>Telescope<CR>
                nnoremap <C-P> <cmd>Telescope find_files<CR>
                nnoremap <unique> <silent> <LocalLeader>d <cmd>Telescope diagnostics<CR>
            ]]

            -- Welp, https://github.com/nvim-telescope/telescope.nvim/issues/2027#issuecomment-1561836585
            vim.api.nvim_create_autocmd("WinLeave", {
              callback = function()
                if vim.bo.ft == "TelescopePrompt" and vim.fn.mode() == "i" then
                  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "i", false)
                end
              end,
            })
        end,
        event = "VeryLazy",
    },
    { 'rafcamlet/nvim-luapad',                    lazy = true,   ft = "lua" },

    {
        'numToStr/Comment.nvim',
        dependencies = {
          'JoosepAlviste/nvim-ts-context-commentstring',
          'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require('Comment').setup {
                pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
                mappings = {
                    basic = true,
                    extra = false,
                }
            }
        end,
        lazy = true,
        event = "VeryLazy",
    },
    {
        'kylechui/nvim-surround',
        config = function() require('nvim-surround').setup({}) end,
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
        end,
        lazy = true,
        event = "BufEnter",
    },
    'junegunn/vim-peekaboo',
    {
      'ojroques/vim-oscyank',
      lazy = true,
      event = "BufEnter",
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
      opts = {
          formatters_by_ft = {
            lua = { "stylua" },
            vue = { { "prettierd", "prettier" } },
            javascript = { 'clang_format' },
            typescript = { 'clang_format' },
            python = { 'isort' },
            yaml = { command = 'yamlfmt', args = { '-i', '-n' } },
            ["*"] = { "trim_whitespace" },
          },
      },
      init = function()
        -- overrides formatexpr=v:lua.vim.lsp.formatexpr()
        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
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
    -- {
    --     'epwalsh/obsidian.nvim',
    --     dependencies = { 'hrsh7th/nvim-cmp' },
    --     config = function()
    --         require('obsidian').setup({
    --             dir = "~/OneDrive/obsidian",
    --             use_advanced_uri = true,
    --         })
    --     end,
    --     lazy = true,
    --     ft = "markdown",
    -- },

    {
        'ryvnf/readline.vim',
        config = function()
            local function back_delete_char()
                local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
                if col == vim.fn.col('$') - 1 then return end
                local bufnr = vim.api.nvim_get_current_buf()
                vim.api.nvim_buf_set_text(bufnr, row - 1, col, row - 1, col + 1, {})
            end

            vim.keymap.set('i', '<C-D>', back_delete_char, { silent = true })
        end,
        lazy = true,
        event = 'VeryLazy',
    },
    {
        'kana/vim-fakeclip',
        lazy = true,
        event = "VeryLazy",
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
        'rhysd/git-messenger.vim',
        keys = { '<leader>gm', '<cmd>GitMessenger<cr>' },
        config = function() vim.g.git_messenger_include_diff = "current" end
    },

    -- use 'jbyuki/instant.nvim'  -- coediting

    -- https://github.com/rhysd/conflict-marker.vim
    -- https://github.com/christoomey/vim-conflicted
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
        config = function()
            require('gitsigns').setup({
                -- I dont like the index `Hunk 1 of 2`, maybe I can patch a plugin
                -- https://github.com/wbthomason/packer.nvim/issues/882
                preview_config = {
                    -- Options passed to nvim_open_win
                    border = 'none',
                    style = 'minimal',
                    relative = 'cursor',
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    map('n', ']c', function()
                        if vim.wo.diff then return ']c' end
                        vim.schedule(gs.next_hunk)
                        return '<Ignore>'
                    end, { expr = true })
                    map('n', '[c', function()
                        if vim.wo.diff then return '[c' end
                        vim.schedule(gs.prev_hunk)
                        return '<Ignore>'
                    end, { expr = true })

                    -- Actions
                    map('n', '<leader>hs', gs.stage_hunk)
                    map('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
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
            });
        end,
        lazy = true,
        event = "BufEnter",
    },
    {
      -- 'johmsalas/text-case.nvim',
      'chiedo/vim-case-convert',
      lazy = true,
      event = "BufEnter",
    },
    {
      'gyim/vim-boxdraw',
      lazy = true,
      event = "BufEnter",
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
    {
        'skywind3000/asyncrun.vim',
        lazy = true,
        event = "VeryLazy",
    },
    {
        'mattn/emmet-vim',
        ft = { 'html', 'hbs', 'typescript', 'typescriptreact' },
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
        'norcalli/nvim-colorizer.lua',
        ft = { 'css', 'javascript', 'html', 'less', 'sass', 'typescriptreact', 'Onedarkpro' },
        config = function() require 'colorizer'.setup() end,
    },
    -- { 'ray-x/navigator.lua' },
    {
        'simrat39/symbols-outline.nvim',
        config = function()
            local outline = require("symbols-outline")

            outline.setup({ opts = { width = 20 } })
            vim.keymap.set('n', '<leader>vt', outline.toggle_outline, { silent = true })
        end,
        lazy = true,
        event = 'UIEnter',
    },
    {
        'rebelot/heirline.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons', 'olimorris/onedarkpro.nvim' },
        config = function() require('statusline') end,
        lazy = true,
        event = "UIEnter",
    },
    {
        'vimpostor/vim-tpipeline', -- move vim statusline into tmux statsline
        lazy = true,
        event = "UIEnter",
    },
    {
        'mrcjkb/rustaceanvim',
        version = '^3', -- Recommended
        ft = { 'rust' },
        dependencies = { 'mfussenegger/nvim-dap', 'hrsh7th/nvim-cmp' },
        init = function()
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
              settings = {
                ['rust-analyzer'] = {
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
      'saecki/crates.nvim',
      tag = 'v0.4.0',
      dependencies = { 'nvim-lua/plenary.nvim', 'hrsh7th/nvim-cmp' },
      event = { "BufRead Cargo.toml" },
      config = function()
        require('crates').setup({
          src = { cmp = { enabled = true } }
      })
    end
    },
    {
        'mfussenegger/nvim-dap',
        dependencies = {
          'nvim-telescope/telescope-dap.nvim',
          'nvim-telescope/telescope.nvim',
          'rcarriga/nvim-dap-ui'
        },
        config = function()
          local dap, dapui = require("dap"), require("dapui")
          require('telescope').load_extension('dap')
          dapui.setup()

          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
          end

          vim.keymap.set('n', '<Leader>db', function() dap.toggle_breakpoint() end)
          vim.keymap.set('n', '<Leader>dr', function() dap.repl.open() end)
          vim.keymap.set('n', '<Leader>dl', function() dap.run_last() end)
          vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
            require('dap.ui.widgets').hover()
          end)
          vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
            require('dap.ui.widgets').preview()
          end)
          vim.keymap.set('n', '<Leader>df', function()
            local widgets = require('dap.ui.widgets')
            widgets.centered_float(widgets.frames)
          end)
          vim.keymap.set('n', '<Leader>ds', function()
            local widgets = require('dap.ui.widgets')
            widgets.centered_float(widgets.scopes)
          end)

        end,
        lazh = true,
        event = 'VeryLazy',
    },
    {
        'hrsh7th/nvim-cmp',
        lazy = true,
        -- Must be earlier enough to avoid lazy loading a lazy load
        -- https://github.com/neovim/nvim-lspconfig/issues/1142#issuecomment-1656844163
        event = "BufReadPre",
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'quangnguyen30192/cmp-nvim-ultisnips',
            'neovim/nvim-lspconfig',
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'mfussenegger/nvim-lint',
            'folke/neodev.nvim',
            'andersevenrud/cmp-tmux',
            {
                'lvimuser/lsp-inlayhints.nvim',
                config = function() require('lsp-inlayhints').setup({
                    inlay_hints = { type_hints = { show = false, remove_colon_start = true } }
                }) end,
            },

            { 'SmiteshP/nvim-navbuddy', "MunifTanjim/nui.nvim" },

            'SmiteshP/nvim-navic',
            { 'j-hui/fidget.nvim', branch = 'legacy' },

            'p00f/clangd_extensions.nvim',
            'MrcJkb/haskell-tools.nvim',
        },
        config = function()
          require('lsp')
          require('neodev').setup({})
          require("fidget").setup({}) -- nvim-lsp progress
        end,
    },
    {
        "ThePrimeagen/refactoring.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function() require('refactoring').setup({}) end,
        lazy = true,
        event = 'VeryLazy',
    },
    {
        -- regarding the issue of very long output from :messages
        -- noice.nvim is too intrusive.
        -- https://github.com/neovim/neovim/pull/5189 would be btter
        'folke/noice.nvim',
        event = 'LspAttach',
        opts = {
          presets = {
            bottom_search = false, -- use a classic bottom cmdline for search
            command_palette = false, -- position the cmdline and popupmenu together
            long_message_to_split = false, -- long messages will be sent to a split
            inc_rename = false, -- enables an input dialog for inc-rename.nvim
            lsp_doc_border = false, -- add a border to hover docs and signature help
          },
          cmdline = { enabled = false },
          messages = { enabled = false },
          popupmenu = { enabled = false },
          notify = { enabled = false },
          smart_move = { enabled = false },
          lsp = {
            progress = { enabled = false },
            override = {
              -- override the default lsp markdown formatter with Noice
              ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
              -- override the lsp markdown formatter with Noice
              ["vim.lsp.util.stylize_markdown"] = true,
              -- override cmp documentation with Noice (needs the other options to work)
              ["cmp.entry.get_documentation"] = true,
            },
            hover = { enabled = false },
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
        },
        config = function()
            require("neo-tree").setup({
              window = {
                mappings = {
                  ["Z"] = "expand_all_nodes",
                }
              },
              filesystem = {
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
        dependencies = 'famiu/bufdelete.nvim',
        config = function()
            local sidebar = 'neo-tree';
            require('bufferline').setup {
                options = {
                    show_buffer_icons = false,
                    show_buffer_close_icons = false,
                    show_close_icon = false,
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
                        require('bufdelete').bufdelete(bufnr, true)
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
                    require('bufdelete').bufdelete(0, true)
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
            "nvim-neotest/neotest-python",
            "nvim-neotest/neotest-vim-test",
            "nvim-treesitter/nvim-treesitter",
            "antoinemadec/FixCursorHold.nvim"
        },
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
        lazy = true,
        ft = { "vim", "python" },
    },
    -- use 'heavenshell/vim-pydocstring', {'for': 'python'}
    { 'wookayin/semshi', build = ':UpdateRemotePlugins', lazy = true, ft = "python" },
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            require 'nvim-treesitter.configs'.setup {
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
                    enable = false,
                    disable = { "python" },
                },
                incremental_selection = { enable = true },
                embedded_template = { enable = true, }
            }
        end
    },

    {
        'windwp/nvim-autopairs',
        config = function() require('nvim-autopairs').setup {}; end,
        lazy = true,
        event = 'VeryLazy',
    },

    {
        'yioneko/nvim-yati',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        cond = function() return vim.bo.filetype == 'python'; end,
        config = function()
            require("nvim-treesitter.configs").setup {
                yati = { enable = true },
            };
        end,
        lazy = true,
        event = "VeryLazy",
    },

    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = function()
            require 'nvim-treesitter.configs'.setup {
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
            }
        end,
        lazy = true,
        event = "VeryLazy",
    },

    {
        'nvim-treesitter/nvim-treesitter-refactor',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = function()
            require 'nvim-treesitter.configs'.setup {
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
            }
        end,
        lazy = true,
        event = "VeryLazy",
    },

    {
        'andymass/vim-matchup',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = function()
            require 'nvim-treesitter.configs'.setup {
                matchup = {
                    enable = true, -- mandatory, false will disable the whole extension
                    disable = {},  -- optional, list of language that will be disabled
                    -- [options]
                },
            }
        end,
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
