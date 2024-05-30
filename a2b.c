#include <stdio.h>
#include <string.h>

#define RULES_MAX_LENGTH 100
#define SRC_MAX_LENGTH 100

char src[SRC_MAX_LENGTH];
char rules[RULES_MAX_LENGTH];
char replacement[SRC_MAX_LENGTH];

void replace_segment(int startIdx, int segmentLen, const char replacement[], int replacementLen) {
    int srcLen = strlen(src);
    if (segmentLen == replacementLen) {
        for (int i = 0; i < replacementLen; i++) {
            src[startIdx + i] = replacement[i];
        }
    } else if (segmentLen > replacementLen) {
        for (int i = 0; i < replacementLen; i++) {
            src[startIdx + i] = replacement[i];
        }
        for (int i = startIdx + replacementLen; i < srcLen - (segmentLen - replacementLen); i++) {
            src[i] = src[i + (segmentLen - replacementLen)];
        }
        src[srcLen - (segmentLen - replacementLen)] = '\0';
    } else {
        for (int i = srcLen; i >= startIdx + segmentLen; i--) {
            src[i + (replacementLen - segmentLen)] = src[i];
        }
        for (int i = 0; i < replacementLen; i++) {
            src[startIdx + i] = replacement[i];
        }
    }
}

int main() {
    int srcIdx = 0, rulesIdx = 0, segmentLen = 0;
    int srcLen, rulesLen;

    printf("Enter src:\n");
    fgets(src, SRC_MAX_LENGTH, stdin);

    printf("Enter replacement rules:\n");
    fgets(rules, RULES_MAX_LENGTH, stdin);

    srcLen = strlen(src);
    if (srcLen > 0 && src[srcLen - 1] == '\n') {
        src[srcLen - 1] = '\0';
    }

    rulesLen = strlen(rules);
    if (rulesLen > 0 && rules[rulesLen - 1] == '\n') {
        rules[rulesLen - 1] = '\0';
    }

    while (1) {
        srcIdx = 0;
        rulesIdx = 0;
        segmentLen = 0;

        while (srcIdx < strlen(src) && rulesIdx < strlen(rules)) {
            if (src[srcIdx] == rules[rulesIdx]) {
                srcIdx++;
                segmentLen++;
                rulesIdx++;

                if (rules[rulesIdx] == '=') {
                    rulesIdx++;
                    int replaceStartIdx = srcIdx - segmentLen;
                    int replacementLen = 0;

                    while (rules[rulesIdx] != ';' && rules[rulesIdx] != '\0') {
                        if (replacementLen < SRC_MAX_LENGTH - 1) {
                            replacement[replacementLen] = rules[rulesIdx];
                        }
                        replacementLen++;
                        rulesIdx++;
                    }
                    replacement[replacementLen] = '\0';

                    replace_segment(replaceStartIdx, segmentLen, replacement, replacementLen);

                    srcIdx = 0;
                    rulesIdx = 0;
                    segmentLen = 0;
                    continue;
                }
            } else {
                srcIdx -= segmentLen;
                segmentLen = 0;
                while (rulesIdx < strlen(rules) && rules[rulesIdx] != ';') {
                    rulesIdx++;
                }
                rulesIdx++;
                if (rulesIdx >= strlen(rules)) {
                    srcIdx++;
                    rulesIdx = 0;
                }
            }
        }

        if (srcIdx == strlen(src)) {
            break;
        }
    }

    printf("ANSWER:\n%s\n", src);

    return 0;
}
