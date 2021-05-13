local util = require('packer.util')
local vim

local plugins = function(use, use_rocks)
    use {
        'glacambre/firenvim',
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
        end
    }
    use {
        '/lukas-reineke/indent-blankline.nvim',
        branch = 'lua',
        config = function()
            vim.g.indent_blankline_filetype_exclude = {'help', 'coc-explorer'}
        end,
    }
    use {
        'joshdick/onedark.vim',
        config = function() vim.g.onedark_terminal_italics = 1 end
    }
    use 'ryanoasis/vim-devicons'

    use 'junegunn/fzf.vim'  -- depends on pkgs.fzf
    use 'rafcamlet/nvim-luapad'
    use 'tpope/vim-commentary'
    use 'machakann/vim-sandwich'
    use 'junegunn/vim-easy-align'
    use 'junegunn/vim-peekaboo'

    use {
        'iamcco/markdown-preview.nvim',
        ft = {'markdown', 'vim-plug'},
        run = function() vim.fn['mkdp#util#install']() end,
        config = function()
            vim.g.mkdp_open_ip = 'localhost'
            -- wsl2
            -- function! g:OpenBrowser(url)
            --   silent exe '!lemonade open ' a:url
            -- endfunction
            -- let g:mkdp_browserfunc = 'g:OpenBrowser'
        end
    }

    use 'ryvnf/readline.vim'
    use 'kana/vim-fakeclip'
    use 'chrisbra/unicode.vim'
    use 'tpope/vim-liquid'
    use 'tpope/vim-dadbod'  -- for SQL. TODO: help exrc
    use 'kristijanhusak/vim-dadbod-ui'

    use 'cohama/agit.vim'

    use {
        'rhysd/git-messenger.vim',
        -- cmd = {'<Plug>(git-messenger)', 'GitMessenger'}
        cmd = {'GitMessenger'},
        config = function() vim.g.git_messenger_include_diff = "current" end
    }

    -- https://github.com/rhysd/conflict-marker.vim
    -- https://github.com/christoomey/vim-conflicted
    use 'tpope/vim-fugitive'
    use 'rbong/vim-flog'
    use 'airblade/vim-gitgutter'
    use 'mhinz/vim-signify'
    use 'wellle/tmux-complete.vim'
    use 'chiedo/vim-case-convert'
    use 'gyim/vim-boxdraw'
    use {'monkoose/fzf-hoogle.vim', ft = 'haskell'}
    use 'ojroques/vim-oscyank'

    use {
        'neoclide/coc.nvim',
        branch = 'release',
        run = ':CocInstall coc-lua coc-rust-analyzer coc-git coc-yaml coc-explorer coc-tsserver coc-pyright coc-metals coc-json coc-clangd coc-sh'
    }
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
    use {'mattn/emmet-vim', ft = {'html', 'hbs', 'typescript'}}
    use {'Rykka/colorv.vim', ft = {'less', 'sass', 'css'}}
    use 'rhysd/vim-grammarous'
    use {'norcalli/nvim-colorizer.lua', ft = {'css', 'javascript', 'html', 'less'}}
    use 'liuchengxu/vista.vim'
    use 'itchyny/lightline.vim'
    use {
        'ap/vim-buftabline',
        config = function()
            vim.g.buftabline_show = 1
            vim.g.buftabline_numbers = 2
        end
    }
    -- use 'heavenshell/vim-pydocstring', {'for': 'python'}
    use {'numirias/semshi', run = ':UpdateRemotePlugins'}
    use {'jackguo380/vim-lsp-cxx-highlight', ft = 'cpp'}
    use {'alfredodeza/pytest.vim', ft = 'python'}
    -- use 'nvim-treesitter/nvim-treesitter'

    use_rocks {'luaposix', 'lua-cjson', 'inspect', 'stdlib', 'penlight'}
end

local config = {
    compile_path = util.join_paths(vim.fn.stdpath('data'), 'site', 'plugin', 'packer_compiled.vim'),
}

return require('packer').startup({plugins, config = config})
