#define _CRT_SECURE_NO_WARNINGS
#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_FILE_SIZE 32768
#define MAX_CATEGORIES 32
#define MAX_OPCODES 64
#define MAX_SEMANTICS 64
#define MAX_STR_LEN 64

typedef struct {
    int code;
    char name[MAX_STR_LEN];
} opcode_entry_t;

typedef struct {
    int code;
    char name[MAX_STR_LEN];
    opcode_entry_t opcodes[MAX_OPCODES];
    size_t opcode_count;
} category_entry_t;

typedef struct {
    category_entry_t categories[MAX_CATEGORIES];
    size_t category_count;
} registry_data_t;

static const char *skip_ws(const char *p, const char *end)
{
    while (p < end && isspace((unsigned char)*p)) {
        ++p;
    }
    return p;
}

static const char *parse_string(const char *p, const char *end, char *out, size_t out_size)
{
    size_t len = 0;
    p = skip_ws(p, end);
    if (p >= end || *p != '\"') {
        return NULL;
    }
    ++p;
    while (p < end && *p != '\"') {
        if (*p == '\\' || len + 1 >= out_size) {
            return NULL;
        }
        out[len++] = *p++;
    }
    if (p >= end || *p != '\"') {
        return NULL;
    }
    out[len] = '\0';
    return p + 1;
}

static const char *parse_int(const char *p, const char *end, int *out)
{
    int val = 0;
    p = skip_ws(p, end);
    if (p >= end || !isdigit((unsigned char)*p)) {
        return NULL;
    }
    while (p < end && isdigit((unsigned char)*p)) {
        val = val * 10 + (*p - '0');
        ++p;
    }
    *out = val;
    return p;
}

static uint16_t pack_header(int major, int category, int opcode, int priority, int extension_present)
{
    return (uint16_t)(((major & 0x0F) << 12) |
                      ((category & 0x0F) << 8) |
                      ((opcode & 0x1F) << 3) |
                      ((priority & 0x03) << 1) |
                      (extension_present & 0x01));
}

static void unpack_header(uint16_t word, int *major, int *category, int *opcode, int *priority, int *extension_present)
{
    *major = (word >> 12) & 0x0F;
    *category = (word >> 8) & 0x0F;
    *opcode = (word >> 3) & 0x1F;
    *priority = (word >> 1) & 0x03;
    *extension_present = word & 0x01;
}

static int parse_hex_byte(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static int parse_hex_word(const char *hex, uint16_t *word)
{
    int h0, h1, h2, h3;
    if (strlen(hex) < 4) return 0;
    h0 = parse_hex_byte(hex[0]);
    h1 = parse_hex_byte(hex[1]);
    h2 = parse_hex_byte(hex[2]);
    h3 = parse_hex_byte(hex[3]);
    if (h0 < 0 || h1 < 0 || h2 < 0 || h3 < 0) return 0;
    *word = (uint16_t)((h0 << 12) | (h1 << 8) | (h2 << 4) | h3);
    return 1;
}

static int read_file(const char *path, char *buf, size_t buf_size)
{
    FILE *f = fopen(path, "rb");
    size_t n;
    if (!f) {
        perror(path);
        return 0;
    }
    n = fread(buf, 1, buf_size - 1, f);
    fclose(f);
    buf[n] = '\0';
    return 1;
}

int main(int argc, char **argv)
{
    const char *reg_path = argc > 1 ? argv[1] : "registries/semantic-codes-v0.2.json";
    const char *vec_path = argc > 2 ? argv[2] : "conformance/header-v0.2-vectors.json";
    char reg_buf[MAX_FILE_SIZE];
    char vec_buf[MAX_FILE_SIZE];
    registry_data_t reg;
    const char *p;
    const char *end;
    size_t total_semantics = 0;
    size_t i, j;
    int major, category, opcode, priority, ext;
    unsigned long roundtrip_count = 0;

    if (!read_file(reg_path, reg_buf, sizeof(reg_buf))) return 1;
    if (!read_file(vec_path, vec_buf, sizeof(vec_buf))) return 1;

    memset(&reg, 0, sizeof(reg));
    end = reg_buf + strlen(reg_buf);

    /* Validate wire header model bits */
    p = strstr(reg_buf, "\"major_version_bits\":");
    if (!p) { fprintf(stderr, "Missing major_version_bits\n"); return 1; }
    p = strstr(reg_buf, "\"total_bits\":");
    if (!p) { fprintf(stderr, "Missing total_bits\n"); return 1; }
    p += strlen("\"total_bits\":");
    {
        int total_bits = 0;
        p = parse_int(p, end, &total_bits);
        if (!p || total_bits != 16) {
            fprintf(stderr, "total_bits must be 16\n");
            return 1;
        }
    }

    /* Parse categories */
    p = strstr(reg_buf, "\"categories\":");
    if (!p) { fprintf(stderr, "Missing categories array\n"); return 1; }
    p = strchr(p, '[');
    if (!p) return 1;
    ++p;

    while (p < end) {
        category_entry_t cat;
        p = skip_ws(p, end);
        if (p >= end || *p == ']') break;
        if (*p != '{') return 1;
        ++p;
        memset(&cat, 0, sizeof(cat));

        while (p < end && *p != '}') {
            char key[MAX_STR_LEN];
            p = parse_string(p, end, key, sizeof(key));
            if (!p) return 1;
            p = skip_ws(p, end);
            if (p >= end || *p != ':') return 1;
            ++p;

            if (strcmp(key, "code") == 0) {
                p = parse_int(p, end, &cat.code);
                if (!p) return 1;
            } else if (strcmp(key, "name") == 0) {
                p = parse_string(p, end, cat.name, sizeof(cat.name));
                if (!p) return 1;
            } else if (strcmp(key, "opcodes") == 0) {
                p = skip_ws(p, end);
                if (p >= end || *p != '[') return 1;
                ++p;
                while (p < end) {
                    opcode_entry_t op;
                    p = skip_ws(p, end);
                    if (p >= end || *p == ']') break;
                    if (*p != '{') return 1;
                    ++p;
                    memset(&op, 0, sizeof(op));
                    while (p < end && *p != '}') {
                        char op_key[MAX_STR_LEN];
                        p = parse_string(p, end, op_key, sizeof(op_key));
                        if (!p) return 1;
                        p = skip_ws(p, end);
                        if (p >= end || *p != ':') return 1;
                        ++p;

                        if (strcmp(op_key, "code") == 0) {
                            p = parse_int(p, end, &op.code);
                            if (!p) return 1;
                        } else if (strcmp(op_key, "name") == 0) {
                            p = parse_string(p, end, op.name, sizeof(op.name));
                            if (!p) return 1;
                        } else {
                            /* Skip other boolean/string fields like tier0_candidate, status */
                            p = skip_ws(p, end);
                            if (*p == '\"') {
                                char dummy[MAX_STR_LEN];
                                p = parse_string(p, end, dummy, sizeof(dummy));
                            } else if (strncmp(p, "true", 4) == 0) {
                                p += 4;
                            } else if (strncmp(p, "false", 5) == 0) {
                                p += 5;
                            } else {
                                int dummy_int;
                                p = parse_int(p, end, &dummy_int);
                            }
                            if (!p) return 1;
                        }
                        p = skip_ws(p, end);
                        if (p < end && *p == ',') ++p;
                    }
                    if (p >= end || *p != '}') return 1;
                    ++p;
                    cat.opcodes[cat.opcode_count++] = op;
                    p = skip_ws(p, end);
                    if (p < end && *p == ',') ++p;
                }
                if (p >= end || *p != ']') return 1;
                ++p;
            } else {
                /* skip other category fields */
                p = skip_ws(p, end);
                if (*p == '\"') {
                    char dummy[MAX_STR_LEN];
                    p = parse_string(p, end, dummy, sizeof(dummy));
                } else {
                    int dummy_int;
                    p = parse_int(p, end, &dummy_int);
                }
                if (!p) return 1;
            }
            p = skip_ws(p, end);
            if (p < end && *p == ',') ++p;
        }
        if (p >= end || *p != '}') return 1;
        ++p;
        reg.categories[reg.category_count++] = cat;
        p = skip_ws(p, end);
        if (p < end && *p == ',') ++p;
    }

    /* Validations on registry */
    if (reg.category_count != 16) {
        fprintf(stderr, "Expected 16 categories, got %zu\n", reg.category_count);
        return 1;
    }

    for (i = 0; i < reg.category_count; ++i) {
        if (reg.categories[i].code != (int)i) {
            fprintf(stderr, "Category %zu has non-sequential code %d\n", i, reg.categories[i].code);
            return 1;
        }
        for (j = 0; j < reg.categories[i].opcode_count; ++j) {
            ++total_semantics;
        }
    }

    if (total_semantics != 20) {
        fprintf(stderr, "Expected 20 semantic opcode assignments, got %zu\n", total_semantics);
        return 1;
    }

    /* Validate conformance vectors */
    end = vec_buf + strlen(vec_buf);
    p = strstr(vec_buf, "\"vectors\":");
    if (!p) { fprintf(stderr, "Missing vectors array in vectors json\n"); return 1; }
    p = strchr(p, '[');
    if (!p) return 1;
    ++p;

    {
        size_t vector_count = 0;
        while (p < end) {
            char sem_name[MAX_STR_LEN] = {0};
            char hex_str[MAX_STR_LEN] = {0};
            int cat_code = -1;
            int op_code = -1;
            uint16_t header_word = 0;
            int dec_maj, dec_cat, dec_op, dec_pri, dec_ext;
            int found = 0;

            p = skip_ws(p, end);
            if (p >= end || *p == ']') break;
            if (*p != '{') return 1;
            ++p;

            while (p < end && *p != '}') {
                char k[MAX_STR_LEN];
                p = parse_string(p, end, k, sizeof(k));
                if (!p) return 1;
                p = skip_ws(p, end);
                if (p >= end || *p != ':') return 1;
                ++p;

                if (strcmp(k, "semantic") == 0) {
                    p = parse_string(p, end, sem_name, sizeof(sem_name));
                } else if (strcmp(k, "category") == 0) {
                    p = parse_int(p, end, &cat_code);
                } else if (strcmp(k, "opcode") == 0) {
                    p = parse_int(p, end, &op_code);
                } else if (strcmp(k, "header_hex") == 0) {
                    p = parse_string(p, end, hex_str, sizeof(hex_str));
                } else {
                    return 1;
                }
                if (!p) return 1;
                p = skip_ws(p, end);
                if (p < end && *p == ',') ++p;
            }
            if (p >= end || *p != '}') return 1;
            ++p;

            /* Check semantic against registry */
            for (i = 0; i < reg.category_count; ++i) {
                for (j = 0; j < reg.categories[i].opcode_count; ++j) {
                    if (strcmp(reg.categories[i].opcodes[j].name, sem_name) == 0) {
                        if (reg.categories[i].code != cat_code || reg.categories[i].opcodes[j].code != op_code) {
                            fprintf(stderr, "Vector %s code mismatch\n", sem_name);
                            return 1;
                        }
                        found = 1;
                        break;
                    }
                }
                if (found) break;
            }
            if (!found) {
                fprintf(stderr, "Semantic %s not found in registry\n", sem_name);
                return 1;
            }

            if (!parse_hex_word(hex_str, &header_word)) {
                fprintf(stderr, "Invalid header_hex: %s\n", hex_str);
                return 1;
            }
            unpack_header(header_word, &dec_maj, &dec_cat, &dec_op, &dec_pri, &dec_ext);
            if (dec_maj != 0 || dec_cat != cat_code || dec_op != op_code || dec_ext != 0) {
                fprintf(stderr, "Decoded vector mismatch for %s\n", sem_name);
                return 1;
            }

            ++vector_count;
            p = skip_ws(p, end);
            if (p < end && *p == ',') ++p;
        }

        if (vector_count != total_semantics) {
            fprintf(stderr, "Vector count %zu does not match semantic count %zu\n", vector_count, total_semantics);
            return 1;
        }
    }

    /* Exhaustive 65,536 common-header round trip test */
    for (major = 0; major < 16; ++major) {
        for (category = 0; category < 16; ++category) {
            for (opcode = 0; opcode < 32; ++opcode) {
                for (priority = 0; priority < 4; ++priority) {
                    for (ext = 0; ext < 2; ++ext) {
                        uint16_t w = pack_header(major, category, opcode, priority, ext);
                        int g_maj, g_cat, g_op, g_pri, g_ext;
                        unpack_header(w, &g_maj, &g_cat, &g_op, &g_pri, &g_ext);
                        if (g_maj != major || g_cat != category || g_op != opcode || g_pri != priority || g_ext != ext) {
                            fprintf(stderr, "Round-trip failure for %d %d %d %d %d\n", major, category, opcode, priority, ext);
                            return 1;
                        }
                        ++roundtrip_count;
                    }
                }
            }
        }
    }

    if (roundtrip_count != 65536ul) {
        fprintf(stderr, "Expected 65536 roundtrips, got %lu\n", roundtrip_count);
        return 1;
    }

    printf("registry semantic assignments: %zu\n", total_semantics);
    printf("header states round-tripped: %lu\n", roundtrip_count);
    puts("OK");
    return 0;
}
