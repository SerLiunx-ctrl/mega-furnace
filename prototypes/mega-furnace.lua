local MEGA_FURNACE_NAME = "mega-furnace"
local MEGA_FURNACE_2_NAME = "mega-furnace-2"
local MEGA_INSERTER_NAME = "mega-inserter"
local MEGA_TRANSPORT_BELT_NAME = "mega-transport-belt"
local MEGA_UNDERGROUND_BELT_NAME = "mega-underground-belt"
local MEGA_SPLITTER_NAME = "mega-splitter"
local MEGA_LOGISTICS_TECH_NAME = "mega-logistics"
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

local function replace_filename_tree(node, source_filename, replacement_filename)
  if type(node) ~= "table" then
    return
  end

  if node.filename == source_filename then
    node.filename = replacement_filename
  end

  for _, child in pairs(node) do
    if type(child) == "table" then
      replace_filename_tree(child, source_filename, replacement_filename)
    end
  end
end

local function clear_tint_tree(node)
  if type(node) ~= "table" then
    return
  end

  if node.filename or node.filenames or node.stripes then
    node.tint = nil
  end

  for _, child in pairs(node) do
    if type(child) == "table" then
      clear_tint_tree(child)
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

local express_transport_belt = data.raw["transport-belt"] and data.raw["transport-belt"]["express-transport-belt"]
if express_transport_belt then
  express_transport_belt.next_upgrade = MEGA_TRANSPORT_BELT_NAME
end

local express_underground_belt = data.raw["underground-belt"] and data.raw["underground-belt"]["express-underground-belt"]
if express_underground_belt then
  express_underground_belt.next_upgrade = MEGA_UNDERGROUND_BELT_NAME
end

local express_splitter = data.raw.splitter and data.raw.splitter["express-splitter"]
if express_splitter then
  express_splitter.next_upgrade = MEGA_SPLITTER_NAME
end

local bulk_inserter = data.raw.inserter and data.raw.inserter["bulk-inserter"]
if bulk_inserter then
  bulk_inserter.next_upgrade = MEGA_INSERTER_NAME
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
local inserter_tech_ingredients = {}
local logistics_tech_ingredients = {}
local prerequisites = {
  "logistics-3",
  "nuclear-power",
  "utility-science-pack"
}

for _, pack_name in ipairs(low_tier_science_packs) do
  if data.raw.tool[pack_name] then
    low_tier_tech_ingredients[#low_tier_tech_ingredients + 1] = {pack_name, 1}
    inserter_tech_ingredients[#inserter_tech_ingredients + 1] = {pack_name, 1}
    logistics_tech_ingredients[#logistics_tech_ingredients + 1] = {pack_name, 1}
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
mega_furnace.energy_usage = "4.5MW"
mega_furnace.energy_source.emissions_per_minute = {pollution = 30}
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
    {type = "item", name = "heat-pipe", amount = 25},
    {type = "item", name = "express-transport-belt", amount = 16},
    {type = "item", name = "processing-unit", amount = 250},
    {type = "item", name = "electric-furnace", amount = 16},
    {type = "item", name = "steel-plate", amount = 500},
    {type = "item", name = "refined-concrete", amount = 50}
  },
  results = {
    {type = "item", name = MEGA_FURNACE_NAME, amount = 1}
  }
}

local mega_furnace_technology = {
  type = "technology",
  name = MEGA_FURNACE_NAME,
  icon = "__mega_furnace__/graphics/icons/mega-furnace.png",
  icon_size = 64,
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
mega_furnace_2.energy_usage = "15MW"
mega_furnace_2.module_slots = 4
mega_furnace_2.energy_source.drain = "500kW"
mega_furnace_2.energy_source.emissions_per_minute = {pollution = 60}
mega_furnace_2.graphics_set.animation.layers[1].filename = "__mega_furnace__/graphics/entity/mega-furnace-2/mega-furnace-2.png"
mega_furnace_2.graphics_set.working_visualisations[1].animation.layers[1].filename = "__mega_furnace__/graphics/entity/mega-furnace-2/mega-furnace-2-heater-blue.png"
mega_furnace_2.graphics_set.working_visualisations[1].animation.layers[1].tint = nil
mega_furnace_2.graphics_set.working_visualisations[1].animation.layers[2].filename = "__base__/graphics/entity/electric-furnace/electric-furnace-light.png"
mega_furnace_2.graphics_set.working_visualisations[1].animation.layers[2].tint = {r = 0.55, g = 0.78, b = 1.0, a = 0.35}
mega_furnace_2.graphics_set.working_visualisations[2].animation.filename = "__base__/graphics/entity/electric-furnace/electric-furnace-ground-light.png"
mega_furnace_2.graphics_set.working_visualisations[2].animation.tint = {r = 0.40, g = 0.62, b = 1.0, a = 0.25}

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
    {type = "item", name = MEGA_FURNACE_NAME, amount = 1},
    {type = "item", name = "low-density-structure", amount = 200},
    {type = "item", name = "processing-unit", amount = 375},
    {type = "item", name = "heat-pipe", amount = 100},
    {type = "item", name = "express-transport-belt", amount = 64},
    {type = "item", name = "steel-plate", amount = 1000},
    {type = "item", name = "refined-concrete", amount = 250}
  },
  results = {
    {type = "item", name = MEGA_FURNACE_2_NAME, amount = 1}
  }
}

local mega_furnace_2_technology = {
  type = "technology",
  name = MEGA_FURNACE_2_NAME,
  icon = "__mega_furnace__/graphics/icons/mega-furnace-2.png",
  icon_size = 64,
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

local mega_inserter = table.deepcopy(data.raw.inserter["bulk-inserter"])
mega_inserter.name = MEGA_INSERTER_NAME
mega_inserter.icon = "__mega_furnace__/graphics/icons/mega-inserter.png"
mega_inserter.icon_size = 64
mega_inserter.icons = nil
mega_inserter.minable = {mining_time = 0.2, result = MEGA_INSERTER_NAME}
mega_inserter.max_health = 240
mega_inserter.energy_per_movement = "40kJ"
mega_inserter.energy_per_rotation = "40kJ"
mega_inserter.energy_source.drain = "7.5kW"
mega_inserter.extension_speed = 0.16
mega_inserter.rotation_speed = 0.075
mega_inserter.filter_count = 5
mega_inserter.next_upgrade = nil
mega_inserter.stack_size_bonus = 29
mega_inserter.uses_inserter_stack_size_bonus = false
mega_inserter.hand_base_picture.tint = {r = 0.84, g = 0.48, b = 1.0, a = 1.0}
mega_inserter.hand_closed_picture.tint = {r = 0.84, g = 0.48, b = 1.0, a = 1.0}
mega_inserter.hand_open_picture.tint = {r = 0.84, g = 0.48, b = 1.0, a = 1.0}
mega_inserter.platform_picture.sheet.tint = {r = 0.70, g = 0.36, b = 0.98, a = 1.0}

local mega_inserter_item = table.deepcopy(data.raw.item["bulk-inserter"])
mega_inserter_item.name = MEGA_INSERTER_NAME
mega_inserter_item.icon = "__mega_furnace__/graphics/icons/mega-inserter.png"
mega_inserter_item.icon_size = 64
mega_inserter_item.icons = nil
mega_inserter_item.place_result = MEGA_INSERTER_NAME
mega_inserter_item.order = "f[bulk-inserter]-z[mega-inserter]"
mega_inserter_item.stack_size = 50
mega_inserter_item.weight = 60 * kg

local mega_inserter_recipe = {
  type = "recipe",
  name = MEGA_INSERTER_NAME,
  enabled = false,
  energy_required = 12,
  ingredients = {
    {type = "item", name = "bulk-inserter", amount = 4},
    {type = "item", name = "processing-unit", amount = 20},
    {type = "item", name = "electric-engine-unit", amount = 20},
    {type = "item", name = "low-density-structure", amount = 10},
    {type = "item", name = "steel-plate", amount = 40}
  },
  results = {
    {type = "item", name = MEGA_INSERTER_NAME, amount = 1}
  }
}

local mega_inserter_technology = {
  type = "technology",
  name = MEGA_INSERTER_NAME,
  icon = "__mega_furnace__/graphics/icons/mega-inserter.png",
  icon_size = 64,
  effects = {
    {type = "unlock-recipe", recipe = MEGA_INSERTER_NAME}
  },
  prerequisites = {
    "inserter-capacity-bonus-6",
    MEGA_FURNACE_NAME
  },
  unit = {
    count = 1500,
    ingredients = inserter_tech_ingredients,
    time = 60
  }
}

local high_throughput_tint = {r = 0.82, g = 0.48, b = 1.0, a = 1.0}

local mega_transport_belt = table.deepcopy(data.raw["transport-belt"]["express-transport-belt"])
mega_transport_belt.name = MEGA_TRANSPORT_BELT_NAME
mega_transport_belt.icon = "__mega_furnace__/graphics/icons/mega-transport-belt.png"
mega_transport_belt.icon_size = 64
mega_transport_belt.icons = nil
mega_transport_belt.minable = {mining_time = 0.1, result = MEGA_TRANSPORT_BELT_NAME}
mega_transport_belt.related_underground_belt = MEGA_UNDERGROUND_BELT_NAME
mega_transport_belt.next_upgrade = nil
mega_transport_belt.speed = 0.1875
replace_filename_tree(
  mega_transport_belt.belt_animation_set,
  "__base__/graphics/entity/express-transport-belt/express-transport-belt.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-transport-belt.png"
)
clear_tint_tree(mega_transport_belt.belt_animation_set)

local mega_transport_belt_item = table.deepcopy(data.raw.item["express-transport-belt"])
mega_transport_belt_item.name = MEGA_TRANSPORT_BELT_NAME
mega_transport_belt_item.icon = "__mega_furnace__/graphics/icons/mega-transport-belt.png"
mega_transport_belt_item.icon_size = 64
mega_transport_belt_item.icons = nil
mega_transport_belt_item.place_result = MEGA_TRANSPORT_BELT_NAME
mega_transport_belt_item.order = "a[transport-belt]-d[mega-transport-belt]"

local mega_transport_belt_recipe = {
  type = "recipe",
  name = MEGA_TRANSPORT_BELT_NAME,
  category = "crafting-with-fluid",
  enabled = false,
  ingredients = {
    {type = "item", name = "express-transport-belt", amount = 2},
    {type = "item", name = "processing-unit", amount = 1},
    {type = "item", name = "electric-engine-unit", amount = 1},
    {type = "fluid", name = "lubricant", amount = 40}
  },
  results = {
    {type = "item", name = MEGA_TRANSPORT_BELT_NAME, amount = 2}
  }
}

local mega_underground_belt = table.deepcopy(data.raw["underground-belt"]["express-underground-belt"])
mega_underground_belt.name = MEGA_UNDERGROUND_BELT_NAME
mega_underground_belt.icon = "__mega_furnace__/graphics/icons/mega-underground-belt.png"
mega_underground_belt.icon_size = 64
mega_underground_belt.icons = nil
mega_underground_belt.minable = {mining_time = 0.1, result = MEGA_UNDERGROUND_BELT_NAME}
mega_underground_belt.next_upgrade = nil
mega_underground_belt.max_distance = 13
mega_underground_belt.speed = 0.1875
replace_filename_tree(
  mega_underground_belt.belt_animation_set,
  "__base__/graphics/entity/express-transport-belt/express-transport-belt.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-transport-belt.png"
)
replace_filename_tree(
  mega_underground_belt.structure,
  "__base__/graphics/entity/express-underground-belt/express-underground-belt-structure.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-underground-belt-structure.png"
)
clear_tint_tree(mega_underground_belt.belt_animation_set)
clear_tint_tree(mega_underground_belt.structure)

local mega_underground_belt_item = table.deepcopy(data.raw.item["express-underground-belt"])
mega_underground_belt_item.name = MEGA_UNDERGROUND_BELT_NAME
mega_underground_belt_item.icon = "__mega_furnace__/graphics/icons/mega-underground-belt.png"
mega_underground_belt_item.icon_size = 64
mega_underground_belt_item.icons = nil
mega_underground_belt_item.place_result = MEGA_UNDERGROUND_BELT_NAME
mega_underground_belt_item.order = "b[underground-belt]-d[mega-underground-belt]"

local mega_underground_belt_recipe = {
  type = "recipe",
  name = MEGA_UNDERGROUND_BELT_NAME,
  category = "crafting-with-fluid",
  enabled = false,
  energy_required = 2,
  ingredients = {
    {type = "item", name = "express-underground-belt", amount = 2},
    {type = "item", name = "processing-unit", amount = 4},
    {type = "item", name = "electric-engine-unit", amount = 4},
    {type = "fluid", name = "lubricant", amount = 80}
  },
  results = {
    {type = "item", name = MEGA_UNDERGROUND_BELT_NAME, amount = 2}
  }
}

local mega_splitter = table.deepcopy(data.raw.splitter["express-splitter"])
mega_splitter.name = MEGA_SPLITTER_NAME
mega_splitter.icon = "__mega_furnace__/graphics/icons/mega-splitter.png"
mega_splitter.icon_size = 64
mega_splitter.icons = nil
mega_splitter.minable = {mining_time = 0.1, result = MEGA_SPLITTER_NAME}
mega_splitter.related_transport_belt = MEGA_TRANSPORT_BELT_NAME
mega_splitter.next_upgrade = nil
mega_splitter.speed = 0.1875
replace_filename_tree(
  mega_splitter.belt_animation_set,
  "__base__/graphics/entity/express-transport-belt/express-transport-belt.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-transport-belt.png"
)
replace_filename_tree(
  mega_splitter.structure,
  "__base__/graphics/entity/express-splitter/express-splitter-north.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-splitter-north.png"
)
replace_filename_tree(
  mega_splitter.structure,
  "__base__/graphics/entity/express-splitter/express-splitter-east.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-splitter-east.png"
)
replace_filename_tree(
  mega_splitter.structure,
  "__base__/graphics/entity/express-splitter/express-splitter-south.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-splitter-south.png"
)
replace_filename_tree(
  mega_splitter.structure,
  "__base__/graphics/entity/express-splitter/express-splitter-west.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-splitter-west.png"
)
replace_filename_tree(
  mega_splitter.structure_patch,
  "__base__/graphics/entity/express-splitter/express-splitter-east-top_patch.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-splitter-east-top-patch.png"
)
replace_filename_tree(
  mega_splitter.structure_patch,
  "__base__/graphics/entity/express-splitter/express-splitter-west-top_patch.png",
  "__mega_furnace__/graphics/entity/mega-logistics/mega-splitter-west-top-patch.png"
)
clear_tint_tree(mega_splitter.belt_animation_set)
clear_tint_tree(mega_splitter.structure)
clear_tint_tree(mega_splitter.structure_patch)

local mega_splitter_item = table.deepcopy(data.raw.item["express-splitter"])
mega_splitter_item.name = MEGA_SPLITTER_NAME
mega_splitter_item.icon = "__mega_furnace__/graphics/icons/mega-splitter.png"
mega_splitter_item.icon_size = 64
mega_splitter_item.icons = nil
mega_splitter_item.place_result = MEGA_SPLITTER_NAME
mega_splitter_item.order = "c[splitter]-d[mega-splitter]"

local mega_splitter_recipe = {
  type = "recipe",
  name = MEGA_SPLITTER_NAME,
  category = "crafting-with-fluid",
  enabled = false,
  energy_required = 2,
  ingredients = {
    {type = "item", name = "express-splitter", amount = 1},
    {type = "item", name = "processing-unit", amount = 8},
    {type = "item", name = "electric-engine-unit", amount = 4},
    {type = "fluid", name = "lubricant", amount = 120}
  },
  results = {
    {type = "item", name = MEGA_SPLITTER_NAME, amount = 1}
  }
}

local mega_logistics_technology = {
  type = "technology",
  name = MEGA_LOGISTICS_TECH_NAME,
  icon = "__mega_furnace__/graphics/icons/mega-transport-belt.png",
  icon_size = 64,
  effects = {
    {type = "unlock-recipe", recipe = MEGA_TRANSPORT_BELT_NAME},
    {type = "unlock-recipe", recipe = MEGA_UNDERGROUND_BELT_NAME},
    {type = "unlock-recipe", recipe = MEGA_SPLITTER_NAME}
  },
  prerequisites = {
    MEGA_INSERTER_NAME
  },
  unit = {
    count = 1800,
    ingredients = logistics_tech_ingredients,
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
  mega_furnace_2_technology,
  mega_inserter,
  mega_inserter_item,
  mega_inserter_recipe,
  mega_inserter_technology,
  mega_transport_belt,
  mega_transport_belt_item,
  mega_transport_belt_recipe,
  mega_underground_belt,
  mega_underground_belt_item,
  mega_underground_belt_recipe,
  mega_splitter,
  mega_splitter_item,
  mega_splitter_recipe,
  mega_logistics_technology
})
