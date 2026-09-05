/*
 * Validator for MCL deployment profiles.
 *
 * `mcl-core/schema/deployment-profile-v1.md` is the prose; this is the
 * executable form. There is no JSON Schema file on purpose: nothing in this
 * toolchain enforces JSON Schema, so a third description of the same rules
 * would drift from the other two the moment any of them changed.
 *
 *   validate_deployment_profile <profile.json>...
 *
 * Reports two independent things, because conflating them hides both:
 *
 *   VALIDITY        the profile obeys the schema. Failure exits non-zero.
 *   SATISFIABILITY  everything it requires exists today. A profile naming
 *                   AP-BOOTSTRAP-1 is correctly written and PENDING, because
 *                   that profile has not been specified yet. That is a fact
 *                   about MCL, not an error in the deployment.
 *
 * The parser is hand-rolled and dependency-free, matching validate_registry.c
 * and validate_field_registry.c. It is a checker, not a general JSON library:
 * it refuses what it does not understand rather than skipping it, which is the
 * behaviour a validator needs and a parser usually does not have.
 */

#define _CRT_SECURE_NO_WARNINGS
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_FILE_SIZE   65536
#define MAX_STR         128
#define MAX_ENTRIES     16

/* ------------------------------------------------------------------ model */

typedef struct {
    char transport[MAX_STR];
    long transport_id;
    char profile[MAX_STR];
    long profile_id;
} bearer_t;

typedef struct {
    char schema[MAX_STR];
    char profile_id[MAX_STR];
    long revision;

    long wire_major;
    long link_major;
    char conformance_layer[MAX_STR];
    char bootstrap_profile[MAX_STR];
    int  has_bootstrap;

    bearer_t mandatory[MAX_ENTRIES];
    size_t   mandatory_count;
    bearer_t optional[MAX_ENTRIES];
    size_t   optional_count;

    int security_profile_null;
    int has_security;
} profile_t;

static int g_errors;
static int g_pending;

static void fail(const char *path, const char *msg)
{
    printf("  FAIL %s: %s\n", path, msg);
    g_errors++;
}

/* ----------------------------------------------------------------- lexer */

static const char *skip_ws(const char *p, const char *end)
{
    while (p < end && isspace((unsigned char)*p)) ++p;
    return p;
}

static const char *parse_string(const char *p, const char *end,
                                char *out, size_t out_size)
{
    size_t len = 0u;
    p = skip_ws(p, end);
    if (p >= end || *p != '"') return NULL;
    ++p;
    while (p < end && *p != '"') {
        if (*p == '\\') return NULL;         /* no escapes in this dialect */
        if (len + 1u >= out_size) return NULL;
        out[len++] = *p++;
    }
    if (p >= end) return NULL;
    out[len] = '\0';
    return p + 1;
}

static const char *parse_long(const char *p, const char *end, long *out)
{
    char buf[32];
    size_t len = 0u;
    p = skip_ws(p, end);
    while (p < end && (isdigit((unsigned char)*p) || *p == '-')) {
        if (len + 1u >= sizeof(buf)) return NULL;
        buf[len++] = *p++;
    }
    if (len == 0u) return NULL;
    buf[len] = '\0';
    *out = strtol(buf, NULL, 10);
    return p;
}

static const char *expect(const char *p, const char *end, char c)
{
    p = skip_ws(p, end);
    if (p >= end || *p != c) return NULL;
    return p + 1;
}

/* --------------------------------------------------- peer-specific scan */

/*
 * Schema section 4. A deployment profile that could carry a peer address would
 * let the two-builder acceptance test be passed by prearrangement, which is the
 * exact failure that test exists to detect. Unknown keys are already refused by
 * the parser; this catches an address smuggled through a legitimately-named
 * field.
 */
static int looks_like_ipv4(const char *s)
{
    int groups = 0, digits = 0;
    for (; *s; ++s) {
        if (isdigit((unsigned char)*s)) { if (++digits > 3) return 0; }
        else if (*s == '.') { if (digits == 0) return 0; digits = 0; ++groups; }
        else return 0;
    }
    return (groups == 3 && digits > 0);
}

static int looks_like_mac_or_ipv6(const char *s)
{
    int seps = 0, hex = 0;
    for (; *s; ++s) {
        if (isxdigit((unsigned char)*s)) { ++hex; }
        else if (*s == ':' || *s == '-') { ++seps; }
        else return 0;
    }
    return (seps >= 2 && hex >= 4);
}

static void scan_value(const char *path, const char *key, const char *value)
{
    if (looks_like_ipv4(value) || looks_like_mac_or_ipv6(value)) {
        char msg[MAX_STR * 4];
        snprintf(msg, sizeof(msg),
                 "peer-specific address in field '%s' (schema section 4): %s",
                 key, value);
        fail(path, msg);
    }
}

/* ---------------------------------------------------------- bearer array */

static const char *parse_bearer_array(const char *p, const char *end,
                                      const char *path,
                                      bearer_t *out, size_t *count)
{
    char key[MAX_STR];
    *count = 0u;

    p = expect(p, end, '[');
    if (p == NULL) return NULL;
    p = skip_ws(p, end);
    if (p < end && *p == ']') return p + 1;

    for (;;) {
        bearer_t b;
        int seen_transport = 0, seen_tid = 0, seen_profile = 0, seen_pid = 0;

        memset(&b, 0, sizeof(b));
        p = expect(p, end, '{');
        if (p == NULL) return NULL;

        for (;;) {
            p = parse_string(p, end, key, sizeof(key));
            if (p == NULL) return NULL;
            p = expect(p, end, ':');
            if (p == NULL) return NULL;

            if (strcmp(key, "transport") == 0) {
                p = parse_string(p, end, b.transport, sizeof(b.transport));
                seen_transport = 1;
                if (p) scan_value(path, key, b.transport);
            } else if (strcmp(key, "profile") == 0) {
                p = parse_string(p, end, b.profile, sizeof(b.profile));
                seen_profile = 1;
                if (p) scan_value(path, key, b.profile);
            } else if (strcmp(key, "transport_id") == 0) {
                p = parse_long(p, end, &b.transport_id);
                seen_tid = 1;
            } else if (strcmp(key, "profile_id") == 0) {
                p = parse_long(p, end, &b.profile_id);
                seen_pid = 1;
            } else {
                fail(path, "unknown key in continuation entry");
                return NULL;
            }
            if (p == NULL) return NULL;

            p = skip_ws(p, end);
            if (p < end && *p == ',') { ++p; continue; }
            break;
        }
        p = expect(p, end, '}');
        if (p == NULL) return NULL;

        if (!seen_transport || !seen_tid || !seen_profile || !seen_pid) {
            fail(path, "continuation entry missing a required field");
            return NULL;
        }
        if (*count >= MAX_ENTRIES) {
            fail(path, "too many continuation entries");
            return NULL;
        }
        out[(*count)++] = b;

        p = skip_ws(p, end);
        if (p < end && *p == ',') { ++p; continue; }
        break;
    }
    return expect(p, end, ']');
}

/* ------------------------------------------------------ registry lookup */

/*
 * Cross-check against the real transport registries rather than a table
 * compiled in here. A copy would be a second source of truth, and the point of
 * the check is that a deployment cannot require of its members something the
 * registry says is Experimental Use and therefore committed to replacement.
 */
static int registry_status(const char *root, long transport_id, long profile_id,
                           char *status_out, size_t status_size)
{
    char path[512];
    static char buf[MAX_FILE_SIZE];
    FILE *f;
    size_t n;
    const char *p, *end;
    char needle[64];

    if (transport_id == 2) {
        snprintf(path, sizeof(path), "%s/mcl-ip/registries/ip-profiles-v0.1.json", root);
    } else if (transport_id == 3) {
        snprintf(path, sizeof(path), "%s/mcl-ble/registries/ble-profiles-v0.1.json", root);
    } else if (transport_id == 1) {
        snprintf(path, sizeof(path), "%s/mcl-ap/registries/ap-profiles-v0.1.json", root);
    } else {
        return -1;
    }

    f = fopen(path, "rb");
    if (f == NULL) return -2;
    n = fread(buf, 1u, sizeof(buf) - 1u, f);
    fclose(f);
    buf[n] = '\0';

    /* Find "id": <profile_id> then the "status" that follows it. */
    snprintf(needle, sizeof(needle), "\"id\": %ld", profile_id);
    p = strstr(buf, needle);
    if (p == NULL) {
        snprintf(needle, sizeof(needle), "\"id\":%ld", profile_id);
        p = strstr(buf, needle);
    }
    if (p == NULL) return -3;

    end = buf + n;
    p = strstr(p, "\"status\"");
    if (p == NULL || p >= end) return -3;
    p = strchr(p, ':');
    if (p == NULL) return -3;
    ++p;
    if (parse_string(p, end, status_out, status_size) == NULL) return -3;
    return 0;
}

/* -------------------------------------------------------------- validate */

static int validate(const char *root, const char *path)
{
    static char buf[MAX_FILE_SIZE];
    profile_t prof;
    FILE *f;
    size_t n;
    const char *p, *end;
    char key[MAX_STR];
    size_t i;
    int stranger_or_above;
    int before = g_errors;

    memset(&prof, 0, sizeof(prof));
    prof.wire_major = -1;
    prof.link_major = -1;

    f = fopen(path, "rb");
    if (f == NULL) { fail(path, "cannot open"); return 1; }
    n = fread(buf, 1u, sizeof(buf) - 1u, f);
    fclose(f);
    buf[n] = '\0';
    p = buf;
    end = buf + n;

    /* A UTF-8 BOM is not part of the document. */
    if (n >= 3u && (unsigned char)buf[0] == 0xEFu) p = buf + 3;

    p = expect(p, end, '{');
    if (p == NULL) { fail(path, "not a JSON object"); return 1; }

    for (;;) {
        p = parse_string(p, end, key, sizeof(key));
        if (p == NULL) { fail(path, "bad key"); return 1; }
        p = expect(p, end, ':');
        if (p == NULL) { fail(path, "expected ':'"); return 1; }

        if (strcmp(key, "schema") == 0) {
            p = parse_string(p, end, prof.schema, sizeof(prof.schema));
        } else if (strcmp(key, "profile_id") == 0) {
            p = parse_string(p, end, prof.profile_id, sizeof(prof.profile_id));
            if (p) scan_value(path, key, prof.profile_id);
        } else if (strcmp(key, "revision") == 0) {
            p = parse_long(p, end, &prof.revision);
        } else if (strcmp(key, "requires") == 0) {
            p = expect(p, end, '{');
            if (p == NULL) { fail(path, "requires is not an object"); return 1; }
            for (;;) {
                p = parse_string(p, end, key, sizeof(key));
                if (p == NULL) { fail(path, "bad key in requires"); return 1; }
                p = expect(p, end, ':');
                if (p == NULL) return 1;
                if (strcmp(key, "wire_major") == 0) {
                    p = parse_long(p, end, &prof.wire_major);
                } else if (strcmp(key, "link_major") == 0) {
                    p = parse_long(p, end, &prof.link_major);
                } else if (strcmp(key, "conformance_layer") == 0) {
                    p = parse_string(p, end, prof.conformance_layer,
                                     sizeof(prof.conformance_layer));
                } else if (strcmp(key, "bootstrap_profile") == 0) {
                    p = parse_string(p, end, prof.bootstrap_profile,
                                     sizeof(prof.bootstrap_profile));
                    prof.has_bootstrap = 1;
                } else {
                    fail(path, "unknown key in requires");
                    return 1;
                }
                if (p == NULL) { fail(path, "bad value in requires"); return 1; }
                p = skip_ws(p, end);
                if (p < end && *p == ',') { ++p; continue; }
                break;
            }
            p = expect(p, end, '}');
        } else if (strcmp(key, "continuation") == 0) {
            p = expect(p, end, '{');
            if (p == NULL) { fail(path, "continuation is not an object"); return 1; }
            for (;;) {
                p = parse_string(p, end, key, sizeof(key));
                if (p == NULL) { fail(path, "bad key in continuation"); return 1; }
                p = expect(p, end, ':');
                if (p == NULL) return 1;
                if (strcmp(key, "mandatory") == 0) {
                    p = parse_bearer_array(p, end, path, prof.mandatory,
                                           &prof.mandatory_count);
                } else if (strcmp(key, "optional") == 0) {
                    p = parse_bearer_array(p, end, path, prof.optional,
                                           &prof.optional_count);
                } else {
                    fail(path, "unknown key in continuation");
                    return 1;
                }
                if (p == NULL) { fail(path, "bad continuation array"); return 1; }
                p = skip_ws(p, end);
                if (p < end && *p == ',') { ++p; continue; }
                break;
            }
            p = expect(p, end, '}');
        } else if (strcmp(key, "security") == 0) {
            prof.has_security = 1;
            p = expect(p, end, '{');
            if (p == NULL) { fail(path, "security is not an object"); return 1; }
            p = parse_string(p, end, key, sizeof(key));
            if (p == NULL || strcmp(key, "profile") != 0) {
                fail(path, "security must contain exactly 'profile'");
                return 1;
            }
            p = expect(p, end, ':');
            if (p == NULL) return 1;
            p = skip_ws(p, end);
            if (p + 4 <= end && strncmp(p, "null", 4) == 0) {
                prof.security_profile_null = 1;
                p += 4;
            } else {
                fail(path, "security.profile must be null in v1: no named "
                           "security profile exists yet");
                return 1;
            }
            p = expect(p, end, '}');
        } else {
            fail(path, "unknown top-level key");
            return 1;
        }

        if (p == NULL) { fail(path, "bad value"); return 1; }
        p = skip_ws(p, end);
        if (p < end && *p == ',') { ++p; continue; }
        break;
    }
    if (expect(p, end, '}') == NULL) { fail(path, "trailing content"); return 1; }

    /* ---- schema section 3.1 ---- */

    if (strcmp(prof.schema, "mcl-deployment-profile/v1") != 0) {
        fail(path, "schema must be exactly 'mcl-deployment-profile/v1'");
    }
    {
        size_t len = strlen(prof.profile_id);
        if (len < 3u || len > 64u) {
            fail(path, "profile_id must be 3-64 characters");
        }
        for (i = 0u; i < len; ++i) {
            char c = prof.profile_id[i];
            if (!((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-')) {
                fail(path, "profile_id must be A-Z, 0-9 and '-' only");
                break;
            }
        }
    }
    if (prof.revision < 1) fail(path, "revision must be >= 1");
    if (prof.wire_major != 1) fail(path, "requires.wire_major must be 1");
    if (prof.link_major != 1) fail(path, "requires.link_major must be 1");
    if (!prof.has_security) fail(path, "security block is required");

    stranger_or_above = 0;
    if (strcmp(prof.conformance_layer, "MCL Base 1") == 0) {
        stranger_or_above = 0;
    } else if (strcmp(prof.conformance_layer, "MCL Stranger-Contact 1") == 0 ||
               strcmp(prof.conformance_layer, "MCL Secure-Stranger 1") == 0) {
        stranger_or_above = 1;
    } else {
        fail(path, "requires.conformance_layer names no layer in "
                   "spec/conformance-profiles-v1.md");
    }

    if (stranger_or_above && !prof.has_bootstrap) {
        fail(path, "a stranger-contact layer requires a bootstrap_profile");
    }
    if (!stranger_or_above && prof.has_bootstrap) {
        fail(path, "MCL Base 1 must not name a bootstrap_profile: a foundation "
                   "deployment has an arranged bearer and no rendezvous "
                   "requirement (schema section 3.1)");
    }

    /* Duplicate transports across the two lists would make "optional" a lie. */
    for (i = 0u; i < prof.mandatory_count; ++i) {
        size_t j;
        for (j = 0u; j < prof.optional_count; ++j) {
            if (prof.mandatory[i].transport_id == prof.optional[j].transport_id &&
                prof.mandatory[i].profile_id  == prof.optional[j].profile_id) {
                fail(path, "the same transport/profile is both mandatory and optional");
            }
        }
        for (j = i + 1u; j < prof.mandatory_count; ++j) {
            if (prof.mandatory[i].transport_id == prof.mandatory[j].transport_id &&
                prof.mandatory[i].profile_id  == prof.mandatory[j].profile_id) {
                fail(path, "duplicate mandatory continuation entry");
            }
        }
    }

    /* ---- registry cross-check ---- */
    for (i = 0u; i < prof.mandatory_count; ++i) {
        char status[MAX_STR];
        int rc = registry_status(root, prof.mandatory[i].transport_id,
                                 prof.mandatory[i].profile_id,
                                 status, sizeof(status));
        if (rc == -1) {
            fail(path, "mandatory entry names an unassigned transport_id");
        } else if (rc == -2) {
            fail(path, "cannot read the registry for a mandatory transport");
        } else if (rc == -3) {
            fail(path, "mandatory entry names a profile_id absent from its registry");
        } else if (strcmp(status, "stable") != 0) {
            char msg[MAX_STR * 4];
            snprintf(msg, sizeof(msg),
                    "mandatory entry requires profile_id %ld, which the "
                         "registry marks '%s' -- a deployment cannot require "
                         "what the project has committed to replacing",
                    prof.mandatory[i].profile_id, status);
            fail(path, msg);
        }
    }

    if (g_errors != before) return 1;

    /* ---- report, deriving guarantees from content ---- */

    printf("  OK   %s  (%s, revision %ld)\n",
           path, prof.profile_id, prof.revision);
    printf("         layer      %s\n", prof.conformance_layer);
    printf("         guarantees MEET       %s\n",
           stranger_or_above ? "yes" : "no (arranged bearer assumed)");
    printf("         guarantees CONTINUE   %s",
           prof.mandatory_count > 0u ? "yes" : "no");
    for (i = 0u; i < prof.mandatory_count; ++i) {
        printf("%s%s/%ld", i == 0u ? " -- " : ", ",
               prof.mandatory[i].profile, prof.mandatory[i].profile_id);
    }
    printf("\n");
    printf("         guarantees SECURE     no (no named security profile exists)\n");

    if (prof.has_bootstrap) {
        /* Satisfiability, reported separately from validity. */
        printf("         PENDING    bootstrap_profile '%s' is not specified yet;"
               " the profile is correctly written and waiting on MCL\n",
               prof.bootstrap_profile);
        g_pending++;
    }
    return 0;
}

int main(int argc, char **argv)
{
    const char *root = ".";
    int i, first = 1;

    if (argc < 2) {
        fprintf(stderr, "usage: validate_deployment_profile [--root DIR] "
                        "<profile.json>...\n");
        return 2;
    }
    for (i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--root") == 0 && i + 1 < argc) {
            root = argv[++i];
            continue;
        }
        if (first) { printf("=== deployment profiles ===\n"); first = 0; }
        validate(root, argv[i]);
    }

    printf("\n%d error(s), %d pending\n", g_errors, g_pending);
    return g_errors == 0 ? 0 : 1;
}
