cmake_minimum_required(VERSION 3.16)
project(mcl_core LANGUAGES C)

enable_testing()

add_executable(mcl_core_validate_registry tools/validate_registry.c)
set_target_properties(mcl_core_validate_registry PROPERTIES
    C_STANDARD 99
    C_STANDARD_REQUIRED YES
    C_EXTENSIONS NO)

add_test(NAME mcl_core_validate_registry COMMAND mcl_core_validate_registry
    "${CMAKE_CURRENT_SOURCE_DIR}/registries/semantic-codes-v0.2.json"
    "${CMAKE_CURRENT_SOURCE_DIR}/conformance/header-v0.2-vectors.json")

# The Tier-0 field registry records which field MEANINGS are settled. Its
# summary block is checked against its own entries, because a count written by
# hand drifts, and a wrong count here would overstate how much of Tier-0 is
# interoperable -- the specific failure the registry exists to prevent.
add_executable(mcl_core_validate_field_registry tools/validate_field_registry.c)
set_target_properties(mcl_core_validate_field_registry PROPERTIES
    C_STANDARD 99
    C_STANDARD_REQUIRED YES
    C_EXTENSIONS NO)

add_test(NAME mcl_core_validate_field_registry
    COMMAND mcl_core_validate_field_registry
    "${CMAKE_CURRENT_SOURCE_DIR}/registries/tier0-fields-v0.1.json")
