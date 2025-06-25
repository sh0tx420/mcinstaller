#!/bin/bash

# imports
source ./lib.sh

function Patch_VSP_VanillaPaper {
    sed -i 's/delay-chunk-unloads-by: .*/delay-chunk-unloads-by: 0s/' "$1/config/paper-world-defaults.yml"
    # max-auto-save-chunks-per-tick is set to 200 here (paper has 24) but we let it be
    sed -i 's/allow-player-cramming-damage: false/allow-player-cramming-damage: true/' "$1/config/paper-world-defaults.yml"
    sed -i 's/max-entity-collisions: .*/max-entity-collisions: 2147483647/' "$1/config/paper-world-defaults.yml"
    sed -i 's/phantoms-only-attack-insomniacs: true/phantoms-only-attack-insomniacs: false/' "$1/config/paper-world-defaults.yml"
    sed -i 's/count-all-mobs-for-spawning: false/count-all-mobs-for-spawning: true/' "$1/config/paper-world-defaults.yml"
    sed -i 's/per-player-mob-spawns: true/per-player-mob-spawns: false/' "$1/config/paper-world-defaults.yml"
    sed -i 's/item-frame-cursor-limit: .*/item-frame-cursor-limit: 2147483647/' "$1/config/paper-world-defaults.yml"
    
    sed -i 's/display-name: .*/display-name: 2147483647/' "$1/config/paper-global.yml"
    sed -i 's/lore-line: .*/lore-line: 2147483647/' "$1/config/paper-global.yml"
    sed -i 's/author: .*/author: 2147483647/' "$1/config/paper-global.yml"
    sed -i 's/page: .*/page: 2147483647/' "$1/config/paper-global.yml"
    sed -i 's/title: .*/title: 2147483647/' "$1/config/paper-global.yml"
    sed -i 's/page-max: .*/page-max: disabled/' "$1/config/paper-global.yml"
    
    sed -i 's/allow-headless-pistons: false/allow-headless-pistons: true/' "$1/config/paper-global.yml"
    sed -i 's/allow-permanent-block-break-exploits: false/allow-permanent-block-break-exploits: true/' "$1/config/paper-global.yml"
    sed -i 's/allow-piston-duplication: false/allow-piston-duplication: true/' "$1/config/paper-global.yml"
    sed -i 's/skip-tripwire-hook-placement-validation: false/skip-tripwire-hook-placement-validation: true/' "$1/config/paper-global.yml"
    sed -i 's/allow-piston-duplication: false/allow-piston-duplication: true/' "$1/config/paper-global.yml"
    
    sed -i '/entity-activation-range:/,/^[^[:space:]]/ {
        s/animals: .*/animals: 0/
        s/flying-monsters: .*/flying-monsters: 0/
        s/misc: .*/misc: 0/
        s/monsters: .*/monsters: 0/
        s/raiders: .*/raiders: 0/
        s/villagers: .*/villagers: 0/
        s/water: .*/water: 0/
    }' "$1/spigot.yml"
    
    cprintf "Applied patch: PaperMC Vanilla-like experience"
}

function Patch_VSP_AntiXray {
    szXray_paper_world_defaults=$(cat << 'EOF'
  anti-xray:
    enabled: true
    engine-mode: 2
    hidden-blocks:
    # You can add air here such that many holes are generated.
    # This works well against cave finders but may cause client FPS drops for all players.
    - air
    - copper_ore
    - deepslate_copper_ore
    - raw_copper_block
    - diamond_ore
    - deepslate_diamond_ore
    - gold_ore
    - deepslate_gold_ore
    - iron_ore
    - deepslate_iron_ore
    - raw_iron_block
    - lapis_ore
    - deepslate_lapis_ore
    - redstone_ore
    - deepslate_redstone_ore
    lava-obscures: false
    # As of 1.18 some ores are generated much higher.
    # Please adjust the max-block-height setting at your own discretion.
    # https://minecraft.wiki/w/Ore might be helpful.
    max-block-height: 64
    replacement-blocks:
    # Chest is a tile entity and can't be added to hidden-blocks in engine-mode: 2.
    # But adding chest here will hide buried treasures, if max-block-height is increased.
    - chest
    - amethyst_block
    - andesite
    - budding_amethyst
    - calcite
    - coal_ore
    - deepslate_coal_ore
    - deepslate
    - diorite
    - dirt
    - emerald_ore
    - deepslate_emerald_ore
    - granite
    - gravel
    - oak_planks
    - smooth_basalt
    - stone
    - tuff
    update-radius: 2
    use-permission: false
EOF
)

    szXray_world_nether=$(cat << 'EOF'
anticheat:
  anti-xray:
    enabled: true
    engine-mode: 2
    hidden-blocks:
    # See note about air and possible client performance issues above.
    - air
    - ancient_debris
    - bone_block
    - glowstone
    - magma_block
    - nether_bricks
    - nether_gold_ore
    - nether_quartz_ore
    - polished_blackstone_bricks
    lava-obscures: false
    max-block-height: 128
    replacement-blocks:
    - basalt
    - blackstone
    - gravel
    - netherrack
    - soul_sand
    - soul_soil
    update-radius: 2
    use-permission: false
EOF
)

    szXray_world_the_end=$(cat << 'EOF'
anticheat:
  anti-xray:
    enabled: false
EOF
)

    #sed -i '/^  anti-xray:/,/^  [^[:space:]]\|^$/d' "$1/config/paper-world-defaults.yml"
    #sed -i "/^anticheat:/a$szXray_paper_world_defaults" "$1/config/paper-world-defaults.yml"   # broken
    # Remove existing anti-xray section from paper-world-defaults.yml
    sed -i '/^  anti-xray:/,/^  [^[:space:]]/d' "$1/config/paper-world-defaults.yml"
    # Append new anti-xray configuration after anticheat:
    sed -i "/^anticheat:/r /dev/stdin" "$1/config/paper-world-defaults.yml" <<< "$szXray_paper_world_defaults"
    
    echo "$szXray_world_nether" >> "$1/world_nether/paper-world.yml"
    echo "$szXray_world_the_end" >> "$1/world_the_end/paper-world.yml"
    
    cprintf "Applied patch: PaperMC Anti-Xray (engine-mode: 2)"
}

function Patch_VSP_All {
    # $1 here should be as a directory, same as where start.sh is
    Patch_VSP_VanillaPaper "$1"
    Patch_VSP_AntiXray "$1"
}

