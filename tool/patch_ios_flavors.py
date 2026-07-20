#!/usr/bin/env python3
"""Add Flutter iOS flavors (dev/prod) to Runner.xcodeproj/project.pbxproj."""

from __future__ import annotations

import re
import uuid
from pathlib import Path

PBX = Path(__file__).resolve().parents[1] / "ios/Runner.xcodeproj/project.pbxproj"
text = PBX.read_text()

def uid() -> str:
    return uuid.uuid4().hex[:24].upper()

flavor_files = {
    "Debug-dev.xcconfig": uid(),
    "Release-dev.xcconfig": uid(),
    "Profile-dev.xcconfig": uid(),
    "Debug-prod.xcconfig": uid(),
    "Release-prod.xcconfig": uid(),
    "Profile-prod.xcconfig": uid(),
}

release_ref_line = (
    '		7AFA3C8E1D35360C0083082E /* Release.xcconfig */ = '
    '{isa = PBXFileReference; lastKnownFileType = text.xcconfig; '
    'name = Release.xcconfig; path = Flutter/Release.xcconfig; sourceTree = "<group>"; };'
)
extra_refs = []
for name, fid in flavor_files.items():
    extra_refs.append(
        f'		{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; '
        f'name = {name}; path = Flutter/{name}; sourceTree = "<group>"; }};'
    )
if release_ref_line not in text:
    raise SystemExit("Could not find Release.xcconfig PBXFileReference")
if "Debug-dev.xcconfig" in text:
    raise SystemExit("Flavors already patched — aborting to avoid duplicates")
text = text.replace(release_ref_line, release_ref_line + "\n" + "\n".join(extra_refs))

group_snip = "				7AFA3C8E1D35360C0083082E /* Release.xcconfig */,"
group_extra = "\n".join(
    f"				{fid} /* {name} */," for name, fid in flavor_files.items()
)
if group_snip not in text:
    raise SystemExit("Could not find Flutter group Release.xcconfig entry")
text = text.replace(group_snip, group_snip + "\n" + group_extra)

PROJECT_DEBUG = "97C147031CF9000F007C117D"
PROJECT_RELEASE = "97C147041CF9000F007C117D"
PROJECT_PROFILE = "249021D3217E4FDB00AE95B9"
TARGET_DEBUG = "97C147061CF9000F007C117D"
TARGET_RELEASE = "97C147071CF9000F007C117D"
TARGET_PROFILE = "249021D4217E4FDB00AE95B9"
TEST_DEBUG = "331C8088294A63A400263BE5"
TEST_RELEASE = "331C8089294A63A400263BE5"
TEST_PROFILE = "331C808A294A63A400263BE5"

base_map = {
    "Debug": (PROJECT_DEBUG, TARGET_DEBUG, TEST_DEBUG),
    "Release": (PROJECT_RELEASE, TARGET_RELEASE, TEST_RELEASE),
    "Profile": (PROJECT_PROFILE, TARGET_PROFILE, TEST_PROFILE),
}

flavors = {
    "dev": {
        "bundle": "com.mpsedc.evmManagementSystem.dev",
        "name": '"EVM DEV"',
        "xc": {
            "Debug": (flavor_files["Debug-dev.xcconfig"], "Debug-dev.xcconfig"),
            "Release": (flavor_files["Release-dev.xcconfig"], "Release-dev.xcconfig"),
            "Profile": (flavor_files["Profile-dev.xcconfig"], "Profile-dev.xcconfig"),
        },
    },
    "prod": {
        "bundle": "com.mpsedc.evmManagementSystem",
        "name": "EVM",
        "xc": {
            "Debug": (flavor_files["Debug-prod.xcconfig"], "Debug-prod.xcconfig"),
            "Release": (flavor_files["Release-prod.xcconfig"], "Release-prod.xcconfig"),
            "Profile": (flavor_files["Profile-prod.xcconfig"], "Profile-prod.xcconfig"),
        },
    },
}

def extract_block(src: str, config_id: str) -> str:
    pattern = rf"(\t\t{config_id} /\* [^*]+ \*/ = \{{.*?\n\t\t\}};\n)"
    m = re.search(pattern, src, flags=re.S)
    if not m:
        raise SystemExit(f"Missing config block {config_id}")
    return m.group(1)

# Capture originals before further edits
originals = {
    cid: extract_block(text, cid)
    for cid in [
        PROJECT_DEBUG, PROJECT_RELEASE, PROJECT_PROFILE,
        TARGET_DEBUG, TARGET_RELEASE, TARGET_PROFILE,
        TEST_DEBUG, TEST_RELEASE, TEST_PROFILE,
    ]
}

new_blocks: list[str] = []
project_list_entries: list[str] = []
target_list_entries: list[str] = []
test_list_entries: list[str] = []

for flavor, meta in flavors.items():
    for base_name, (proj_id, tgt_id, test_id) in base_map.items():
        cfg_name = f"{base_name}-{flavor}"
        new_proj, new_tgt, new_test = uid(), uid(), uid()

        proj_new = originals[proj_id].replace(
            f"\t\t{proj_id} /* {base_name} */", f"\t\t{new_proj} /* {cfg_name} */", 1
        )
        proj_new = re.sub(r"\n\t\t\tname = [^;]+;", f"\n\t\t\tname = {cfg_name};", proj_new, count=1)

        tgt_new = originals[tgt_id].replace(
            f"\t\t{tgt_id} /* {base_name} */", f"\t\t{new_tgt} /* {cfg_name} */", 1
        )
        tgt_new = re.sub(r"\n\t\t\tname = [^;]+;", f"\n\t\t\tname = {cfg_name};", tgt_new, count=1)
        tgt_new = re.sub(
            r"PRODUCT_BUNDLE_IDENTIFIER = [^;]+;",
            f"PRODUCT_BUNDLE_IDENTIFIER = {meta['bundle']};",
            tgt_new,
            count=1,
        )
        if "APP_DISPLAY_NAME" not in tgt_new:
            tgt_new = tgt_new.replace(
                "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
                "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n"
                f"\t\t\t\tAPP_DISPLAY_NAME = {meta['name']};",
                1,
            )
        xc_id, xc_name = meta["xc"][base_name]
        tgt_new = re.sub(
            r"baseConfigurationReference = [A-F0-9]+ /\* [^ ]+ \*/;",
            f"baseConfigurationReference = {xc_id} /* {xc_name} */;",
            tgt_new,
            count=1,
        )

        test_new = originals[test_id].replace(
            f"\t\t{test_id} /* {base_name} */", f"\t\t{new_test} /* {cfg_name} */", 1
        )
        test_new = re.sub(r"\n\t\t\tname = [^;]+;", f"\n\t\t\tname = {cfg_name};", test_new, count=1)

        new_blocks.extend([proj_new, tgt_new, test_new])
        project_list_entries.append(f"\t\t\t\t{new_proj} /* {cfg_name} */,")
        target_list_entries.append(f"\t\t\t\t{new_tgt} /* {cfg_name} */,")
        test_list_entries.append(f"\t\t\t\t{new_test} /* {cfg_name} */,")

marker = "/* End XCBuildConfiguration section */"
text = text.replace(marker, "".join(new_blocks) + marker)

def append_to_config_list(list_id: str, entries: list[str]) -> None:
    global text
    pattern = (
        rf"({list_id} /\* [^*]+ \*/ = \{{\n"
        rf"\t\t\tisa = XCConfigurationList;\n"
        rf"\t\t\tbuildConfigurations = \(\n)"
        rf"(.*?)"
        rf"(\n\t\t\t\);)"
    )
    m = re.search(pattern, text, flags=re.S)
    if not m:
        raise SystemExit(f"Config list {list_id} not found")
    existing = m.group(2).rstrip()
    text = text[: m.start(2)] + existing + "\n" + "\n".join(entries) + text[m.end(2) :]

append_to_config_list("97C146E91CF9000F007C117D", project_list_entries)
append_to_config_list("97C147051CF9000F007C117D", target_list_entries)
append_to_config_list("331C8087294A63A400263BE5", test_list_entries)

for tid in (TARGET_DEBUG, TARGET_RELEASE, TARGET_PROFILE):
    block = extract_block(text, tid)
    if "APP_DISPLAY_NAME" not in block:
        updated = block.replace(
            "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
            "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n"
            "\t\t\t\tAPP_DISPLAY_NAME = EVM;",
            1,
        )
        text = text.replace(block, updated)

PBX.write_text(text)
print("Patched", PBX)
