#include <stdio.h>
#include <string.h>

char src[] = "CBA";
char rules[] = "CB=BC;CA=AC;BA=AB";

int main() {
    int srcIdx = 0, rulesIdx = 0, segmentLen = 0;

    while (srcIdx < strlen(src) && rulesIdx < strlen(rules)) {
        if (src[srcIdx] == rules[rulesIdx]) {
            srcIdx++;
            segmentLen++;
            rulesIdx++;
            if (rules[rulesIdx] == '=') {
                int count = 0;

                rulesIdx++;
                srcIdx -= segmentLen;
                while (count < segmentLen) {
                    src[srcIdx] = rules[rulesIdx];
                    count++;
                    srcIdx++;
                    rulesIdx++;
                }
                
                srcIdx = 0;
                rulesIdx = 0;
                segmentLen = 0;
                continue;
            }
        } else {
            srcIdx -= segmentLen;
            segmentLen = 0;

            // Skips to next ';' or end of string
            while (rulesIdx < strlen(rules) && rules[rulesIdx] != ';') {
                rulesIdx++;
            }

            rulesIdx++;

            // No rules to apply
            if (rulesIdx >= strlen(rules)) {
                srcIdx++;
                rulesIdx = 0;
            }
        }
    }

    printf("%s\n", src);

    return 1;
}
