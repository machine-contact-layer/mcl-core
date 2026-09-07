/*
 * The reference-C side of the C4 exchange.
 *
 * Release gate item 16. Driven by test_independent.py, which holds the
 * independent implementation. This program does exactly one operation per
 * invocation and communicates only in hex, so the two implementations exchange
 * BYTES and nothing else -- no shared struct, no shared header, no in-process
 * call. Anything not in those bytes cannot be carrying the protocol.
 *
 * Usage:  cross_check <verb> [hex]
 *
 * Exit code 0 means the operation succeeded; stdout carries the answer. Any
 * non-zero exit is a refusal, which is as much a part of the comparison as an
 * acceptance: two implementations that accept the same good input and disagree
 * about bad input are not interoperable.
 */

#include "mcl/wire.h"
#include "mcl/link.h"
#include "mcl/negotiation.h"
#include "mcl/ip_binding.h"
#include "mcl/ble_binding.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static size_t from_hex(const char *text, uint8_t *out, size_t capacity)
{
    size_t len = strlen(text);
    size_t i;

    if ((len % 2u) != 0u || (len / 2u) > capacity) {
        return 0u;
    }
    for (i = 0u; i < len; i += 2u) {
        unsigned value = 0u;
        if (sscanf(text + i, "%2x", &value) != 1) {
            return 0u;
        }
        out[i / 2u] = (uint8_t)value;
    }
    return len / 2u;
}

static void print_hex(const uint8_t *data, size_t size)
{
    size_t i;
    for (i = 0u; i < size; ++i) {
        printf("%02x", data[i]);
    }
    printf("\n");
}

static const char *kind_name(mcl_wire_kind_t kind)
{
    switch (kind) {
    case MCL_WIRE_KIND_PRESENCE:         return "PRESENCE";
    case MCL_WIRE_KIND_HAZARD:           return "HAZARD";
    case MCL_WIRE_KIND_REQUEST:          return "REQUEST";
    case MCL_WIRE_KIND_AUTHORITY_CLAIM:  return "AUTHORITY_CLAIM";
    case MCL_WIRE_KIND_DEGRADED_STATE:   return "DEGRADED_STATE";
    case MCL_WIRE_KIND_TRANSPORT_OFFER:  return "TRANSPORT_OFFER";
    case MCL_WIRE_KIND_TRANSPORT_ACCEPT: return "TRANSPORT_ACCEPT";
    default:                             return "UNKNOWN";
    }
}

/* The three objects the independent side asks this one to produce. Values
 * match the Python side's expectations exactly, so a mismatch is a real
 * disagreement rather than a difference of test data. */
static int build_object(const char *name, mcl_wire_tier0_t *obj)
{
    memset(obj, 0, sizeof(*obj));
    obj->priority = 1u;
    obj->source_ref = 0x0BADCAFEu;

    if (strcmp(name, "PRESENCE") == 0) {
        obj->kind = MCL_WIRE_KIND_PRESENCE;
        obj->body.presence.machine_class = 3u;
        obj->body.presence.capability_tag = 0x00ABCDu;
        obj->body.presence.ttl = 60u;
        return 1;
    }
    if (strcmp(name, "TRANSPORT_OFFER") == 0) {
        obj->kind = MCL_WIRE_KIND_TRANSPORT_OFFER;
        obj->body.transport_offer.migration_ref = 0x4D194201u;
        obj->body.transport_offer.transport_id = 2u;
        /* Profile 1, IP-DATAGRAM: the Standards Action assignment. The fixture
           carried the experimental 192 until that value existed, and moving it
           is step 5 of the promotion sequence rather than housekeeping --
           profile_id travels on the wire, so this changes the bytes under
           test. The 192 cases did not disappear; they moved to explicit
           experimental-value tests in test_independent.py. */
        obj->body.transport_offer.profile_id = 1u;
        obj->body.transport_offer.endpoint_token = 0xD00D0001u;
        obj->body.transport_offer.validity = 30u;
        return 1;
    }
    if (strcmp(name, "TRANSPORT_ACCEPT") == 0) {
        obj->kind = MCL_WIRE_KIND_TRANSPORT_ACCEPT;
        obj->body.transport_accept.migration_ref = 0x4D194201u;
        obj->body.transport_accept.transport_id = 2u;
        obj->body.transport_accept.profile_id = 1u;
        obj->body.transport_accept.session_ref = 0x5E5510C7u;
        return 1;
    }
    return 0;
}

int main(int argc, char **argv)
{
    uint8_t buffer[2048];
    uint8_t scratch[2048];
    size_t size = 0u;
    size_t written = 0u;
    size_t consumed = 0u;

    if (argc < 2) {
        fprintf(stderr, "usage: cross_check <verb> [hex]\n");
        return 2;
    }

    if (strcmp(argv[1], "decode_tier0") == 0) {
        mcl_wire_tier0_t obj;
        size = from_hex(argc > 2 ? argv[2] : "", buffer, sizeof(buffer));
        if (size == 0u) {
            return 1;
        }
        if (mcl_wire_tier0_decode(buffer, size, &obj, &consumed) !=
                MCL_WIRE_OK) {
            return 1;
        }
        if (consumed != size) {
            /* Trailing bytes. Refused rather than ignored, so that this side
             * and the independent side agree about what "decodes" means. */
            return 1;
        }
        printf("%s\n", kind_name(obj.kind));
        return 0;
    }

    if (strcmp(argv[1], "encode_tier0") == 0) {
        mcl_wire_tier0_t obj;
        if (argc < 3 || build_object(argv[2], &obj) == 0) {
            return 2;
        }
        if (mcl_wire_tier0_encode(&obj, buffer, sizeof(buffer), &written) !=
                MCL_WIRE_OK) {
            return 1;
        }
        print_hex(buffer, written);
        return 0;
    }

    /*
     * Print every decoded field, so the independent side can compare VALUES.
     *
     * This verb exists because a length-only comparison is not a comparison. A
     * first draft of the independent implementation gave AUTHORITY_CLAIM an
     * 8-bit authority_class and a 16-bit jurisdiction instead of 6 and 12; the
     * total is identical, the object still consumed exactly 14 bytes, and a
     * check on lengths passed while every field after source_ref was misread.
     */
    if (strcmp(argv[1], "fields_tier0") == 0) {
        mcl_wire_tier0_t o;
        size = from_hex(argc > 2 ? argv[2] : "", buffer, sizeof(buffer));
        if (size == 0u) {
            return 1;
        }
        if (mcl_wire_tier0_decode(buffer, size, &o, &consumed) != MCL_WIRE_OK ||
            consumed != size) {
            return 1;
        }
        printf("kind=%s priority=%u source_ref=%u",
               kind_name(o.kind), (unsigned)o.priority,
               (unsigned)o.source_ref);
        switch (o.kind) {
        case MCL_WIRE_KIND_PRESENCE:
            printf(" machine_class=%u capability_tag=%u ttl=%u",
                   (unsigned)o.body.presence.machine_class,
                   (unsigned)o.body.presence.capability_tag,
                   (unsigned)o.body.presence.ttl);
            break;
        case MCL_WIRE_KIND_HAZARD:
            printf(" hazard_class=%u severity=%u confidence=%u"
                   " x=%d y=%d z=%d radius=%u ttl=%u",
                   (unsigned)o.body.hazard.hazard_class,
                   (unsigned)o.body.hazard.severity,
                   (unsigned)o.body.hazard.confidence,
                   (int)o.body.hazard.x, (int)o.body.hazard.y,
                   (int)o.body.hazard.z,
                   (unsigned)o.body.hazard.radius,
                   (unsigned)o.body.hazard.ttl);
            break;
        case MCL_WIRE_KIND_REQUEST:
            printf(" request_class=%u target_ref=%u x=%d y=%d radius=%u ttl=%u",
                   (unsigned)o.body.request.request_class,
                   (unsigned)o.body.request.target_ref,
                   (int)o.body.request.x, (int)o.body.request.y,
                   (unsigned)o.body.request.radius,
                   (unsigned)o.body.request.ttl);
            break;
        case MCL_WIRE_KIND_AUTHORITY_CLAIM:
            printf(" authority_class=%u jurisdiction=%u credential_ref=%u"
                   " validity=%u",
                   (unsigned)o.body.authority_claim.authority_class,
                   (unsigned)o.body.authority_claim.jurisdiction,
                   (unsigned)o.body.authority_claim.credential_ref,
                   (unsigned)o.body.authority_claim.validity);
            break;
        case MCL_WIRE_KIND_DEGRADED_STATE:
            printf(" affected_capability=%u health=%u severity=%u ttl=%u",
                   (unsigned)o.body.degraded_state.affected_capability,
                   (unsigned)o.body.degraded_state.health,
                   (unsigned)o.body.degraded_state.severity,
                   (unsigned)o.body.degraded_state.ttl);
            break;
        case MCL_WIRE_KIND_TRANSPORT_OFFER:
            printf(" migration_ref=%u transport_id=%u profile_id=%u"
                   " endpoint_token=%u validity=%u",
                   (unsigned)o.body.transport_offer.migration_ref,
                   (unsigned)o.body.transport_offer.transport_id,
                   (unsigned)o.body.transport_offer.profile_id,
                   (unsigned)o.body.transport_offer.endpoint_token,
                   (unsigned)o.body.transport_offer.validity);
            break;
        case MCL_WIRE_KIND_TRANSPORT_ACCEPT:
            printf(" migration_ref=%u transport_id=%u profile_id=%u"
                   " session_ref=%u",
                   (unsigned)o.body.transport_accept.migration_ref,
                   (unsigned)o.body.transport_accept.transport_id,
                   (unsigned)o.body.transport_accept.profile_id,
                   (unsigned)o.body.transport_accept.session_ref);
            break;
        default:
            return 1;
        }
        printf("\n");
        return 0;
    }

    if (strcmp(argv[1], "decode_frame") == 0) {
        mcl_link_frame_t frame;
        size = from_hex(argc > 2 ? argv[2] : "", buffer, sizeof(buffer));
        if (size == 0u) {
            return 1;
        }
        if (mcl_link_frame_decode(buffer, size, &frame, &consumed) !=
                MCL_LINK_OK) {
            return 1;
        }
        if (consumed != size) {
            return 1;
        }
        printf("ok\n");
        return 0;
    }

    if (strcmp(argv[1], "encode_frame") == 0) {
        mcl_wire_tier0_t obj;
        mcl_link_frame_t frame;
        (void)build_object("PRESENCE", &obj);
        if (mcl_wire_tier0_encode(&obj, scratch, sizeof(scratch), &written) !=
                MCL_WIRE_OK) {
            return 1;
        }
        memset(&frame, 0, sizeof(frame));
        frame.frame_class = MCL_LINK_CLASS_CONTACT;
        frame.flags = (uint8_t)(MCL_LINK_FLAG_SEQUENCE |
                                MCL_LINK_FLAG_FRAME_CHECK);
        frame.source_ref = 0x0BADCAFEu;
        frame.sequence = 7u;
        frame.payload = scratch;
        frame.payload_len = (uint16_t)written;
        if (mcl_link_frame_encode(&frame, buffer, sizeof(buffer), &size) !=
                MCL_LINK_OK) {
            return 1;
        }
        print_hex(buffer, size);
        return 0;
    }

    /*
     * The same frame at the STABLE Link major.
     *
     * Nothing in the layout moves between major 0 and major 1 -- the major
     * exists because the version policy reserves 0 for pre-standard work --
     * so this verb differs from encode_frame only in the high nibble of the
     * first byte. It exists because no cross-implementation case had ever
     * carried a major-1 frame, and the clean-room implementation turned out to
     * refuse one.
     */
    if (strcmp(argv[1], "encode_frame_major1") == 0) {
        mcl_wire_tier0_t obj;
        mcl_link_frame_t frame;
        (void)build_object("PRESENCE", &obj);
        if (mcl_wire_tier0_encode_at_major(MCL_WIRE_STABLE_MAJOR, &obj, scratch,
                                           sizeof(scratch), &written) !=
                MCL_WIRE_OK) {
            return 1;
        }
        memset(&frame, 0, sizeof(frame));
        frame.frame_class = MCL_LINK_CLASS_CONTACT;
        frame.flags = (uint8_t)(MCL_LINK_FLAG_SEQUENCE |
                                MCL_LINK_FLAG_FRAME_CHECK);
        frame.source_ref = 0x0BADCAFEu;
        frame.sequence = 7u;
        frame.payload = scratch;
        frame.payload_len = (uint16_t)written;
        if (mcl_link_frame_encode_at_major(MCL_LINK_STABLE_MAJOR, &frame,
                                           buffer, sizeof(buffer), &size) !=
                MCL_LINK_OK) {
            return 1;
        }
        print_hex(buffer, size);
        return 0;
    }

    if (strcmp(argv[1], "decode_capability") == 0) {
        mcl_link_capability_t cap;
        size = from_hex(argc > 2 ? argv[2] : "", buffer, sizeof(buffer));
        if (size == 0u) {
            return 1;
        }
        if (mcl_link_capability_decode(buffer, size, &cap) != MCL_LINK_OK) {
            return 1;
        }
        printf("%04x,%04x,%u,%04x\n",
               (unsigned)cap.wire_majors, (unsigned)cap.link_majors,
               (unsigned)cap.max_frame, (unsigned)cap.features);
        return 0;
    }

    if (strcmp(argv[1], "encode_capability") == 0) {
        mcl_link_capability_t cap;
        if (mcl_link_make_capability(&cap, 0x0003u, 0x0001u, 1048u, 0u) !=
                MCL_LINK_OK) {
            return 1;
        }
        if (mcl_link_capability_encode(&cap, buffer, sizeof(buffer),
                                       &written) != MCL_LINK_OK) {
            return 1;
        }
        print_hex(buffer, written);
        return 0;
    }

    if (strcmp(argv[1], "select") == 0) {
        mcl_link_capability_t local;
        mcl_link_capability_t peer;
        mcl_link_negotiation_t out;
        if (mcl_link_make_capability(&local, 0x000Bu, 0x0003u, 900u,
                                     0x0F0Fu) != MCL_LINK_OK) {
            return 1;
        }
        if (mcl_link_make_capability(&peer, 0x0007u, 0x0001u, 512u,
                                     0x00FFu) != MCL_LINK_OK) {
            return 1;
        }
        if (mcl_link_negotiation_select(&local, &peer, &out) != MCL_LINK_OK) {
            return 1;
        }
        printf("%u,%u,%u,%04x\n",
               (unsigned)out.wire_major, (unsigned)out.link_major,
               (unsigned)out.max_frame, (unsigned)out.features);
        return 0;
    }

    /* ---------- transport profiles, release gate item 17 ---------- */

    if (strcmp(argv[1], "ip_validate") == 0) {
        size = from_hex(argc > 2 ? argv[2] : "", buffer, sizeof(buffer));
        if (size == 0u) { return 1; }
        if (mcl_ip_datagram_validate(buffer, size) != MCL_IP_OK) { return 1; }
        printf("ok\n");
        return 0;
    }

    if (strcmp(argv[1], "ip_mtu") == 0) {
        char family[8];
        unsigned mtu = 0u;
        mcl_ip_address_family_t af;
        if (argc < 3 || sscanf(argv[2], "%7[^:]:%u", family, &mtu) != 2) {
            return 2;
        }
        af = (strcmp(family, "ipv4") == 0) ? MCL_IP_AF_IPV4 : MCL_IP_AF_IPV6;
        printf("%u\n", (unsigned)mcl_ip_max_frame_for_mtu(af, (size_t)mtu));
        return 0;
    }

    if (strcmp(argv[1], "ble_per_pdu") == 0) {
        unsigned mtu = 0u;
        if (argc < 3 || sscanf(argv[2], "%u", &mtu) != 1) { return 2; }
        printf("%u\n", (unsigned)mcl_ble_payload_per_pdu((uint16_t)mtu));
        return 0;
    }

    if (strcmp(argv[1], "ble_validate") == 0) {
        size = from_hex(argc > 2 ? argv[2] : "", buffer, sizeof(buffer));
        if (size == 0u) { return 1; }
        if (mcl_ble_frame_validate(buffer, size) != MCL_BLE_OK) { return 1; }
        printf("ok\n");
        return 0;
    }

    if (strcmp(argv[1], "ble_fragment") == 0) {
        size_t count;
        size_t i;
        size = from_hex(argc > 2 ? argv[2] : "", buffer, sizeof(buffer));
        if (size == 0u) { return 1; }
        count = mcl_ble_fragment_count(size, MCL_BLE_ATT_DEFAULT_MTU);
        if (count == 0u) { return 1; }
        for (i = 0u; i < count; ++i) {
            size_t n = 0u;
            size_t j;
            if (mcl_ble_fragment(buffer, size, MCL_BLE_ATT_DEFAULT_MTU, i,
                                 scratch, sizeof(scratch), &n) != MCL_BLE_OK) {
                return 1;
            }
            if (i != 0u) { printf(","); }
            for (j = 0u; j < n; ++j) { printf("%02x", scratch[j]); }
        }
        printf("\n");
        return 0;
    }

    if (strcmp(argv[1], "ble_reassemble") == 0) {
        /* Comma-separated fragments fed in order. Any refusal is the answer. */
        mcl_ble_reassembler_t r;
        char *list = (argc > 2) ? argv[2] : (char *)"";
        char *token;
        size_t frame_size = 0u;
        int completed = 0;

        mcl_ble_reassembler_reset(&r);
        token = strtok(list, ",");
        while (token != NULL) {
            size_t n = from_hex(token, scratch, sizeof(scratch));
            mcl_ble_status_t st;
            if (n == 0u && strlen(token) != 0u) { return 1; }
            st = mcl_ble_reassemble(&r, scratch, n, &frame_size);
            if (st == MCL_BLE_OK) {
                completed = 1;
            } else if (st != MCL_BLE_ERR_INCOMPLETE) {
                return 1;
            }
            token = strtok(NULL, ",");
        }
        if (completed == 0) { return 1; }
        print_hex(r.buffer, frame_size);
        return 0;
    }

    fprintf(stderr, "unknown verb %s\n", argv[1]);
    return 2;
}
