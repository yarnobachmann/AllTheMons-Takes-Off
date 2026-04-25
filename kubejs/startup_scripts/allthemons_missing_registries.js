const blockIds = [
  'air_essence_block',
  'earth_essence_block',
  'fire_essence_block',
  'water_essence_block',
  'magical_soil',
  'blaze_powder_block'
]

const itemIds = [
  'ancient_stone_cell',
  'andesite_cell',
  'arcane_sulfur',
  'atm_star_shard_1',
  'atm_star_shard_2',
  'atm_star_shard_3',
  'atm_star_shard_4',
  'atm_star_shard_5',
  'azure_silver_clump',
  'azure_silver_crystal',
  'azure_silver_dirty_dust',
  'azure_silver_shard',
  'basalt_cell',
  'black_cell',
  'blackstone_cell',
  'blue_cell',
  'bort_sulfur',
  'brown_cell',
  'calcite_cell',
  'clay_cell',
  'cobbled_deepslate_cell',
  'crimson_iron_clump',
  'crimson_iron_crystal',
  'crimson_iron_dirty_dust',
  'crimson_iron_shard',
  'cyan_cell',
  'diorite_cell',
  'dirt_cell',
  'end_stone_cell',
  'fire_eye',
  'fire_pearl',
  'granite_cell',
  'gray_cell',
  'gravel_cell',
  'green_cell',
  'ice_eye',
  'ice_pearl',
  'iesnium_sulfur',
  'imperium_enchanting_base',
  'inferium_enchanting_base',
  'lava_cell',
  'light_blue_cell',
  'light_gray_cell',
  'lightning_eye',
  'lightning_pearl',
  'lime_cell',
  'magenta_cell',
  'modularium_plate',
  'moss_cell',
  'netherrack_cell',
  'orange_cell',
  'pink_cell',
  'prosperity_sulfur',
  'prudentium_enchanting_base',
  'purple_cell',
  'red_cell',
  'red_sand_cell',
  'runic_sulfur',
  'salt_sulfur',
  'sand_cell',
  'silent_allthemodium_plate',
  'silent_unobtainium_plate',
  'silent_vibranium_plate',
  'sky_stone_cell',
  'soul_sand_cell',
  'starlight_prediction',
  'stellarite_sulfur',
  'sulfur_sulfur',
  'supremium_enchanting_base',
  'tertium_enchanting_base',
  'tuff_cell',
  'universal_press',
  'white_cell',
  'yellow_cell'
]

const fluidIds = [
  'liquid_aureal',
  'liquid_souls',
  'unrefined_liquid_souls'
]

StartupEvents.registry('block', event => {
  blockIds.forEach(id => event.create(id))
})

StartupEvents.registry('item', event => {
  itemIds.forEach(id => event.create(id))
})

StartupEvents.registry('fluid', event => {
  fluidIds.forEach(id => event.create(id).thinTexture(0x6f47a8).bucketColor(0x6f47a8))
})

StartupEvents.registry('mekanism:chemical', event => {
  event.create('clean_azure_silver')
  event.create('clean_crimson_iron')
  event.create('dirty_azure_silver')
  event.create('dirty_crimson_iron')
})
