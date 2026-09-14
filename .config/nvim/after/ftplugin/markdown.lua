vim.o.softtabstop = 2
vim.o.shiftwidth = 2

local livepreview_available, _ = pcall(require, "livepreview.config")
local previewing = false

-- look for backlinks to current file
vim.keymap.set("n", "gl", function()
    vim.cmd("silent grep! " .. vim.fn.shellescape(vim.fn.expand("%:t")))
    vim.cmd("copen")
end, { buffer = true })

local function start_preview()
    vim.cmd("LivePreview start")

    if vim.env.NIRI_SOCKET then
        if vim.env.TMUX then
            vim.fn.jobstart(
                { "tmux",
                    "if-shell", "-F", "#{window_zoomed_flag}", "", "resize-pane -Z"
                },
                { detach = true, }
            )
        end
        vim.fn.jobstart({ "sh", "-c",
            "niri msg action set-column-width 50%; \
            sleep 0.5; \
            niri msg action swap-window-right \
            niri msg action focus-column-left \
            niri msg action focus-column-right"
        }, { detach = true })
    end
end

local function close_preview_window()
    local win_raw = vim.fn.system({ "niri", "msg", "-j", "windows" })
    local ok_win, wins = pcall(vim.json.decode, win_raw)
    if not ok_win then return end

    for _, w in ipairs(wins) do
        if w.title and w.title:find("Live preview") then
            vim.fn.jobstart({
                "niri", "msg", "action", "close-window", "--id", tostring(w.id)
            }, { detach = true })
        end
    end
end

local function stop_preview()
    if vim.env.NIRI_SOCKET then
        if vim.env.TMUX then
            vim.fn.jobstart(
                { "tmux", "resize-pane", "-Z" },
                { detach = true, }
            )
        end
        close_preview_window()
    end
end

vim.keymap.set('n', 'gb', function()
    if livepreview_available then
        if not previewing then
            vim.cmd("w")
            start_preview()
            previewing = true
        else
            stop_preview()
            previewing = false
        end
    else
        vim.cmd("!FORCE_XO=true $NOTES_DIR/.scripts/nt.sh -p %:p")
    end
end, { desc = 'Preview markdown file', silent = true })

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if previewing then
            stop_preview()
        end
    end
})


-- Each "skippable" block type is described by:
--   starts(line)         -> true if this line opens the block
--   is_delimited         -> true: skip forward to a matching closer line
--                           false: skip forward while `starts` keeps matching
--                           (i.e. a "run" of similar lines, like a table)
--   ends(line)            -> only used when is_delimited; matches the closer
local block_types = {
    { -- $$ ... $$ math block (allow indentation, e.g. inside a list item)
        starts = function(l) return l:match("^%s*%$%$%s*$") ~= nil end,
        ends = function(l) return l:match("^%s*%$%$%s*$") ~= nil end,
        is_delimited = true,
    },
    { -- ``` ... ``` fenced code block
        starts = function(l) return l:match("^%s*```") ~= nil end,
        ends = function(l) return l:match("^%s*```") ~= nil end,
        is_delimited = true,
    },
    { -- table: a run of contiguous table-like lines, no distinct closer
        starts = function(line)
            return line:match("^%s*|") ~= nil
                or (line:match("^%s*[-:| ]+$") ~= nil
                    and line:match("[-|]") ~= nil)
        end,
        is_delimited = false,
    },
}

-- Given lines and a starting index i (where some block_type.starts matched),
-- return the index just past the end of that block.
local function skip_block(lines, n, i, block)
    if block.is_delimited then
        i = i + 1 -- past the opening delimiter
        while i <= n and not block.ends(lines[i]) do
            i = i + 1
        end
        return i + 1 -- past the closing delimiter
    else
        while i <= n and block.starts(lines[i]) do
            i = i + 1
        end
        return i
    end
end

-- A paragraph followed by \n\n won't be formatted
-- Returns the index to jump to if protected, or nil if not.
local function protected_paragraph_end(lines, n, i)
    local para_end = i
    while para_end <= n and lines[para_end] ~= "" do
        para_end = para_end + 1
    end

    if para_end + 1 <= n
        and lines[para_end] == ""
        and lines[para_end + 1] == "" then
        return para_end
    end

    return nil
end

-- YAML frontmatter is only valid as the very first thing in the file, so it
-- can't be expressed as a generic block_type (those only look at the line
-- itself, not its position). Handle it as a one-off before the main scan.
local function skip_frontmatter(lines, n)
    if n >= 1 and lines[1]:match("^%-%-%-%s*$") then
        local i = 2
        while i <= n and not lines[i]:match("^%-%-%-%s*$") do
            i = i + 1
        end
        return i + 1 -- past the closing "---"
    end
    return 1
end

local group = vim.api.nvim_create_augroup(
    "gq_autoformat" .. vim.api.nvim_get_current_buf(),
    { clear = true }
)
vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    buffer = 0,
    desc = "gq-format markdown paragraphs, skipping math, code, tables, and YAML frontmatter.",
    callback = function(event)
        local view = vim.fn.winsaveview()
        local lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)

        local n = #lines
        local i = skip_frontmatter(lines, n)

        while i <= n do
            if lines[i] == "" then
                i = i + 1
                goto continue
            end

            -- try each skippable block type in turn
            for _, block in ipairs(block_types) do
                if block.starts(lines[i]) then
                    i = skip_block(lines, n, i, block)
                    goto continue
                end
            end

            -- check if paragraph is followed by \n\n
            local protected_skip = protected_paragraph_end(lines, n, i)
            if protected_skip then
                i = protected_skip
                goto continue
            end

            -- none matched: this is a regular paragraph, gq-format it,
            -- relying on gqip to stop at the surrounding blank lines
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            vim.cmd("normal! gqip")

            -- gq can change the line count, so refresh our view of the
            -- buffer before continuing the scan
            lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)
            n = #lines

            -- advance past the (possibly reflowed) paragraph to its
            -- trailing blank line
            while i <= n and lines[i] ~= "" do
                i = i + 1
            end

            ::continue::
        end

        vim.fn.winrestview(view)
    end,
})
