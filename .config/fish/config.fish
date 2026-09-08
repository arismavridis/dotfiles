# For interactive sessions:
if status is-interactive

    fish_vi_key_bindings
    set fish_cursor_default block
    set fish_cursor_insert line blink
    set fish_cursor_replace_one underscore blink
    set fish_cursor_visual block

    set fish_greeting

    if type -q zoxide
        zoxide init fish | source
    end
end
