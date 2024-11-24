# Git DeepL Translator

<p align="left">
    <a href="https://github.com/Rikj000/Git-DeepL-Translator/blob/development/LICENSE">
        <img src="https://img.shields.io/github/license/Rikj000/Git-DeepL-Translator?label=License&logo=gnu" alt="GNU General Public License">
    </a> <a href="https://github.com/Rikj000/Git-DeepL-Translator/releases">
        <img src="https://img.shields.io/github/downloads/Rikj000/Git-DeepL-Translator/total?label=Total%20Downloads&logo=github" alt="Total Releases Downloaded from GitHub">
    </a> <a href="https://github.com/Rikj000/Git-DeepL-Translator/releases/latest">
        <img src="https://img.shields.io/github/v/release/Rikj000/Git-DeepL-Translator?include_prereleases&label=Latest%20Release&logo=github" alt="Latest Official Release on GitHub">
    </a> <a href="https://www.iconomi.com/register?ref=zQQPK">
        <img src="https://img.shields.io/badge/ICONOMI-Join-blue?logo=bitcoin&logoColor=white" alt="ICONOMI - The world’s largest crypto strategy provider">
    </a> <a href="https://www.buymeacoffee.com/Rikj000">
        <img src="https://img.shields.io/badge/-Buy%20me%20a%20Coffee!-FFDD00?logo=buy-me-a-coffee&logoColor=black" alt="Buy me a Coffee as a way to sponsor this project!"> 
    </a>
</p>

Simple [Bash](https://www.gnu.org/software/bash/bash.html) script to translate the whole commit message history of a local [Git](https://git-scm.com/) repository from one language to another using [DeepLX](https://deeplx.owo.network/)!

## Dependencies
- [bash](https://archlinux.org/packages/core/x86_64/bash/)
- [coreutils](https://archlinux.org/packages/core/x86_64/coreutils/)
- [curl](https://archlinux.org/packages/core/x86_64/curl/)
- [gawk](https://archlinux.org/packages/core/x86_64/gawk/)
- [sed](https://archlinux.org/packages/core/x86_64/sed/)
- [wget](https://archlinux.org/packages/extra/x86_64/wget/)
- [jq](https://archlinux.org/packages/extra/x86_64/jq/)
- [git](https://archlinux.org/packages/extra/x86_64/git/)
- [git-filter-repo](https://archlinux.org/packages/extra/any/git-filter-repo/)
- [deeplx-bin](https://aur.archlinux.org/packages/deeplx-bin)

## Installation
1. Create a permanent installation location:
    ```bash
    mkdir -p ~/Documents/Program-Files/Git-DeepL-Translator;
    ```
2. Download the latest [`git-deepl-translator`](https://github.com/Rikj000/Git-DeepL-Translator) repo locally to the permanent installation location:
    ```bash
    cd ~/Documents/Program-Files/Git-DeepL-Translator;
    wget "$(
        curl -s -H "Accept: application/vnd.github.v3+json" \
        'https://api.github.com/repos/Rikj000/Git-DeepL-Translator/releases/latest' \
        | jq .assets[0].browser_download_url | sed -e 's/^"//' -e 's/"$//')";
    ```
3. Setup a system link for easy CLI usage:
    ```bash
    sudo ln -s ~/Documents/Program-Files/Git-DeepL-Translator/git-deepl-translator.sh /usr/bin/git-deepl-translator;
    ```

## Usage
Following is the output of `git-deepl-translator -h`:
```bash
Git-DeepL-Translator - v1.0.0
Simple "bash" script to translate the whole commit message history,
of a local Git repository, from one language to another, using DeepLX!

Usage:
  git-deepl-translator [options]

Example:
  git-deepl-translator -ig="/path/to/git/input/repo" -og="/path/to/git/output/repo" -il 'FR' -ol 'EN'

Optional options:
  -h,    -help                           Show this help.
  -u,    -update                         Update Git-DeepL-Translator to the latest version.
  -du,   -deeplx_url=<url>               URL to the DeepLX API, defaults to 'http://localhost:1188'
  -ds,   -deeplx_retry_seconds=<sec>     Amount of seconds to wait before retrying to fetch a DeepLX translation in case none was received, defaults to 10
  -ig,   -input_git_repo_dir=<path>      Path to local input Git repository
  -og,   -output_git_repo_dir=<path>     Path to local output Git repository
  -il,   -input_language=<lang>          Language used by the commit messages of the input Git repository, defaults to 'JA' (Japanese)
  -ol,   -output_language=<lang>         Language to translate the commit messages of the output Git repository into, defaults to 'EN' (English)
```
