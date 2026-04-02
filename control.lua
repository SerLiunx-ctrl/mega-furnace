local MEGA_MINING_FIELD_NAME = "mega-mining-field"
local MEGA_MINING_FIELD_SPINDLE_ANIMATION_NAME = "mega-mining-field-spindle-animation"
local MEGA_MINING_FIELD_STATUS_GLOW_SPRITE_NAME = "mega-mining-field-status-glow"
local GUI_ROOT_NAME = "mega_mining_field_gui"
local OUTPUT_START_INDEX = 1
local OUTPUT_END_INDEX = 80
local PROCESS_INTERVAL = 1
local PRODUCT_OPTIONS = {"iron-ore", "copper-ore"}
local ALLOWED_PRODUCTS = {
  ["iron-ore"] = true,
  ["copper-ore"] = true
}

local function ensure_globals()
  storage.mega_mining_fields = storage.mega_mining_fields or {}
  storage.mega_mining_field_opened = storage.mega_mining_field_opened or {}
end

local function get_gui_root(player)
  if not (player and player.valid) then
    return nil
  end

  return player.gui.relative[GUI_ROOT_NAME] or player.gui.screen[GUI_ROOT_NAME]
end

local function get_inventory(entity)
  if not (entity and entity.valid) then
    return nil
  end

  return entity.get_inventory(defines.inventory.chest)
end

local function ensure_state_shape(state)
  if not state then
    return nil
  end

  if not ALLOWED_PRODUCTS[state.selected_product] then
    state.selected_product = "iron-ore"
  end
  state.progress = math.max(0, state.progress or 0)
  state.installed_drill_name = state.installed_drill_name or nil
  state.cycle_progress = math.min(1, math.max(0, state.cycle_progress or 0))
  state.blocked_full_output = state.blocked_full_output == true
  state.installed_modules = nil
  state.spindle_render_id = state.spindle_render_id or nil
  state.glow_render_id = state.glow_render_id or nil
  return state
end

local function reset_production_state(state)
  state.progress = 0
  state.cycle_progress = 0
  state.blocked_full_output = false
end

local function destroy_render_object(render_id)
  if not render_id then
    return
  end

  local render_object = render_id
  if type(render_id) == "number" then
    render_object = rendering.get_object_by_id(render_id)
  end
  if render_object then
    render_object.destroy()
  end
end

local function get_render_object(render_ref)
  if not render_ref then
    return nil
  end

  if type(render_ref) == "number" then
    return rendering.get_object_by_id(render_ref)
  end

  if render_ref.valid then
    return render_ref
  end

  return nil
end

local function destroy_mining_field_renderings(state)
  if not state then
    return
  end

  destroy_render_object(state.spindle_render_id)
  destroy_render_object(state.glow_render_id)
  state.spindle_render_id = nil
  state.glow_render_id = nil
end

local function ensure_mining_field_renderings(state)
  local entity = state and state.entity
  if not (entity and entity.valid) then
    return
  end

  local spindle = get_render_object(state.spindle_render_id)
  if not spindle then
    state.spindle_render_id = rendering.draw_animation({
      animation = MEGA_MINING_FIELD_SPINDLE_ANIMATION_NAME,
      surface = entity.surface,
      target = {entity = entity, offset = {0, -0.10}},
      x_scale = 1,
      y_scale = 1,
      render_layer = "object",
      animation_speed = 0,
      visible = false
    })
  end

  local glow = get_render_object(state.glow_render_id)
  if not glow then
    state.glow_render_id = rendering.draw_light({
      sprite = MEGA_MINING_FIELD_STATUS_GLOW_SPRITE_NAME,
      surface = entity.surface,
      target = {entity = entity, offset = {0, -0.45}},
      scale = 0.34,
      intensity = 0.42,
      minimum_darkness = 0,
      color = {r = 1.0, g = 0.55, b = 0.18},
      visible = false
    })
  end
end

local function update_mining_field_renderings(state, active, rate)
  ensure_mining_field_renderings(state)

  local spindle = get_render_object(state.spindle_render_id)
  if spindle then
    spindle.visible = active
    if active then
      spindle.animation_speed = math.min(0.34, 0.11 + rate * 0.0012)
    else
      spindle.animation_speed = 0
    end
  end

  local glow = get_render_object(state.glow_render_id)
  if glow then
    glow.visible = active
  end
end

local function is_valid_mining_drill_item(item_name)
  local prototype = item_name and prototypes.item[item_name] or nil
  if not prototype then
    return false
  end

  local place_result = prototype.place_result
  return place_result and place_result.valid and place_result.type == "mining-drill"
end

local function get_drill_output_rate(drill_name)
  if not is_valid_mining_drill_item(drill_name) then
    return 0
  end

  local place_result = prototypes.item[drill_name].place_result
  return (place_result.mining_speed or 0) * 2
end

local function spill_item(entity, item_name, position)
  if entity and entity.valid and item_name then
    entity.surface.spill_item_stack(position or entity.position, {name = item_name, count = 1}, true, entity.force, false)
  end
end

local function register_mining_field(entity)
  if not (entity and entity.valid and entity.name == MEGA_MINING_FIELD_NAME and entity.unit_number) then
    return
  end

  local state = ensure_state_shape(storage.mega_mining_fields[entity.unit_number])
  if state then
    state.entity = entity
    return
  end

  storage.mega_mining_fields[entity.unit_number] = ensure_state_shape({
    entity = entity,
    selected_product = "iron-ore",
    progress = 0,
    installed_drill_name = nil,
    cycle_progress = 0,
    blocked_full_output = false
  })
end

local function destroy_gui(player)
  if not (player and player.valid) then
    return
  end

  local root = get_gui_root(player)
  if root then
    root.destroy()
  end

  storage.mega_mining_field_opened[player.index] = nil
end

local function unregister_mining_field(entity)
  if not (entity and entity.valid and entity.unit_number) then
    return
  end

  local state = storage.mega_mining_fields[entity.unit_number]
  destroy_mining_field_renderings(state)
  if state and state.installed_drill_name then
    spill_item(entity, state.installed_drill_name, entity.position)
  end
  storage.mega_mining_fields[entity.unit_number] = nil

  for player_index, unit_number in pairs(storage.mega_mining_field_opened) do
    if unit_number == entity.unit_number then
      local player = game.get_player(player_index)
      if player then
        destroy_gui(player)
      end
    end
  end
end

local function scan_existing_mining_fields()
  ensure_globals()
  rendering.clear("mega_furnace")
  local previous_states = storage.mega_mining_fields or {}
  storage.mega_mining_fields = {}

  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = MEGA_MINING_FIELD_NAME}) do
      register_mining_field(entity)
      local state = ensure_state_shape(storage.mega_mining_fields[entity.unit_number])
      local previous = previous_states[entity.unit_number]
      if previous then
        state.selected_product = previous.selected_product or state.selected_product
        state.progress = previous.progress or state.progress
        state.installed_drill_name = previous.installed_drill_name or state.installed_drill_name
        state.cycle_progress = previous.cycle_progress or state.cycle_progress
        state.blocked_full_output = previous.blocked_full_output or state.blocked_full_output

        if previous.installed_modules then
          for _, module_name in pairs(previous.installed_modules) do
            if module_name then
              spill_item(entity, module_name, entity.position)
            end
          end
        end
      end

      ensure_mining_field_renderings(state)
    end
  end
end

local function get_mining_field_state_from_player(player)
  local unit_number = storage.mega_mining_field_opened[player.index]
  if not unit_number then
    return nil
  end

  local state = ensure_state_shape(storage.mega_mining_fields[unit_number])
  if not state or not (state.entity and state.entity.valid) then
    destroy_gui(player)
    return nil
  end

  return state
end

local function insert_into_output_slots(inventory, item_name, amount)
  if amount <= 0 then
    return 0
  end

  local item_prototype = prototypes.item[item_name]
  if not item_prototype then
    return 0
  end

  local remaining = amount

  for slot_index = OUTPUT_START_INDEX, math.min(OUTPUT_END_INDEX, #inventory) do
    if remaining <= 0 then
      break
    end

    local stack = inventory[slot_index]
    if stack.valid_for_read and stack.name == item_name and stack.count < item_prototype.stack_size then
      local add = math.min(remaining, item_prototype.stack_size - stack.count)
      stack.count = stack.count + add
      remaining = remaining - add
    end
  end

  for slot_index = OUTPUT_START_INDEX, math.min(OUTPUT_END_INDEX, #inventory) do
    if remaining <= 0 then
      break
    end

    local stack = inventory[slot_index]
    if not stack.valid_for_read then
      local add = math.min(remaining, item_prototype.stack_size)
      stack.set_stack({name = item_name, count = add})
      remaining = remaining - add
    end
  end

  return amount - remaining
end

local function can_insert_amount(inventory, item_name, amount)
  if amount <= 0 then
    return true
  end

  local item_prototype = prototypes.item[item_name]
  if not item_prototype then
    return false
  end

  local remaining = amount

  for slot_index = OUTPUT_START_INDEX, math.min(OUTPUT_END_INDEX, #inventory) do
    local stack = inventory[slot_index]
    if stack.valid_for_read and stack.name == item_name then
      remaining = remaining - (item_prototype.stack_size - stack.count)
      if remaining <= 0 then
        return true
      end
    end
  end

  for slot_index = OUTPUT_START_INDEX, math.min(OUTPUT_END_INDEX, #inventory) do
    local stack = inventory[slot_index]
    if not stack.valid_for_read then
      remaining = remaining - item_prototype.stack_size
      if remaining <= 0 then
        return true
      end
    end
  end

  return false
end

local function get_insert_capacity(inventory, item_name)
  local item_prototype = prototypes.item[item_name]
  if not item_prototype then
    return 0
  end

  local capacity = 0

  for slot_index = OUTPUT_START_INDEX, math.min(OUTPUT_END_INDEX, #inventory) do
    local stack = inventory[slot_index]
    if stack.valid_for_read and stack.name == item_name then
      capacity = capacity + (item_prototype.stack_size - stack.count)
    elseif not stack.valid_for_read then
      capacity = capacity + item_prototype.stack_size
    end
  end

  return capacity
end

local function build_gui(player, entity)
  destroy_gui(player)
  register_mining_field(entity)

  local state = ensure_state_shape(storage.mega_mining_fields[entity.unit_number])
  storage.mega_mining_field_opened[player.index] = entity.unit_number

  local frame = player.gui.relative.add({
    type = "frame",
    name = GUI_ROOT_NAME,
    direction = "vertical",
    anchor = {
      gui = defines.relative_gui_type.container_gui,
      position = defines.relative_gui_position.right
    }
  })
  frame.style.minimal_width = 280

  frame.add({
    type = "label",
    caption = {"gui.mega-mining-field-title"},
    style = "frame_title"
  })

  local body = frame.add({
    type = "frame",
    name = "mega_mining_field_body",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  })

  body.add({
    type = "label",
    caption = {"gui.mega-mining-field-resource"}
  })

  local resource_flow = body.add({
    type = "flow",
    name = "mega_mining_field_resource_flow",
    direction = "horizontal"
  })
  for _, product_name in ipairs(PRODUCT_OPTIONS) do
    resource_flow.add({
      type = "sprite-button",
      name = "mega_mining_field_product_" .. product_name,
      style = "slot_button",
      sprite = "item/" .. product_name,
      tooltip = {"item-name." .. product_name},
      tags = {action = "select-product", product = product_name}
    })
  end

  body.add({
    type = "label",
    caption = {"gui.mega-mining-field-drill-slot"}
  })
  body.add({
    type = "sprite-button",
    name = "mega_mining_field_drill_slot",
    style = "slot_button",
    tags = {action = "drill-slot"},
    tooltip = {"gui.mega-mining-field-empty-drill"}
  })

  body.add({
    type = "label",
    name = "mega_mining_field_rate_label"
  })
  body.add({
    type = "progressbar",
    name = "mega_mining_field_progressbar",
    value = 0
  })
  body.add({
    type = "label",
    name = "mega_mining_field_status_label"
  })
  body.add({
    type = "label",
    name = "mega_mining_field_buffer_label",
    style = "caption_label"
  })
end

local function refresh_gui(player)
  local frame = get_gui_root(player)
  if not frame then
    return
  end

  local state = get_mining_field_state_from_player(player)
  if not state then
    return
  end

  local inventory = get_inventory(state.entity)
  if not inventory then
    destroy_gui(player)
    return
  end

  local body = frame["mega_mining_field_body"]
  if not body then
    destroy_gui(player)
    return
  end

  local resource_flow = body["mega_mining_field_resource_flow"]
  local drill_button = body["mega_mining_field_drill_slot"]
  local rate_label = body["mega_mining_field_rate_label"]
  local progressbar = body["mega_mining_field_progressbar"]
  local status_label = body["mega_mining_field_status_label"]
  local buffer_label = body["mega_mining_field_buffer_label"]
  if not (resource_flow and drill_button and rate_label and progressbar and status_label and buffer_label) then
    destroy_gui(player)
    return
  end

  for _, product_name in ipairs(PRODUCT_OPTIONS) do
    local button = resource_flow["mega_mining_field_product_" .. product_name]
    if button then
      button.toggled = state.selected_product == product_name
    end
  end

  if state.installed_drill_name then
    drill_button.sprite = "item/" .. state.installed_drill_name
    drill_button.number = 1
    drill_button.tooltip = {"item-name." .. state.installed_drill_name}
  else
    drill_button.sprite = "utility/add"
    drill_button.number = nil
    drill_button.tooltip = {"gui.mega-mining-field-empty-drill"}
  end

  local rate = get_drill_output_rate(state.installed_drill_name)
  rate_label.caption = {
    "gui.mega-mining-field-rate",
    string.format("%.2f", rate)
  }
  progressbar.value = math.min(1, math.max(0, state.cycle_progress or 0))

  if not state.installed_drill_name then
    status_label.caption = {"gui.mega-mining-field-status-no-drill"}
  elseif state.blocked_full_output then
    status_label.caption = {"gui.mega-mining-field-status-full-output"}
  elseif not is_valid_mining_drill_item(state.installed_drill_name) then
    status_label.caption = {"gui.mega-mining-field-status-invalid-drill"}
  else
    status_label.caption = {
      "gui.mega-mining-field-status-working",
      string.format("%.2f", rate),
      {"item-name." .. state.selected_product}
    }
  end

  local total_output = 0
  for slot_index = OUTPUT_START_INDEX, OUTPUT_END_INDEX do
    local stack = inventory[slot_index]
    if stack.valid_for_read then
      total_output = total_output + stack.count
    end
  end
  buffer_label.caption = {
    "gui.mega-mining-field-buffer-count",
    total_output
  }
end

local function handle_drill_slot_click(player, state)
  if state.installed_drill_name then
    if player.cursor_stack and player.cursor_stack.valid_for_read then
      local inserted = player.insert({name = state.installed_drill_name, count = 1})
      if inserted <= 0 then
        player.print({"gui.mega-mining-field-no-space"})
        return
      end
    else
      player.cursor_stack.set_stack({name = state.installed_drill_name, count = 1})
    end

    state.installed_drill_name = nil
    reset_production_state(state)
    return
  end

  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and is_valid_mining_drill_item(cursor_stack.name) then
    state.installed_drill_name = cursor_stack.name
    cursor_stack.count = cursor_stack.count - 1
    reset_production_state(state)
    return
  end

  player.print({"gui.mega-mining-field-cannot-insert"})
end

local function try_flush_output(state, inventory, product_name)
  local pending_amount = math.floor(state.progress)
  if pending_amount <= 0 then
    state.blocked_full_output = false
    return true
  end

  local insert_capacity = get_insert_capacity(inventory, product_name)
  if insert_capacity <= 0 then
    state.blocked_full_output = true
    state.cycle_progress = 0
    return false
  end

  local inserted = insert_into_output_slots(inventory, product_name, math.min(pending_amount, insert_capacity))
  state.progress = state.progress - inserted
  state.blocked_full_output = math.floor(state.progress) > 0
  return not state.blocked_full_output
end

local function process_mining_fields()
  for unit_number, state in pairs(storage.mega_mining_fields) do
    local entity = state.entity
    if not (entity and entity.valid) then
      storage.mega_mining_fields[unit_number] = nil
    else
      ensure_state_shape(state)
      local inventory = get_inventory(entity)
      local product_name = state.selected_product
      if inventory and ALLOWED_PRODUCTS[product_name] and state.installed_drill_name and is_valid_mining_drill_item(state.installed_drill_name) then
        local rate = get_drill_output_rate(state.installed_drill_name)
        update_mining_field_renderings(state, not state.blocked_full_output, rate)
        if state.blocked_full_output then
          if try_flush_output(state, inventory, product_name) then
            state.cycle_progress = 0
          end
        else
          state.cycle_progress = math.min(1, state.cycle_progress + (PROCESS_INTERVAL / 60))
          if state.cycle_progress >= 1 then
            state.progress = state.progress + rate
            try_flush_output(state, inventory, product_name)
            state.cycle_progress = 0
          end
        end
      else
        update_mining_field_renderings(state, false, 0)
        state.cycle_progress = 0
        state.progress = 0
        state.blocked_full_output = false
      end
    end
  end

  for player_index, _ in pairs(storage.mega_mining_field_opened) do
    local player = game.get_player(player_index)
    if player and player.valid then
      refresh_gui(player)
    end
  end
end

script.on_init(function()
  ensure_globals()
  scan_existing_mining_fields()
end)

script.on_configuration_changed(function()
  ensure_globals()
  scan_existing_mining_fields()
end)

script.on_event({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive
}, function(event)
  register_mining_field(event.created_entity or event.entity)
end)

script.on_event({
  defines.events.on_pre_player_mined_item,
  defines.events.on_robot_pre_mined,
  defines.events.on_entity_died,
  defines.events.script_raised_destroy
}, function(event)
  unregister_mining_field(event.entity)
end)

script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  local entity = event.entity
  if entity and entity.valid and entity.name == MEGA_MINING_FIELD_NAME then
    player.opened = entity
    build_gui(player, entity)
    refresh_gui(player)
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  local element = event.element
  if element and element.valid and element.name == GUI_ROOT_NAME then
    destroy_gui(player)
    return
  end

  local entity = event.entity
  if entity and entity.valid and entity.name == MEGA_MINING_FIELD_NAME then
    destroy_gui(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  local element = event.element
  if not (element and element.valid and element.tags and element.tags.action) then
    return
  end

  local state = get_mining_field_state_from_player(player)
  if not state then
    return
  end

  if element.tags.action == "select-product" then
    if ALLOWED_PRODUCTS[element.tags.product] then
      if state.selected_product ~= element.tags.product then
        state.selected_product = element.tags.product
        reset_production_state(state)
      end
      refresh_gui(player)
    end
    return
  end

  if element.tags.action == "drill-slot" then
    handle_drill_slot_click(player, state)
    refresh_gui(player)
  end
end)

script.on_nth_tick(PROCESS_INTERVAL, process_mining_fields)
