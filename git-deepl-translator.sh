#!/bin/bash
# Author: Rikj000

# === Default Settings =================================================================================================
DEEPLX_URL="http://localhost:1188";
DEEPLX_RETRY_SECONDS="10";
INPUT_GIT_REPO_DIR="";
OUTPUT_GIT_REPO_DIR="";
INPUT_LANGUAGE="JA";
OUTPUT_LANGUAGE="EN";
# === Default Settings =================================================================================================

# Help function
function usage() {
    cat << EOF

  Git-DeepL-Translator - v0.0.0
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
EOF

    exit 0;
}

# Update function
function update() {
    echo "Setting up installation directory helpers...";
    INSTALLATION_FILE=$(realpath "$(dirname "$0")/$(basename "$0")");
    INSTALLATION_DIR=$(dirname "$INSTALLATION_FILE");

    echo "Moving to the installation directory... ($INSTALLATION_DIR)";
    cd "$INSTALLATION_DIR/" || exit;

    echo "Downloading + installing latest version...";
    wget "$(
        curl -s -H "Accept: application/vnd.github.v3+json" \
        'https://api.github.com/repos/Rikj000/Git-DeepL-Translator/releases/latest' \
        | jq .assets[0].browser_download_url)";
    exit;
}

# ANSI text coloring
GREEN='\033[0;32m';
RED='\033[0;31m';
END='\033[m';

# Loop through arguments and process them
for arg in "$@"
do
    case $arg in
        -du=*|-deeplx_url=*)
        DEEPLX_URL="${arg#*=}";
        shift
        ;;
        -ds=*|-deeplx_retry_seconds=*)
        DEEPLX_RETRY_SECONDS="${arg#*=}";
        shift
        ;;
        -ig=*|-input_git_repo_dir=*)
        INPUT_GIT_REPO_DIR="${arg#*=}";
        shift
        ;;
        -og=*|-output_git_repo_dir=*)
        OUTPUT_GIT_REPO_DIR="${arg#*=}";
        shift
        ;;
        -il=*|-input_language=*)
        INPUT_LANGUAGE="${arg#*=}";
        shift
        ;;
        -ol=*|-output_language=*)
        OUTPUT_LANGUAGE="${arg#*=}";
        shift
        ;;
        -h|-help)
        usage;
        ;;
        -u|-update)
        update;
        ;;
        *)
        echo "";
        echo -e "${RED}  🙉  git-deepl-translator - Illegal argument(s) used!${END}";
        echo "";
        echo "  Please see the 'git-deepl-translator -help' output below for the correct usage:";
        usage;
        ;;
    esac
done

echo "Setting up directory helpers...";
INSTALLATION_FILE=$(realpath "$(dirname "$0")/$(basename "$0")");
INSTALLATION_DIR=$(dirname "$INSTALLATION_FILE");

TMP_DIR="$INSTALLATION_DIR/tmp";
TMP_GIT_REPO_DIR="$TMP_DIR/git";
TMP_GIT_LOG_DIR="$TMP_DIR/git-log";
TMP_GIT_LOG_FILE="$TMP_GIT_LOG_DIR/git-log.txt";
TMP_GIT_LOG_EXPRESSIONS_FILE="$TMP_GIT_LOG_DIR/git-log-expressions.txt";

echo "Cleaning up temporary conversion directory ($TMP_DIR)...";
# shellcheck disable=SC2216
yes | rm -fr "$TMP_DIR";
mkdir "$TMP_DIR" "$TMP_GIT_LOG_DIR";

echo "Copying the Git repository input directory ($INPUT_GIT_REPO_DIR)" \
    "to the temporary Git conversion directory ($TMP_GIT_REPO_DIR)...";
cp -r "$INPUT_GIT_REPO_DIR" "$TMP_GIT_REPO_DIR";

echo "Moving to temporary Git conversion directory ($TMP_GIT_REPO_DIR)...";
cd "$TMP_GIT_REPO_DIR/" || exit;

echo "Log git commit message history to temporary git-log file ($TMP_GIT_LOG_FILE), include new-lines..."
git log --pretty=format:"%B" > "$TMP_GIT_LOG_FILE";

echo "Combining temporary git-log file ($TMP_GIT_LOG_FILE) lines with DeepLX translations" \
    "into temporary git-log expressions file ($TMP_GIT_LOG_EXPRESSIONS_FILE)...";
touch "$TMP_GIT_LOG_EXPRESSIONS_FILE";
TMP_GIT_LOG_FILE_LINES=$(wc -l < "$TMP_GIT_LOG_FILE");
for LINE_INDEX in $(seq "$TMP_GIT_LOG_FILE_LINES"); do

    ORIGINAL_LINE=$(head -n "$LINE_INDEX" "$TMP_GIT_LOG_FILE" | tail -n 1);
    # Replace 'TAB' with 'space' to prevent DeepLX from crashing
    FORMATTED_LINE=${ORIGINAL_LINE//	/ };
    FORMATTED_LINE=${FORMATTED_LINE//　/ };
    # Replace 'double quote' with 'single quote' to prevent DeepLX from crashing
    FORMATTED_LINE=${FORMATTED_LINE//\"/\'}
    # Replace '/' with '' to prevent DeepLX from crashing
    FORMATTED_LINE=${FORMATTED_LINE//\\}

    # Replace 'space' with '' to check if line empty
    if [ -z "${FORMATTED_LINE// }" ] &>/dev/null; then
        echo "Line: $LINE_INDEX - Skipping empty line...";
        continue;
    fi

    TRANSLATED_LINE="null";
    while [ "$TRANSLATED_LINE" == "null" ]; do
        TRANSLATED_LINE=$(curl -s -X POST "$DEEPLX_URL/translate" \
        -H "Content-Type: application/json" \
        -d "{
            \"text\": \"$FORMATTED_LINE\",
            \"source_lang\": \"$INPUT_LANGUAGE\",
            \"target_lang\": \"$OUTPUT_LANGUAGE\"
        }" | jq -r '.data');

        if [ "$TRANSLATED_LINE" == "null" ]; then
            echo "Line: $LINE_INDEX - Received null translation for line '$FORMATTED_LINE'," \
                "re-trying in '$DEEPLX_RETRY_SECONDS' seconds...";
            echo "Likely rate-limited, either wait it out, or switch VPN connections + restart 'deeplx' to continue...";
            sleep "$DEEPLX_RETRY_SECONDS";
        fi
    done

    # Only append if $TRANSLATED_LINE not empty
    if [ -n "$TRANSLATED_LINE" ]; then
        echo "Line: $LINE_INDEX - Appending translated line!";
        echo "$ORIGINAL_LINE==>$TRANSLATED_LINE" >> "$TMP_GIT_LOG_EXPRESSIONS_FILE";
    fi
done

echo "Replace git commit message history with temporary git-log expressions file ($TMP_GIT_LOG_EXPRESSIONS_FILE)...";
git filter-repo --force --replace-message "$TMP_GIT_LOG_EXPRESSIONS_FILE";

echo "Cleaning up Git repository output directory ($OUTPUT_GIT_REPO_DIR)...";
# shellcheck disable=SC2216
yes | rm -fr "$OUTPUT_GIT_REPO_DIR";

echo "Moving the temporary Git conversion directory ($TMP_GIT_REPO_DIR)" \
    "to Git repository output directory ($OUTPUT_GIT_REPO_DIR)...";
mv "$TMP_GIT_REPO_DIR" "$OUTPUT_GIT_REPO_DIR";

echo -e "${GREEN}git-deepl-translator has been executed to its end!${END}";
