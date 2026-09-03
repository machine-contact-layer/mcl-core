/*
 * Check registries/tier0-fields-v0.1.json against itself.
 *
 * WHY THIS EXISTS
 *
 * That registry records which Tier-0 field meanings are settled and which are
 * not, and it carries a summary block counting them. A summary counted by hand
 * is a number that drifts the first time a field changes status, and a WRONG
 * count in this particular file is the specific failure the file exists to
 * prevent: it would overstate how much of Tier-0 is interoperable.
 *
 * This was not hypothetical. The summary was written by hand as 6 assigned /
 * 9 provisional / 6 open. The real counts are 5 / 10 / 6 -- one field claimed
 * as settled that is not. The fix for a miscount is not to recount more
 * carefully; it is to stop counting by hand.
 *
 * It also enforces the rules the registry states about itself:
 *   - every field carries a status, from the three defined values
 *   - every provisional or open field says what the gap is, because a field
 *     marked unfinished with no explanation is not a record of anything
 *   - the summary matches the entries
 *   - any field carrying a v1_disposition names the decision that descoped it.
 *     That key is a SCOPE axis, kept separate from status, which is a MEANING
 *     axis: a field dropped from Stable v1 is not thereby understood.
 *
 * A minimal recursive-descent scan of the shapes this file actually uses.
 * There is no JSON library here and there will not be one: the protocol repos
 * take no dependencies.
 */

#define _CRT_SECURE_NO_WARNINGS
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_FILE_SIZE 65536

static char g_buffer[MAX_FILE_SIZE];
static size_t g_size;
static int g_failures;

static void fail(const char *fmt, const char *a)
{
    ++g_failures;
    printf("  FAIL: ");
    printf(fmt, a);
    printf("\n");
}

/*
 * Find the next occurrence of `key` as an object key at or after `from`.
 * Returns the offset just past the closing quote of the key, or (size_t)-1.
 */
static size_t find_key(const char *key, size_t from)
{
    char pattern[64];
    const char *hit;

    if (from >= g_size) {
        return (size_t)-1;
    }
    (void)snprintf(pattern, sizeof(pattern), "\"%s\"", key);
    hit = strstr(g_buffer + from, pattern);
    if (hit == NULL) {
        return (size_t)-1;
    }
    return (size_t)(hit - g_buffer) + strlen(pattern);
}

/* Read the string value that follows a key position. */
static int read_string_value(size_t pos, char *out, size_t out_size)
{
    size_t i = pos;
    size_t n = 0u;

    while (i < g_size && g_buffer[i] != '"') {
        if (g_buffer[i] == ',' || g_buffer[i] == '}' || g_buffer[i] == '[') {
            return 0;  /* not a string value */
        }
        ++i;
    }
    if (i >= g_size) {
        return 0;
    }
    ++i;
    while (i < g_size && g_buffer[i] != '"' && n + 1u < out_size) {
        out[n++] = g_buffer[i++];
    }
    out[n] = '\0';
    return 1;
}

static int read_int_value(size_t pos, int *out)
{
    size_t i = pos;

    while (i < g_size && (g_buffer[i] == ':' || isspace((unsigned char)g_buffer[i]))) {
        ++i;
    }
    if (i >= g_size || (!isdigit((unsigned char)g_buffer[i]) && g_buffer[i] != '-')) {
        return 0;
    }
    *out = atoi(g_buffer + i);
    return 1;
}

int main(int argc, char **argv)
{
    FILE *f;
    size_t pos;
    int assigned = 0, provisional = 0, open_count = 0, total = 0;
    int declared_assigned = -1, declared_provisional = -1, declared_open = -1;
    size_t fields_start;
    size_t summary_start;

    if (argc < 2) {
        printf("usage: %s <tier0-fields.json>\n", argv[0]);
        return 2;
    }

    f = fopen(argv[1], "rb");
    if (f == NULL) {
        printf("cannot open %s\n", argv[1]);
        return 2;
    }
    g_size = fread(g_buffer, 1u, sizeof(g_buffer) - 1u, f);
    fclose(f);
    g_buffer[g_size] = '\0';
    if (g_size == 0u) {
        printf("empty file\n");
        return 2;
    }

    printf("Tier-0 field registry: %s\n\n", argv[1]);

    fields_start = find_key("fields", 0u);
    summary_start = find_key("summary", 0u);
    if (fields_start == (size_t)-1 || summary_start == (size_t)-1) {
        printf("  FAIL: no \"fields\" array or no \"summary\" block\n");
        return 1;
    }

    /*
     * Walk every "name" key inside the fields array, and for each read the
     * "status" that follows it. Bounded by the summary block, so the summary's
     * own keys are never counted as entries.
     */
    pos = fields_start;
    for (;;) {
        size_t name_pos = find_key("name", pos);
        size_t status_pos;
        char name[128];
        char status[64];
        char disposition[64];
        size_t gap_pos;
        size_t before_pos;
        size_t next_name;
        size_t disp_pos;

        if (name_pos == (size_t)-1 || name_pos > summary_start) {
            break;
        }
        if (read_string_value(name_pos, name, sizeof(name)) == 0) {
            pos = name_pos;
            continue;
        }

        status_pos = find_key("status", name_pos);
        if (status_pos == (size_t)-1 ||
            read_string_value(status_pos, status, sizeof(status)) == 0) {
            fail("field %s has no status", name);
            pos = name_pos;
            continue;
        }

        ++total;
        next_name = find_key("name", status_pos);
        if (next_name == (size_t)-1 || next_name > summary_start) {
            next_name = summary_start;
        }

        if (strcmp(status, "assigned") == 0) {
            ++assigned;
        } else if (strcmp(status, "provisional") == 0) {
            ++provisional;
        } else if (strcmp(status, "open") == 0) {
            ++open_count;
        } else {
            fail("field %s has an undefined status", name);
        }

        /*
         * A field marked unfinished with no explanation is not a record of
         * anything. Whoever writes the second implementation needs to know
         * WHAT is missing, not merely that something is.
         */
        if (strcmp(status, "provisional") == 0 || strcmp(status, "open") == 0) {
            gap_pos = find_key("gap", status_pos);
            before_pos = find_key("note", status_pos);
            if ((gap_pos == (size_t)-1 || gap_pos > next_name) &&
                (before_pos == (size_t)-1 || before_pos > next_name)) {
                fail("field %s is unfinished but says nothing about the gap",
                     name);
            }
        }

        /*
         * v1_disposition is a SCOPE axis and is deliberately separate from
         * status, which is a MEANING axis. Removing a field from the Stable
         * v1 surface does not settle what it means, and folding the one into
         * the other would make the unsettled-meaning count fall every time a
         * field was merely descoped -- improving the number by giving up.
         * The two ladders in this project are kept apart for the same reason
         * conformance and evidence are.
         */
        disp_pos = find_key("v1_disposition", status_pos);
        if (disp_pos != (size_t)-1 && disp_pos < next_name) {
            if (read_string_value(disp_pos, disposition, sizeof(disposition)) == 0) {
                fail("field %s has an unreadable v1_disposition", name);
            } else if (strcmp(disposition, "removed_from_stable_v1") != 0) {
                fail("field %s has an undefined v1_disposition", name);
            } else if (find_key("v1_decision", disp_pos) == (size_t)-1 ||
                       find_key("v1_decision", disp_pos) > next_name) {
                fail("field %s is descoped but does not say which decision "
                     "descoped it", name);
            }
        }

        pos = status_pos;
    }

    (void)read_int_value(find_key("assigned", summary_start), &declared_assigned);
    (void)read_int_value(find_key("provisional", summary_start), &declared_provisional);
    (void)read_int_value(find_key("open", summary_start), &declared_open);

    printf("  counted:  assigned %d, provisional %d, open %d, total %d\n",
           assigned, provisional, open_count, total);
    printf("  declared: assigned %d, provisional %d, open %d\n",
           declared_assigned, declared_provisional, declared_open);

    if (declared_assigned != assigned) {
        ++g_failures;
        printf("  FAIL: summary claims %d assigned, there are %d\n",
               declared_assigned, assigned);
    }
    if (declared_provisional != provisional) {
        ++g_failures;
        printf("  FAIL: summary claims %d provisional, there are %d\n",
               declared_provisional, provisional);
    }
    if (declared_open != open_count) {
        ++g_failures;
        printf("  FAIL: summary claims %d open, there are %d\n",
               declared_open, open_count);
    }
    if (total == 0) {
        ++g_failures;
        printf("  FAIL: no fields found; the scan is broken, not the file\n");
    }

    printf("\n");
    if (g_failures != 0) {
        printf("%d problems.\n", g_failures);
        return 1;
    }
    printf("field registry is self-consistent.\n");
    printf("NOTE: %d of %d fields are NOT interoperable between independent\n",
           provisional + open_count, total);
    printf("      implementations. That is the honest state, not a defect here.\n");
    return 0;
}
