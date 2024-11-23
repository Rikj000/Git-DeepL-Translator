#!/bin/bash
# Author: Rikj000

# Dependencies
# - git: https://archlinux.org/packages/extra/x86_64/git/
# - git-filter-repo: https://archlinux.org/packages/extra/any/git-filter-repo/
# - deepl-cli: https://kojix2.github.io/deepl-cli/

# ToDo - Switch to input arguments
# == SETTINGS ==========================================================================================================
DEEPL_AUTH_KEY="";
DEEPL_FREE_API=true;
DEEPL_FREE_LINES_PER_BATCH=1000;
GIT_REPO_INPUT_DIR="";
GIT_REPO_OUTPUT_DIR="";
INPUT_LANGUAGE="JA";
OUTPUT_LANGUAGE="EN";
# == SETTINGS ==========================================================================================================

# ANSI text coloring
GREEN='\033[0;32m';
RED='\033[0;31m';
END='\033[m';

echo "Setting up directory helpers...";
INSTALLATION_FILE=$(realpath "$(dirname "$0")/$(basename "$0")");
INSTALLATION_DIR=$(dirname "$INSTALLATION_FILE");

TMP_DIR="$INSTALLATION_DIR/tmp";
TMP_GIT_REPO_DIR="$TMP_DIR/git";
TMP_GIT_LOG_DIR="$TMP_DIR/git-log";
TMP_GIT_LOG_FILE="$TMP_GIT_LOG_DIR/git-log.txt";
TMP_GIT_LOG_TRANSLATED_FILE="$TMP_GIT_LOG_DIR/git-log-translated.txt";
TMP_GIT_LOG_EXPRESSIONS_FILE="$TMP_GIT_LOG_DIR/git-log-expressions.txt";

echo "Cleaning up temporary conversion directory ($TMP_DIR)...";
# shellcheck disable=SC2216
yes | rm -fr "$TMP_DIR";
mkdir "$TMP_DIR" "$TMP_GIT_LOG_DIR";

echo "Copying the Git repository input directory ($GIT_REPO_INPUT_DIR)" \
    "to the temporary Git conversion directory ($TMP_GIT_REPO_DIR)...";
cp -r "$GIT_REPO_INPUT_DIR" "$TMP_GIT_REPO_DIR";

echo "Moving to temporary Git conversion directory ($TMP_GIT_REPO_DIR)...";
cd "$GIT_REPO_INPUT_DIR/" || exit;

echo "Log git commit message history to temporary git-log file ($TMP_GIT_LOG_FILE), include new-lines..."
git log --pretty=format:"%B" > "$TMP_GIT_LOG_FILE";

echo "Moving to the installation directory... ($INSTALLATION_DIR)";
cd "$INSTALLATION_DIR/" || exit;

TMP_GIT_LOG_FILE_LINES=$(wc -l < "$TMP_GIT_LOG_FILE");
if [ $DEEPL_FREE_API ]; then
    touch "$TMP_GIT_LOG_TRANSLATED_FILE";
    DEEPL_BATCHES_FLOAT=$(bc -l <<< "$TMP_GIT_LOG_FILE_LINES/$DEEPL_FREE_LINES_PER_BATCH");
    DEEPL_BATCHES_INT=$(echo "($DEEPL_BATCHES_FLOAT+0.5)/1" | bc);

    echo "Splitting total of '$TMP_GIT_LOG_FILE_LINES' lines into '$DEEPL_BATCHES_INT' batches" \
        "of max '$DEEPL_FREE_LINES_PER_BATCH' lines per batch...";
    for BATCH_INDEX in $(seq "$DEEPL_BATCHES_INT"); do
        DEEPL_BATCH_HEAD_INT=$(bc <<< "$BATCH_INDEX*$DEEPL_FREE_LINES_PER_BATCH");
        TMP_GIT_LOG_BATCH_FILE="$TMP_GIT_LOG_DIR/git-log-$BATCH_INDEX.txt";
        TMP_GIT_LOG_TRANSLATED_BATCH_FILE="$TMP_GIT_LOG_DIR/git-log-translated-$BATCH_INDEX.txt";

        if [ "$BATCH_INDEX" -ne "$DEEPL_BATCHES_INT" ]; then
            echo "Converting '$DEEPL_FREE_LINES_PER_BATCH' lines in batch '$BATCH_INDEX/$DEEPL_BATCHES_INT'...";
            head -n "$DEEPL_BATCH_HEAD_INT" "$TMP_GIT_LOG_FILE" | \
            tail -n "$DEEPL_FREE_LINES_PER_BATCH" > "$TMP_GIT_LOG_BATCH_FILE";
        else
            # Handle last iteration
            DEEPL_BATCH_TAIL_INT=$(
                bc <<< "$TMP_GIT_LOG_FILE_LINES-(($DEEPL_BATCHES_INT-1)*$DEEPL_FREE_LINES_PER_BATCH)");
            echo "Converting '$DEEPL_BATCH_TAIL_INT' lines in batch '$BATCH_INDEX/$DEEPL_BATCHES_INT'...";
            tail -n "$DEEPL_BATCH_TAIL_INT" "$TMP_GIT_LOG_FILE" > "$TMP_GIT_LOG_BATCH_FILE";
        fi

        echo "Converting batch '$BATCH_INDEX/$DEEPL_BATCHES_INT'" \
            "to temporary git-log translated batch file ($TMP_GIT_LOG_BATCH_FILE)...";
        DEEPL_AUTH_KEY="$DEEPL_AUTH_KEY" deepl \
            "$TMP_GIT_LOG_BATCH_FILE" \
            --output "$TMP_GIT_LOG_TRANSLATED_BATCH_FILE" \
            --from "$INPUT_LANGUAGE" \
            --to "$OUTPUT_LANGUAGE";

        echo "Appending temporary git-log translated batch file ($TMP_GIT_LOG_BATCH_FILE)" \
            "to temporary git-log translated file ($TMP_GIT_LOG_TRANSLATED_FILE)..."
        cat "$TMP_GIT_LOG_TRANSLATED_BATCH_FILE" >> "$TMP_GIT_LOG_TRANSLATED_FILE";
    done
else
    echo "Converting all '$TMP_GIT_LOG_FILE_LINES' lines in one batch" \
        "to temporary git-log translated file ($TMP_GIT_LOG_TRANSLATED_FILE)...";
    DEEPL_AUTH_KEY="$DEEPL_AUTH_KEY" deepl \
        "$TMP_GIT_LOG_FILE" \
        --output "$TMP_GIT_LOG_TRANSLATED_FILE" \
        --from "$INPUT_LANGUAGE" \
        --to "$OUTPUT_LANGUAGE";
fi

echo "Combining temporary git-log file ($TMP_GIT_LOG_FILE)" \
    "with temporary git-log translated file ($TMP_GIT_LOG_TRANSLATED_FILE)" \
    "into temporary git-log expressions file ($TMP_GIT_LOG_EXPRESSIONS_FILE)...";
touch "$TMP_GIT_LOG_EXPRESSIONS_FILE";
for LINE_INDEX in $(seq "$TMP_GIT_LOG_FILE_LINES"); do
    ORIGINAL_LINE=$(head -n "$LINE_INDEX" "$TMP_GIT_LOG_FILE" | tail -n 1);
    TRANSLATED_LINE=$(head -n "$LINE_INDEX" "$TMP_GIT_LOG_TRANSLATED_FILE" | tail -n 1);
    echo "$ORIGINAL_LINE==>$TRANSLATED_LINE" >> "$TMP_GIT_LOG_EXPRESSIONS_FILE";
done

echo "Moving to temporary Git conversion directory ($TMP_GIT_REPO_DIR)...";
cd "$GIT_REPO_INPUT_DIR/" || exit;

echo "Replace git commit message history with temporary git-log expressions file ($TMP_GIT_LOG_EXPRESSIONS_FILE)...";
git filter-repo --force --replace-message "$TMP_GIT_LOG_EXPRESSIONS_FILE";

echo "Cleaning up Git repository output directory ($GIT_REPO_OUTPUT_DIR)...";
# shellcheck disable=SC2216
yes | rm -fr "$GIT_REPO_OUTPUT_DIR";

echo "Moving the temporary Git conversion directory ($TMP_GIT_REPO_DIR)" \
    "to Git repository output directory ($GIT_REPO_OUTPUT_DIR)...";
mv "$TMP_GIT_REPO_DIR" "$GIT_REPO_OUTPUT_DIR";

echo -e "${GREEN}git-deepl-translator has been executed to its end!${END}";
