local util = require('packer.util')

M = {}
--- @param id string
--- @param what "'fg'" | "'bg'"
--- @param mode "'gui'" | "'cterm'" | "'term'"
--- @return string
M.hiof = function(id, what, mode)
    return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(id)), what, mode)
end

--- @generic K, V
--- @param tbl table<K, V>
--- @return K[]
table.keys = function(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        keys[#keys+1] = k
    end
    return keys;
end

--- @generic K, V
--- @param tbl table<K, V>
--- @return V[]
table.values = function(tbl)
    local values = {}
    for _, v in pairs(tbl) do
        values[#values+1] = v;
    end
    return values
end

--- @generic T
--- @param object T
--- @return T
M.trace = function(object)
    local inspect = require('inspect')
    print(inspect(object));
    return object
end

-- Use nvim-treesitter instead of vim-polyglot for:
-- filetype => module
M.treesitter_ft_mod = {
    bibtex          = 'bibtex',
    cmake           = 'cmake',
    comment         = 'comment',
    fennel          = 'fennel',
    graphql         = 'graphql',
    haskell         = 'haskell',
    hcl             = 'hcl',
    lua             = 'lua',
    nix             = 'nix',
    ocaml           = 'ocaml',
    ocaml_interface = 'ocaml_interface',
    python          = 'python',
    scala           = 'scala',
    tla             = 'tlaplus',
    typescript      = 'typescript',
    vim             = 'vim',
    zig             = 'zig',
};

local plugins = function(use, use_rocks)
    use 'lewis6991/impatient.nvim'
    use {
        'glacambre/firenvim',
        config = function()
            vim.g.firenvim_config = {
                localSettings = {
                    ['.*'] = {
                        selector = 'textarea'
                    }
                }
            }
        end,
        run = function() vim.fn['firenvim#install'](0) end
    }
    use {
        'sheerun/vim-polyglot',
        opt = false,
        setup = function()
            -- Please declare this variable before polyglot is loaded (at the top of .vimrc)
            -- vim-polyglot via https://github.com/vim-python/python-syntax improves nothing
            -- not working with vim-markdown
            vim.g.polyglot_disabled = {'python', 'sensible'}
        end,
        cond = function()
            return vim.bo.filetype ~= '' and not M.treesitter_ft_mod[vim.bo.filetype];
        end,
    }
    use {
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            vim.g.indent_blankline_filetype_exclude = {'help', 'coc-explorer'}
            vim.g.indent_blankline_char = '│';

            local guifg = M.hiof('Normal', 'fg', 'gui');
            local ctermfg = M.hiof('Normal', 'fg', 'cterm');
            -- local guifg = vim.api.nvim_eval("synIDattr(synIDtrans(hlID('Normal')), 'fg', 'gui')")

            -- Actually need something like the freground color of the text
            -- vim.cmd('hi IndentBlanklineChar guifg=' .. guifg .. ' ctermfg=' .. ctermfg)
            vim.cmd('hi! link IndentBlanklineSpaceChar Normal')
        end,
    }
    use {
        'olimorris/onedarkpro.nvim',
        config = function()
            local onedarkpro = require('onedarkpro')
            onedarkpro.setup({
                options = { transparency = true },
                hlgroups = {
                    Normal = { fg = '#abb2bf' },
                    DiffAdd = { fg = 'green', bg = 'NONE' },
                    DiffDelete = { fg = 'red', bg = 'NONE' },
                    CocFloating = { link = 'Pmenu' },  -- originally NormalFloat
                    -- CocUnusedHighlight -> CocFadeOut -> Conceal
                    CocUnusedHighlight = { fg='Gray', bg='NONE' },
                    CocInfoSign = { fg = 'LightBlue' },
                    CocHintSign = { fg = 'Cyan' },
                },
            })
            onedarkpro.load()
        end,
    }
    use 'qxxxb/vim-searchhi'

    use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
    use {
        'nvim-telescope/telescope.nvim',
        requires = {{
            'pwntester/octo.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-symbols.nvim',
            'xiyaowong/telescope-emoji.nvim',
            'fannheyward/telescope-coc.nvim',
            'luc-tielen/telescope_hoogle',
        }},
        config = function()
            require('octo').setup()
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
                            ["<C-u>"] = false,  -- do not scroll up in preview
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

            telescope.load_extension('coc')
            telescope.load_extension('hoogle')
            telescope.load_extension('fzf')
        end
    }
    use {'monkoose/fzf-hoogle.vim', ft = 'haskell'}
    use 'junegunn/fzf.vim'  -- depends on pkgs.fzf
    use 'rafcamlet/nvim-luapad'
    use {
        'b3nj5m1n/kommentary',
        requires = 'JoosepAlviste/nvim-ts-context-commentstring',
        config = function()
            require('kommentary.config').configure_language('typescriptreact', {
                single_line_comment_string = 'auto',
                multi_line_comment_strings = 'auto',
                hook_function = require('ts_context_commentstring.internal').update_commentstring
            })
        end,
    }
    use 'machakann/vim-sandwich'
    use 'junegunn/vim-easy-align'
    use 'junegunn/vim-peekaboo'
    use 'ojroques/vim-oscyank'
    use {
        'FooSoft/vim-argwrap',
        config = function() vim.g.argwrap_tail_comma = 1 end
    }
    use {
        'sbdchd/neoformat',
        config = function()
            vim.g.neoformat_enabled_typescript = {'clang-format'};
            -- Enable alignment

            vim.g.neoformat_basic_format_align = 1
            -- Enable tab to spaces conversion
            vim.g.neoformat_basic_format_retab = 1
            -- Enable trimmming of trailing whitespace
            vim.g.neoformat_basic_format_trim = 1
        end
    }

    use 'Olical/conjure'
    use {
        'Olical/aniseed',
        config = function()
            vim.g["aniseed#env"] = true
        end
    }

    use {
        'iamcco/markdown-preview.nvim',
        ft = {'markdown'},
        run = 'cd app && yarn install',
        cmd = 'MarkdownPreview',
        config = function()
            vim.g.mkdp_open_ip = 'localhost'

            -- wsl2
            local file = io.open('/proc/sys/kernel/osrelease', 'r')
            local is_wsl2 = file:read():find('microsoft')
            file:close()

            if is_wsl2 then
              vim.cmd([[
                function! g:OpenBrowser(url)
                  silent exe '!/mnt/c/Windows/System32/cmd.exe /c start' a:url
                endfunction
              ]]);
              vim.g.mkdp_browserfunc = 'g:OpenBrowser'
            end
        end
    }

    use 'ryvnf/readline.vim'
    use 'kana/vim-fakeclip'
    use 'chrisbra/unicode.vim'
    use 'tpope/vim-liquid'
    use 'tpope/vim-dadbod'  -- for SQL. TODO: help exrc
    use 'kristijanhusak/vim-dadbod-ui'

    use {
        'rhysd/git-messenger.vim',
        keys = {'<leader>gm'},
        cmd = {'GitMessenger'},
        config = function() vim.g.git_messenger_include_diff = "current" end
    }

    -- use 'jbyuki/instant.nvim'  -- coediting

    -- https://github.com/rhysd/conflict-marker.vim
    -- https://github.com/christoomey/vim-conflicted
    use 'tpope/vim-fugitive'
    use 'cohama/agit.vim'

    -- The default netrw#BrowseX() is broken. It always opens `file:///...` in
    -- vim despite netrw#CheckIfRemote() returns 1.
    --
    -- So may be xdg-open.
    -- xdg-open uses both Chromium and Firefox🤷, and it does not care about
    -- fragments in a url.
    use {
        'tyru/open-browser.vim',
        config = function()
            vim.g.netrw_nogx = 1
            vim.g.openbrowser_browser_commands = {
                {name = "firefox",       args = {"{browser}", "{uri}"}},
                {name = "xdg-open",      args = {"{browser}", "{uri}"}},
                {name = "x-www-browser", args = {"{browser}", "{uri}"}},
                {name = "w3m",           args = {"{browser}", "{uri}"}},
            }
            vim.cmd [[ nmap gx <Plug>(openbrowser-smart-search) ]]
            vim.cmd [[ vmap gx <Plug>(openbrowser-smart-search) ]]
        end,
    }
    use {
        'mhinz/vim-signify',
        config = function()
            -- spped up; prevent checking other vcs
            vim.g.signify_vcs_list = {'git'}
            vim.g.signify_realtime = 1
        end
    }
    use 'wellle/tmux-complete.vim'
    use 'chiedo/vim-case-convert'
    use 'gyim/vim-boxdraw'
    use {'fisadev/vim-isort', ft = {'python'}}
    use {
        'tell-k/vim-autopep8',
        config = function() vim.g.autopep8_disable_show_diff = 1 end
    }

    use {
        'SirVer/ultisnips',
        requires = { 'honza/vim-snippets' },
        config = function()
            vim.g.UltiSnipsListSnippets        = "<c-tab>"
            vim.g.UltiSnipsJumpForwardTrigger  = "<tab>"
            vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"
            vim.g.snips_author                 = "Congee"
        end
    }

    use {'neomake/neomake', ft = {'python', 'cpp', 'typescript', 'rust'}}
    use 'skywind3000/asyncrun.vim'
    use {
        'mattn/emmet-vim',
        ft = {'html', 'hbs', 'typescript', 'typescriptreact'},
        config = function()
            vim.g.user_emmet_settings = {typescript = {extends = 'jsx'}}
        end
    }

    -- color picker
    use {'KabbAmine/vCoolor.vim', ft = {'less', 'sass', 'css', 'typescriptreact'}}
    use 'rhysd/vim-grammarous'
    use {
        'norcalli/nvim-colorizer.lua',
        ft = {'css', 'javascript', 'html', 'less', 'sass', 'typescriptreact'},
        config = function()
            -- if vim.fn.has("mac") then require'colorizer'.setup() end
            require'colorizer'.setup()
        end,

    }
    use {
        'liuchengxu/vista.vim',
        config = function()
            vim.g.vista_default_executive = 'coc'
            vim.g['vista#renderer#enable_icon'] = 1
            -- doesn't hls provide symbols?
            -- vim.g.vista_ctags_cmd = { haskell = 'hasktags -x -o - -c' }
            vim.cmd [[ nnoremap <silent> <leader>vt :Vista!!<CR> ]]
        end
    }
    -- use {'nvim-lua/lsp-status.nvim'}
    use 'kyazdani42/nvim-web-devicons'
    use {
        'glepnir/galaxyline.nvim',
        config = function() require('eviline') end,
        requires = {'kyazdani42/nvim-web-devicons', 'liuchengxu/vista.vim'}
    }

    use {
        'neoclide/coc.nvim',
        run = 'yarn install --frozen-lockfile',
        requires = { 'ryanoasis/vim-devicons' },  -- coc-explorer requires it
        config = function()
            vim.g.coc_global_extensions = {
                'coc-sumneko-lua',
                'coc-rust-analyzer',
                'coc-git',
                'coc-yaml',
                'coc-explorer',
                'coc-tsserver',
                'coc-pyright',
                'coc-metals',
                'coc-json',
                'coc-clangd',
                'coc-sh',
                'coc-html',
                'coc-vimlsp',
                'coc-clang-format-style-options',
                'coc-ltex',
                'coc-emmet',
                'coc-markdown-preview-enhanced', 'coc-webview',
                'coc-prettier',
                'coc-docker',
                'coc-cmake',
                'coc-tailwindcss',
            }
            vim.g.coc_default_semantic_highlight_groups = 1
            -- Apparently, coc-settings.json does not parse $JAVA_HOME, so we
            -- need to dynamically evaluate $JAVA_HOME:
            -- vim.cmd[[ :call coc#config('ltex.java.path', $JAVA_HOME) ]]
            vim.fn["coc#config"]('ltex.java.path', vim.env.JAVA_HOME);
        end,
    }
    use {
        'gelguy/wilder.nvim',
        requires = {'romgrk/fzy-lua-native'},
        run = ":UpdateRemotePlugins",
        config = function()
            -- VimL lambdas cannot be used with Lua calls. Will make a switch
            -- once it's fixed. https://github.com/gelguy/wilder.nvim/issues/52
            vim.cmd[[
                function! s:wilder_init() abort
                    call wilder#setup({'modes': [':', '/', '?']})
                    call wilder#set_option('use_python_remote_plugin', 0)
                    call wilder#set_option('pipeline', [
                      \   wilder#branch(
                      \     wilder#cmdline_pipeline({
                      \       'fuzzy': 1,
                      \       'fuzzy_filter': wilder#lua_fzy_filter(),
                      \     }),
                      \     wilder#vim_search_pipeline(),
                      \   ),
                      \ ])

                    let l:hightlight_accent = wilder#make_hl(
                      \   'WilderAccent',
                      \   'Pmenu',
                      \   [{}, {}, {'foreground': '#f4468f'}]
                      \ )
                    call wilder#set_option('renderer', wilder#renderer_mux({
                      \ ':': wilder#popupmenu_renderer({
                      \   'highlighter': wilder#lua_fzy_highlighter(),
                      \   'highlights': {'accent': l:hightlight_accent},
                      \   'max_height': '25%',
                      \   'left':  [ ' ', wilder#popupmenu_devicons() ],
                      \   'right': [ ' ', wilder#popupmenu_scrollbar() ],
                      \ }),
                      \ '/': wilder#popupmenu_renderer({
                      \   'highlighter': wilder#lua_fzy_highlighter(),
                      \   'highlights': {'accent': l:hightlight_accent},
                      \   'max_height': '25%',
                      \   'right': [ ' ', wilder#popupmenu_scrollbar() ],
                      \ }),
                      \ }))
                endfunction
                " defer startup
                autocmd CmdlineEnter * ++once call s:wilder_init() | call wilder#main#start()
            ]];
        end,
    }

    -- use 'kyazdani42/nvim-tree.lua'
    -- use 'romgrk/barbar.nvim'  -- barbar does not play well with coc-explorer
    use {
        'ap/vim-buftabline',
        config = function()
            vim.g.buftabline_show = 1
            vim.g.buftabline_numbers = 2
        end
    }
    use {'voldikss/vim-floaterm'}
    use {
        "rcarriga/vim-ultest",
        requires = {"vim-test/vim-test", 'mfussenegger/nvim-dap'},
        run = ":UpdateRemotePlugins",
        config = function() vim.g['test#strategy'] = 'floaterm' end
    }
    -- use 'heavenshell/vim-pydocstring', {'for': 'python'}
    use {'numirias/semshi', run = ':UpdateRemotePlugins'}
    use {'jackguo380/vim-lsp-cxx-highlight', ft = 'cpp'}

    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require'nvim-treesitter.configs'.setup {
                ensure_installed = table.values(M.treesitter_ft_mod);
                context_commentstring = {
                    enable = true,
                    enable_autocmd = false,
                },
                highlight = {
                    enable = true,
                    disable = {"cpp", "bash", "python", "typescript", "go"}
                },
                indent = {
                    enable = true,
                    disable = {"python"},
                },
                incremental_selection = { enable = true },
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
        end
    }

    use {
        'nvim-treesitter/nvim-treesitter-textobjects',
        requires = 'nvim-treesitter/nvim-treesitter',
        config = function()
            require'nvim-treesitter.configs'.setup {
                textobjects = {
                    select = {
                        enable = true,
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
    }

    use_rocks {'luaposix', 'lua-cjson', 'inspect', 'stdlib', 'penlight', 'lua-path'}
end

local config = {
    compile_path = util.join_paths(vim.fn.stdpath('data'), 'site', 'plugin', 'packer_compiled.vim'),
}

return require('packer').startup({plugins, config = config})
