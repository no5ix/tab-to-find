
# zsh-tab-any介绍

支持任何命令对于目录和文件的路径的 tab 自动补全

- 可以不一定是头部完全匹配, 比如 输入 `doc` 然后 tab , 可以匹配 `test_doc` 也可以匹配 `doc_test` 也可以匹配 `test_doc_test`
- 可以递归匹配当前目录的子目录的所有 `doc` 的文件/目录, 也就是说你可以在 `home` 目录输入 `cd doc` 然后从 `home` 目录一步直接 `cd` 到 `~/github/test-proj/documents` 里 !


# 安装方法

1. 确认已经安装好了 `fd` 和 `fzf`
2. 把 `zsh-tab-any` 文件夹放到 `~/.oh-my-zsh/custom/plugins` 的位置
3. `vim ~/.zshrc`, 找到七八十行左右 `plugins=(git)` 的位置 比如原来是 `plugins=(git)` 则改为 `plugins=(git zsh-tab-any)`
4. `source ~/.zshrc` 或者重启 zsh


# 使用方法

- 比如先输入 `cd` 然后 敲击 `tab` 找到想要进入的目录然后回车进入目录了, 也可以先输入 `cd doc` 然后 敲击 `tab`, 会先搜索当前目录下的匹配的文件/目录,
   - 如果只有一个匹配项, 则自动补全
      - 比如匹配到了 `Documents/` , 但如果这不是你想要的, 你想要的是 `~/github/test-proj/documents` , 那你可以再按一次tab
   - 如果不只是有一个匹配项, 则会递归搜索子目录下的所有含有 `doc` 的文件夹
- 同理 `vi`, `ln`, `mv`, `cp` 和其他命令也是如此
