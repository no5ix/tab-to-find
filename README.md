# tab-to-find

One Tab enables interactive and dynamic path search using Zsh, [fd](https://github.com/sharkdp/fd), and [fzf](https://github.com/junegunn/fzf).

## Changes in this branch

- Normal search excludes hidden and ignore-matched entries using fd defaults.
- Hidden and ignored entries can be included deliberately with environment variables.
- Completion uses native Zsh path operations where practical and avoids forcing a prompt reset after selection.
- Searches rooted at `~` promote common home folders (Documents, Downloads, Desktop, Applications, Movies, Music, Pictures, and Projects) before the recursive results.

## Requirements

- Zsh
- fd (or fdfind configured as fd)
- fzf

## Installation

### Manual

```zsh
git clone https://github.com/no5ix/tab-to-find ~/somewhere
echo 'source ~/somewhere/tab-to-find.plugin.zsh' >> ~/.zshrc
source ~/.zshrc
```

### Oh My Zsh

```zsh
git clone https://github.com/no5ix/tab-to-find ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/tab-to-find
```

Add `tab-to-find` to the plugins array in `~/.zshrc`, then restart Zsh or run `source ~/.zshrc`.

## Usage

Use Tab as usual:

- `cd <Tab>`: open interactive directory search.
- `vim <Tab>`: search files.
- `cp <Tab>`, `mv <Tab>`, and `ln <Tab>`: search paths for supported commands.
- Type a partial name before Tab to filter candidates.
- End a path with `//` to limit the search to immediate directories.
- End a path with `..` to limit the search to immediate files.

Normal mode excludes hidden entries and entries ignored by fd. Hidden folders such as `.pi`, `.nvm`, and `.config` are therefore not shown by default.

To include hidden entries for the current shell session:

```zsh
export TAB_TO_FIND_INCLUDE_HIDDEN=1
```

To include ignored entries as well:

```zsh
export TAB_TO_FIND_INCLUDE_IGNORED=1
```

Unset either variable or set it to `0` to restore the default.

## Tests

Run:

```zsh
zsh tests/check-plugin.zsh
```

This lightweight check validates source-level invariants. Also test interactively in macOS Terminal.app and iTerm2. Static checks cannot reproduce terminal-specific prompt/rendering latency.
