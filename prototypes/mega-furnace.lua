local MEGA_FURNACE_NAME = "mega-furnace"
local MEGA_FURNACE_2_NAME = "mega-furnace-2"
local ASSEMBLING_MACHINE_3_ONLY_CATEGORY = "mega-furnace-assembly"
local GRAPHICS_SCALE = 5

local function scale_shift(shift, factor)
  if type(shift) ~= "table" then
    return shift
  end

  if shift.x or shift.y then
    return {x = (shift.x or 0) * factor, y = (shift.y or 0) * factor}
  end

  return {(shift[1] or 0) * factor, (shift[2] or 0) * factor}
end

local function scale_sprite_tree(node, factor)
  if type(node) ~= "table" then
    return
  end

  if node.filename or node.filenames or node.stripes then
    node.scale = (node.scale or 1) * factor

    if node.shift then
      node.shift = scale_shift(node.shift, factor)
    end
  end

  for _, child in pairs(node) do
    if type(child) == "table" then
      scale_sprite_tree(child, factor)
    end
  end
end

local assembling_machine_3 = data.raw["assembling-machine"] and data.raw["assembling-machine"]["assembling-machine-3"]
if assembling_machine_3 then
  local has_custom_category = false

  for _, category_name in ipairs(assembling_machine_3.crafting_categories or {}) do
    if category_name == ASSEMBLING_MACHINE_3_ONLY_CATEGORY then
      has_custom_category = true
      break
    end
  end

  if not has_custom_category then
    table.insert(assembling_machine_3.crafting_categories, ASSEMBLING_MACHINE_3_ONLY_CATEGORY)
  end
end

local ordered_science_packs = {
  "automation-science-pack",
  "logistic-science-pack",
  "military-science-pack",
  "chemical-science-pack",
  "production-science-pack",
  "utility-science-pack",
  "space-science-pack"
}

local low_tier_science_packs = {
  "automation-science-pack",
  "logistic-science-pack",
  "chemical-science-pack",
  "production-science-pack",
  "utility-science-pack"
}

local low_tier_tech_ingredients = {}
local high_tier_tech_ingredients = {}
local prerequisites = {
  "logistics-3",
  "nuclear-power",
  "utility-science-pack"
}

for _, pack_name in ipairs(low_tier_science_packs) do
  if data.raw.tool[pack_name] then
    low_tier_tech_ingredients[#low_tier_tech_ingredients + 1] = {pack_name, 1}
  end
end

for _, pack_name in ipairs(ordered_science_packs) do
  if data.raw.tool[pack_name] then
    high_tier_tech_ingredients[#high_tier_tech_ingredients + 1] = {pack_name, 1}
  end
end

local mega_furnace = table.deepcopy(data.raw.furnace["electric-furnace"])
mega_furnace.name = MEGA_FURNACE_NAME
mega_furnace.icon = "__mega_furnace__/graphics/icons/mega-furnace.png"
mega_furnace.minable = {mining_time = 3, result = MEGA_FURNACE_NAME}
mega_furnace.fast_replaceable_group = nil
mega_furnace.next_upgrade = nil
mega_furnace.max_health = 4500
mega_furnace.collision_box = {{-7.2, -7.2}, {7.2, 7.2}}
mega_furnace.selection_box = {{-7.5, -7.5}, {7.5, 7.5}}
mega_furnace.module_slots = 2
mega_furnace.icon_draw_specification = {shift = {0, -0.35}}
mega_furnace.icons_positioning = {
  {inventory_index = defines.inventory.furnace_modules, shift = {0, 4.0}}
}
mega_furnace.crafting_speed = 100
mega_furnace.energy_usage = "18MW"
mega_furnace.energy_source.emissions_per_minute = {pollution = 60}
scale_sprite_tree(mega_furnace.graphics_set, GRAPHICS_SCALE)
mega_furnace.graphics_set.animation.layers[1].filename = "__mega_furnace__/graphics/entity/mega-furnace/mega-furnace.png"
mega_furnace.graphics_set.working_visualisations[1].animation.layers[1].tint = {r = 0.45, g = 0.8, b = 1.0, a = 1.0}
mega_furnace.graphics_set.working_visualisations[1].animation.layers[2].tint = {r = 0.35, g = 0.72, b = 1.0, a = 0.9}
mega_furnace.graphics_set.working_visualisations[2].animation.tint = {r = 0.3, g = 0.62, b = 1.0, a = 0.75}

local mega_furnace_item = table.deepcopy(data.raw.item["electric-furnace"])
mega_furnace_item.name = MEGA_FURNACE_NAME
mega_furnace_item.icon = "__mega_furnace__/graphics/icons/mega-furnace.png"
mega_furnace_item.place_result = MEGA_FURNACE_NAME
mega_furnace_item.order = "c[electric-furnace]-z[mega-furnace]"
mega_furnace_item.stack_size = 10

local mega_furnace_recipe = {
  type = "recipe",
  name = MEGA_FURNACE_NAME,
  category = ASSEMBLING_MACHINE_3_ONLY_CATEGORY,
  enabled = false,
  energy_required = 20,
  ingredients = {
    {type = "item", name = "heat-pipe", amount = 50},
    {type = "item", name = "express-transport-belt", amount = 32},
    {type = "item", name = "processing-unit", amount = 500},
    {type = "item", name = "electric-furnace", amount = 32},
    {type = "item", name = "steel-plate", amount = 1000},
    {type = "item", name = "refined-concrete", amount = 100}
  },
  results = {
    {type = "item", name = MEGA_FURNACE_NAME, amount = 1}
  }
}

local mega_furnace_technology = {
  type = "technology",
  name = MEGA_FURNACE_NAME,
  icon = "__base__/graphics/technology/advanced-material-processing-2.png",
  icon_size = 256,
  effects = {
    {type = "unlock-recipe", recipe = MEGA_FURNACE_NAME}
  },
  prerequisites = prerequisites,
  unit = {
    count = 1000,
    ingredients = low_tier_tech_ingredients,
    time = 60
  }
}

local mega_furnace_2 = table.deepcopy(mega_furnace)
mega_furnace_2.name = MEGA_FURNACE_2_NAME
mega_furnace_2.icon = "__mega_furnace__/graphics/icons/mega-furnace-2.png"
mega_furnace_2.minable = {mining_time = 3, result = MEGA_FURNACE_2_NAME}
mega_furnace_2.max_health = 7500
mega_furnace_2.crafting_speed = 160
mega_furnace_2.energy_usage = "60MW"
mega_furnace_2.module_slots = 4
mega_furnace_2.energy_source.drain = "2MW"
mega_furnace_2.energy_source.emissions_per_minute = {pollution = 120}
mega_furnace_2.graphics_set.animation.layers[1].filename = "__mega_furnace__/graphics/entity/mega-furnace-2/mega-furnace-2.png"
mega_furnace_2.graphics_set.working_visualisations[1].animation.layers[1].tint = {r = 0.62, g = 0.90, b = 1.0, a = 1.0}
mega_furnace_2.graphics_set.working_visualisations[1].animation.layers[2].tint = {r = 0.52, g = 0.84, b = 1.0, a = 0.95}
mega_furnace_2.graphics_set.working_visualisations[2].animation.tint = {r = 0.45, g = 0.76, b = 1.0, a = 0.85}

local mega_furnace_2_item = table.deepcopy(mega_furnace_item)
mega_furnace_2_item.name = MEGA_FURNACE_2_NAME
mega_furnace_2_item.icon = "__mega_furnace__/graphics/icons/mega-furnace-2.png"
mega_furnace_2_item.place_result = MEGA_FURNACE_2_NAME
mega_furnace_2_item.order = "c[electric-furnace]-zz[mega-furnace-2]"
mega_furnace_2_item.stack_size = 5

local mega_furnace_2_recipe = {
  type = "recipe",
  name = MEGA_FURNACE_2_NAME,
  category = ASSEMBLING_MACHINE_3_ONLY_CATEGORY,
  enabled = false,
  energy_required = 50,
  ingredients = {
    {type = "item", name = MEGA_FURNACE_NAME, amount = 2},
    {type = "item", name = "low-density-structure", amount = 400},
    {type = "item", name = "processing-unit", amount = 750},
    {type = "item", name = "heat-pipe", amount = 200},
    {type = "item", name = "express-transport-belt", amount = 128},
    {type = "item", name = "steel-plate", amount = 2000},
    {type = "item", name = "refined-concrete", amount = 500}
  },
  results = {
    {type = "item", name = MEGA_FURNACE_2_NAME, amount = 1}
  }
}

local mega_furnace_2_technology = {
  type = "technology",
  name = MEGA_FURNACE_2_NAME,
  icon = "__base__/graphics/technology/advanced-material-processing-2.png",
  icon_size = 256,
  effects = {
    {type = "unlock-recipe", recipe = MEGA_FURNACE_2_NAME}
  },
  prerequisites = {
    MEGA_FURNACE_NAME,
    "rocket-silo"
  },
  unit = {
    count = 5000,
    ingredients = high_tier_tech_ingredients,
    time = 60
  }
}

data:extend({
  {
    type = "recipe-category",
    name = ASSEMBLING_MACHINE_3_ONLY_CATEGORY
  },
  mega_furnace,
  mega_furnace_item,
  mega_furnace_recipe,
  mega_furnace_technology,
  mega_furnace_2,
  mega_furnace_2_item,
  mega_furnace_2_recipe,
  mega_furnace_2_technology
})
