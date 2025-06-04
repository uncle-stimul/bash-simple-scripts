#!/bin/bash
BIG_DIRS=$(du -ahx / | sort -rh | head -5)
BIG_FILES=$(find / -mount -type f -size +256M 2>/dev/null)
DOCKER_DATA=$(command docker system df)

[ -n "$BIG_DIRS" ] \
        && echo -e "\033[32mСписок больших каталогов:\033[0m\n$BIG_DIRS"

[ -n "$BIG_FILES" ] \
        && echo -e "\033[32mСписок больших файлов (>256МБ):\033[0m\n$BIG_FILES"

[ -n "$DOCKER_DATA" ] \
        && echo -e "\033[32mЗанимаемая память для docker:\033[0m\n$DOCKER_DATA"

unset BIF_DIRS
unset BIG_FILES
unset DOCKER_DATA