-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local bufnr = ev.buf;

    local function show_documentation()
        local filetype = vim.bo.filetype
        if vim.tbl_contains({ 'vim','help' }, filetype) then
            vim.cmd('h '..vim.fn.expand('<cword>'))
        elseif vim.tbl_contains({ 'man' }, filetype) then
            vim.cmd('Man '..vim.fn.expand('<cword>'))
        elseif vim.fn.expand('%:t') == 'Cargo.toml' and package.loaded.crates ~= nil and require('crates').popup_available() then
            require('crates').show_popup()
        elseif package.loaded.hover then
            require('hover').hover({ bufnr = bufnr }) --- @diagnostic disable-line: missing-fields
        else
            vim.lsp.buf.hover()
        end
    end

    local opts = { silent = true, buffer = bufnr }
    local picker = require("snacks.picker");
    vim.keymap.set('n', 'gD', picker.lsp_declarations, opts)
    vim.keymap.set('n', 'gd', picker.lsp_definitions, opts)
    vim.keymap.set('n', 'gT', picker.lsp_type_definitions, opts)
    vim.keymap.set('n', 'gi', picker.lsp_implementations, opts)
    vim.keymap.set('n', 'gr', picker.lsp_references, opts)
    vim.keymap.set('n', 'K', show_documentation, opts)
    if vim.bo.filetype == 'rust' then
      vim.keymap.set("n", "<space>", function() vim.cmd.RustLsp { 'hover', 'range' } end, opts)
    end
    vim.keymap.set('n', '<leader>ac', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '[h', function()
      vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.HINT, float = true })
    end, opts)
    vim.keymap.set('n', ']h', function()
      vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.HINT, float = true })
    end, opts)
    vim.keymap.set('n', '[w', function()
      vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN, float = true })
    end, opts)
    vim.keymap.set('n', ']w', function()
      vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN, float = true })
    end, opts)
    vim.keymap.set('n', '[e', function()
      vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
    end, opts)
    vim.keymap.set('n', ']e', function()
      vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
    end, opts)
    vim.keymap.set('n', '<leader>fx', function()
        vim.lsp.buf.code_action({
            filter = function(x) return x.isPreferred end,
            apply = true,
        })
    end, opts)

    local client = vim.lsp.get_client_by_id(ev.data.client_id);
    if client == nil then return end

    -- https://github.com/neovim/nvim-lspconfig/issues/2626#issuecomment-2117022664
    if client.name == 'yamlls' and vim.bo.filetype == 'helm' then
      return vim.lsp.buf_detach_client(bufnr, client.id);
    end

    -- lsp client somehow does not send textDocument/rangeFormatting
    if client.server_capabilities.documentRangeFormattingProvider then
        local fn = function() vim.lsp.buf.format({ async = true }) end
        vim.keymap.set('v', 'gq', fn, opts)
    end
  end,
})
