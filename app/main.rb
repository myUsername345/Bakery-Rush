def tick(args)
	# Play music
  if Kernel.tick_count == 0
    args.audio[:music] = {
      input: 'sounds/bg-music-trimmed.mp3',
      gain: 1.0,
      looping: true
    }
	end

  if args.inputs.keyboard.key_down.space
    args.state.clear!
    return
  end

  screen_w = 1280
  screen_h = 720

  args.outputs.sprites << {
    x: 0, y: 0, w: screen_w, h: screen_h,
    path: "sprites/Bakery_Cafe_Setting.png"
  }

  # Init state
  args.state.starting_screen = true if args.state.starting_screen.nil?
  args.state.shop.onFire ||= false
  args.state.flour_count ||= 0
  args.state.milk_count ||= 0
  args.state.cherry_count ||= 0
  args.state.chocolate_count ||= 0
  args.state.tablet_gui_open ||= false
  args.state.selected_receipt ||= nil
  args.state.employee_facing_right = true if args.state.employee_facing_right.nil?
	args.state.recipes = [
		{type: :bread, flour: 1, milk: 1, x: 30},
		{type: :donut, flour: 1, chocolate: 1, x: 140},
		{type: :cupcake, flour: 1, milk: 1, cherry: 1, x: 250}
	]

  checkOrderTimers(args)

  # New state flags for overlays
  args.state.oven_failure_overlay ||= false
  args.state.tablet_success_overlay ||= false
  args.state.ovenpopupenabled ||= false

  # Shop state
  args.state.shop_money ||= 100
  args.state.shop_messages ||= []
  args.state.game_time ||= 10 * 60 # Starting at 10:00 AM
  args.state.floating_money ||= []
  
  # Order system
  args.state.orders ||= []
  args.state.completed_orders ||= []
  args.state.baked_items ||= []
  args.state.baked ||= {cupcake: 0, donut: 0, bread: 0}
  args.state.next_receipt_number ||= 1
  args.state.last_order_generation ||= 0
  args.state.delivery_guy_message ||= ""
  args.state.delivery_guy_message_timer ||= 0

  # Supply box costs
  args.state.supply_cost ||= 3

  # Generate orders periodically (every 30 seconds of game time)
  if args.state.game_time < 19 * 60 && # Stop generating orders at 7pm
     args.state.game_time - args.state.last_order_generation > 25 &&
     args.state.orders.length < 3 &&
     !args.state.shop.onFire
    generate_new_order(args)
    args.state.last_order_generation = args.state.game_time
  end

  # Check win/loss conditions
  if args.state.game_time >= 20 * 60 # 8pm
    if all_orders_completed(args)
      args.state.tablet_success_overlay = true
    else
      args.state.oven_failure_overlay = true
    end
  end

  # Oven failure overlay (Loss screen)
  if args.state.oven_failure_overlay
    args.outputs.sprites << {
      x: 0, y: 0, w: screen_w, h: screen_h,
      path: :pixel, r: 50, g: 50, b: 50, a: 180
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2 + 40,
      text: "You did not meet all customer orders!",
      size: 36, alignment_enum: 1,
      r: 255, g: 255, b: 255
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2 - 20,
      text: "Click here to play again",
      size: 28, alignment_enum: 1,
      r: 255, g: 255, b: 255
    }

    if args.inputs.mouse.click
      args.state.clear!
      args.state.starting_screen = true
      return
    end
    return
  end

  # Tablet success overlay (Win screen)
  if args.state.tablet_success_overlay
    args.outputs.sprites << {
      x: 0, y: 0, w: screen_w, h: screen_h,
      path: :pixel, r: 50, g: 50, b: 50, a: 180
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2 + 60,
      text: "Congrats! You met all customer orders!",
      size: 36, alignment_enum: 1,
      r: 255, g: 255, b: 255
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2 + 10,
      text: "Orders Completed: #{args.state.completed_orders.length}",
      size: 32, alignment_enum: 1,
      r: 255, g: 255, b: 255
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2 - 40,
      text: "Click here to play again",
      size: 28, alignment_enum: 1,
      r: 255, g: 255, b: 255
    }

    if args.inputs.mouse.click
      args.state.clear!
      args.state.starting_screen = true
      return
    end

    return
  end

  if args.state.starting_screen
    args.outputs.sprites << {
      x: 0, y: 0, w: screen_w, h: screen_h,
      path: :pixel, r: 50, g: 50, b: 50, a: 180
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2,
      text: "Click here to play", size: 48, alignment_enum: 1,
      r: 255, g: 255, b: 255
    }
    args.state.starting_screen = false if args.inputs.mouse.click
    return
  end

  # Update shop
  update_shop(args)

  if args.inputs.mouse.click
    mx = args.inputs.mouse.x
    my = args.inputs.mouse.y
  end

  if args.state.shop.onFire && !args.state.fireStarted
    args.state.fireStarted = true
    args.state.fireTimeElapsed = 0
    args.state.fireFrameCounter = 0
    args.state.fireFrame = 0
  end

  # Reset fire state when fire is extinguished
  if !args.state.shop.onFire && args.state.fireStarted
  args.state.fireStarted = false
  args.state.fireTimeElapsed = 0  # Reset the fire progress
  args.state.fireFrameCounter = 0
  args.state.fireFrame = 0
end

  if args.state.fireStarted
    # Track how long the fire has been burning (in frames)
    args.state.fireTimeElapsed ||= 0
    args.state.fireTimeElapsed += 1

    # Update fire animation frame every ~0.3s
    args.state.fireFrameCounter ||= 0
    args.state.fireFrameCounter += 1
    if args.state.fireFrameCounter > 18
      args.state.fireFrameCounter = 0
      args.state.fireFrame ||= 0
      args.state.fireFrame = (args.state.fireFrame + 1) % 2
    end
  end

  args.outputs.sprites << {
    x: 940, y: 325, w: 140, h: 140,
    path: "sprites/FireExtinguisher.png" 
  }

  if args.state.shop.onFire
    render_fire(args)
  end

  if args.state.shop.onFire && mx && my
    if mx.between?(940, 1080) && my.between?(325, 465)
      args.state.shop.onFire = false
      add_shop_message(args, "Fire extinguished! Store is safe.")
    end
  end

  # Oven
  oven_x = screen_w / 2 - 600
  oven_y = screen_h / 2 - 230
  oven_w = 265
  oven_h = 193
  args.outputs.sprites << {
    x: oven_x, y: oven_y,
    w: oven_w, h: oven_h, path: "sprites/Oven.png"
  }

  # Draw baked items
  for i in 0..((args.state.baked)[:cupcake] -1) do
    args.outputs.sprites << {
      x: oven_x + oven_w,
      y: oven_y + 25*i,
      w: 50,
      h: 50,
      path: "sprites/Cupcake.png"
    }
  end

  for i in 0..((args.state.baked)[:donut] -1) do
    args.outputs.sprites << {
      x: oven_x + oven_w + 50,
      y: oven_y + 25*i,
      w: 50,
      h: 50,
      path: "sprites/Donut.png"
    }
  end

  for i in 0..((args.state.baked)[:bread] -1) do
    args.outputs.sprites << {
      x: oven_x + oven_w + 100,
      y: oven_y + 25*i,
      w: 50,
      h: 50,
      path: "sprites/Bread.png"
    }
  end

  # Tablet
  tablet_w, tablet_h = 200, 200
  tablet_x = screen_w / 2 + 200
  tablet_y = screen_h / 2 - 230
  args.outputs.sprites << {
    x: tablet_x, y: tablet_y, w: tablet_w, h: tablet_h,
    path: "sprites/Tablet.png"
  }

  # Show tablet GUI if open
  if args.state.tablet_gui_open
    render_tablet_gui(args, tablet_x, tablet_y, tablet_w, tablet_h)
  end

  # Hotbar background
  hotbar_x = 0
  hotbar_y = 20
  args.outputs.primitives << {
    x: hotbar_x, y: hotbar_y, w: 500, h: 80,
    r: 140, g: 58, b: 44, a: 250,
		path: 'sprites/Long_Panel_Brown.png',
    primitive_marker: :sprite
  }

  # Ingredient display
  ingredients = [
    { icon: "Flour.png", count: args.state.flour_count, w: 50, h: 50 },
    { icon: "Milk.png", count: args.state.milk_count, w: 25, h: 60 },
    { icon: "Cherry.png", count: args.state.cherry_count, w: 32, h: 32 },
    { icon: "Chocolate.png", count: args.state.chocolate_count, w: 32, h: 32 }
  ]

  ingredients.each_with_index do |item, i|
    icon_x = hotbar_x + 30 + i * 120
    icon_y = hotbar_y + 10

    args.outputs.primitives << {
      x: icon_x, y: icon_y,
      w: item[:w], h: item[:h],
      z: 1,
      path: "sprites/#{item[:icon]}",
			primitive_marker: :sprite
    }

    args.outputs.labels << {
      x: icon_x + item[:w] + 8, y: icon_y + 30,
      text: "x #{item[:count]}", size: 24,
      r: 255, g: 255, b: 255
    }
  end

  # SupplyBox 
  supply_box_w, supply_box_h = 150, 200
  supply_box_x, supply_box_y = screen_w - supply_box_w - 0, -30
  args.outputs.sprites << {
    x: supply_box_x, y: supply_box_y, w: supply_box_w, h: supply_box_h,
    path: "sprites/SupplyBox.png"
  }

  # Show supply box cost
  args.outputs.labels << {
    x: supply_box_x + supply_box_w / 2, y: supply_box_y + supply_box_h + 10,
    text: "Supply: $#{args.state.supply_cost}", size: 24, alignment_enum: 1,
    r: 255, g: 255, b: 0
  }

  # Employee sprite
  employee_w = 300
  employee_h = 500
  employee_x = screen_w / 2 - employee_w / 2
  employee_y = screen_h / 2 - 167
  args.outputs.sprites << {
    x: employee_x, y: employee_y, w: employee_w, h: employee_h,
    path: "sprites/Employee.png",
    flip_horizontally: !args.state.employee_facing_right
  }
	employee_text_w = 200
	employee_text_h = 80
	args.outputs.primitives << {
		x: employee_x+employee_w/2-employee_text_w/2, y: employee_y+employee_text_h/2, w: employee_text_w, h: employee_text_h,
		r: 140, g: 58, b: 44, a: 250,
		path: 'sprites/Long_Panel_Brown.png',
		primitive_marker: :sprite
	}
	args.outputs.labels << {
		x: employee_x+employee_w/2, y: employee_y+employee_text_h/2+50,
		text: "Deliver", size: 24, alignment_enum: 1,
		r: 255, g: 255, b: 255
	}

  # Show delivery guy message
  if args.state.delivery_guy_message_timer > 0
    message_x = employee_x + employee_w / 2
    message_y = employee_y + employee_h + 20
    message_text = args.state.delivery_guy_message
    
    text_width = message_text.length * 12  
    text_height = 30
    
    # Message background
    args.outputs.primitives << {
      x: message_x - text_width / 2 - 10,
      y: message_y - 10,
      w: text_width + 20,
      h: text_height,
      primitive_marker: :solid
    }
    
    # Message text
    args.outputs.labels << {
      x: message_x, y: message_y + 10,
      text: message_text,
      size: 20, alignment_enum: 1,
      r: 255, g: 255, b: 255
    }
  
    args.state.delivery_guy_message_timer -= 1
  end

  # Oven popup setup
  oven_popup_offset_x = oven_x
  oven_popup_offset_y = oven_y + oven_h + 20

  # Logic for Oven Popup
  args.state.ovenpopupenabled ||= false
  args.outputs[:oven_popup].w = 250
  args.outputs[:oven_popup].h = 150
  args.outputs[:oven_popup].background_color = [0, 0, 0, 100]

  args.outputs[:oven_popup].sprites << {
    x: 25,
    y: 75,
    w: 50,
    h: 50,
    path: "sprites/Cupcake.png"
  }
  args.outputs[:oven_popup].sprites << {
    x: 100,
    y: 75,
    w: 50,
    h: 50,
    path: "sprites/Donut.png"
  }
  args.outputs[:oven_popup].sprites << {
    x: 175,
    y: 75,
    w: 50,
    h: 50,
    path: "sprites/Bread.png"
  }

  args.state.cupcakebutton = {x: 25, y: 25, w:50, h: 25}
  args.state.donutbutton = {x: 100, y: 25, w:50, h: 25}
  args.state.breadbutton = {x: 175, y: 25, w:50, h: 25}
  args.outputs[:oven_popup].sprites << args.state.cupcakebutton
  args.outputs[:oven_popup].sprites << args.state.donutbutton
  args.outputs[:oven_popup].sprites << args.state.breadbutton

  oven_popup_offset_x = 0
  oven_popup_offset_y = 320

  if args.state.ovenpopupenabled
    render_oven_popup(args, oven_popup_offset_x, oven_popup_offset_y)
  end

  # Click logic
  if args.inputs.mouse.click
    mx = args.inputs.mouse.x
    my = args.inputs.mouse.y

    if args.state.ovenpopupenabled && mx.between?(args.state.cupcakebutton.x + oven_popup_offset_x , args.state.cupcakebutton.x + args.state.cupcakebutton.w + oven_popup_offset_x)
      # Logic for baking cupcakes
    elsif args.state.ovenpopupenabled && mx.between?(args.state.donutbutton.x + oven_popup_offset_x, args.state.donutbutton.x + args.state.donutbutton.w + oven_popup_offset_x)
      # Logic for baking donuts
    elsif args.state.ovenpopupenabled && mx.between?(args.state.breadbutton.x + oven_popup_offset_x, args.state.breadbutton.x + args.state.breadbutton.w + oven_popup_offset_x)
      # Logic for baking bread
    end

    # Oven popup button clicks
    if args.state.ovenpopupenabled
      handle_oven_popup_clicks(args, mx, my, oven_popup_offset_x, oven_popup_offset_y)
    end

    # Oven click toggles popup
    if mx.between?(oven_x, oven_x + oven_w) &&
       my.between?(oven_y, oven_y + oven_h)
      args.state.ovenpopupenabled = !args.state.ovenpopupenabled
    end

    # Tablet click opens orders GUI
    if mx.between?(tablet_x, tablet_x + tablet_w) &&
       my.between?(tablet_y, tablet_y + tablet_h)
      args.state.tablet_gui_open = !args.state.tablet_gui_open
    end

    # SupplyBox click (costs money)
    if mx.between?(supply_box_x, supply_box_x + supply_box_w) &&
       my.between?(supply_box_y, supply_box_y + supply_box_h)
      if args.state.shop_money >= args.state.supply_cost
        args.state.shop_money -= args.state.supply_cost
        case rand(4)
        when 0 then args.state.flour_count += 2
        when 1 then args.state.milk_count += 2
        when 2 then args.state.cherry_count += 1
        when 3 then args.state.chocolate_count += 1
        end
        add_shop_message(args, "Got ingredients for $#{args.state.supply_cost}!")
      else
        add_shop_message(args, "Not enough money for supplies!")
      end
    end

    # Employee flip
    if mx.between?(employee_x, employee_x + employee_w) &&
       my.between?(employee_y, employee_y + employee_h)
      args.state.employee_facing_right = !args.state.employee_facing_right
			
			# Check if delivery guy can deliver any available baked items
			if args.state.baked[:bread] > 0
				check_delivery(args, :bread)
			elsif args.state.baked[:donut] > 0
				check_delivery(args, :donut)
			elsif args.state.baked[:cupcake] > 0
				check_delivery(args, :cupcake)
			else
				args.state.delivery_guy_message = "I don't have anything to deliver!"
				args.state.delivery_guy_message_timer = 120
			end
				
    end
  end

  # Render shop UI
  render_shop_ui(args)
end



def generate_new_order(args)
  items = [:bread, :donut, :cupcake]
  revenues = {bread: 8, donut: 6, cupcake: 10}
  
  item = items.sample
  revenue = revenues[item]
  
  order = {
    id: args.state.next_receipt_number,
    item: item,
    revenue: revenue,
    time_placed: args.state.game_time
  }
  
  args.state.orders << order
  args.state.next_receipt_number += 1
  add_shop_message(args, "New order: #{item.capitalize} for $#{revenue}")
end

def all_orders_completed(args)
  args.state.orders.empty?
end

def render_tablet_gui(args, tablet_x, tablet_y, tablet_w, tablet_h)
  gui_x = tablet_x + tablet_w
  gui_y = tablet_y
  gui_w = 240
  gui_h = 400
  
  # GUI Background
  args.outputs.primitives << {
    x: gui_x, y: gui_y, w: gui_w, h: gui_h,
    r: 140, g: 58, b: 44, a: 250,
		path: 'sprites/panel_brown.png',
    primitive_marker: :sprite
  }

  # Orders list
  if args.state.orders.empty?
    args.outputs.labels << {
      x: gui_x + gui_w/2, y: gui_y + gui_h / 2,
      text: "No orders yet!", size: 20, alignment_enum: 1,
      r: 200, g: 200, b: 200
    }
  else
    args.state.orders.each_with_index do |order, i|
      order_y = gui_y + gui_h - 60 - (i * 100)
      
      # Order details
      args.outputs.labels << {
        x: gui_x + 20, y: order_y,
        text: "Receipt ##{order[:id]}", size: 18,
        r: 255, g: 255, b: 255
      }
      
      args.outputs.labels << {
        x: gui_x + 20, y: order_y - 20,
        text: "Item: #{order[:item].capitalize}", size: 16,
        r: 255, g: 255, b: 255
      }
      
      args.outputs.labels << {
        x: gui_x + 20, y: order_y - 40,
        text: "Revenue: $#{order[:revenue]}", size: 16,
        r: 0, g: 255, b: 0
      }
      
      # Item sprite
      args.outputs.primitives << {
        x: gui_x + gui_w - 70, y: order_y - 35,
        w: 40, h: 40,
        path: "sprites/#{order[:item].capitalize}.png",
        primitive_marker: :sprite
      }
    end
  end
end

def render_oven_popup(args, offset_x, offset_y)
  popup_w = 350
  popup_h = 150
  
  # Oven popup background
  args.outputs.primitives << {
    x: offset_x, y: offset_y,
    w: popup_w, h: popup_h,
    r: 140, g: 58, b: 44, a: 250,
		path: 'sprites/panel_brown.png',
    primitive_marker: :sprite
  }
  
  # Baking options
  recipes = [
    {type: :bread, flour: 1, milk: 2, x: 30},
    {type: :donut, flour: 1, chocolate: 1, x: 140},
    {type: :cupcake, flour: 1, milk: 1, cherry: 1, x: 250}
  ]
  
  recipes.each do |recipe|
    recipe_x = offset_x + recipe[:x]
    recipe_y = offset_y + 40
    
    # Item sprite
    args.outputs.primitives << {
      x: recipe_x, y: recipe_y + 40,
      w: 40, h: 40,
      path: "sprites/#{recipe[:type].capitalize}.png",
      primitive_marker: :sprite
    }
    
    
    # Recipe requirements
    ingredients_text = []
    ingredients_text << "#{recipe[:flour]} Flour" if recipe[:flour]
    ingredients_text << "#{recipe[:milk]} Milk" if recipe[:milk]
    ingredients_text << "#{recipe[:chocolate]} Chocolate" if recipe[:chocolate]
    ingredients_text << "#{recipe[:cherry]} Cherry" if recipe[:cherry]

    
    ingredients_text.each_with_index do |ingredient, idx|
      args.outputs.labels << {
        x: recipe_x + 20, y: recipe_y + 25 - (idx * 18),
        text: ingredient, size: 10, alignment_enum: 1,
        r: 255, g: 255, b: 255
      }
    end
    
  end
end

def handle_oven_popup_clicks(args, mx, my, offset_x, offset_y)

  args.state.recipes.each do |recipe|
    sprite_x = offset_x + recipe[:x]
    sprite_y = offset_y + 40 + 40  # Item sprite position
    
    # Check if click is on the item sprite (40x40 pixels)
    if mx.between?(sprite_x, sprite_x + 40) &&
       my.between?(sprite_y, sprite_y + 40)
      
      if can_bake_recipe(args, recipe)
        consume_recipe_ingredients(args, recipe)
        
        # Add baked item
				show_items(args, recipe)
        args.state.baked_items << {type: recipe[:type]}
				add_shop_message(args, "Baked #{recipe[:type]}!")
				args.state.ovenpopupenabled = false
        
      else
        add_shop_message(args, "Not enough ingredients!")
      end
    end
  end
end

def can_bake_recipe(args, recipe)
  return false if args.state.flour_count < (recipe[:flour] || 0)
  return false if args.state.milk_count < (recipe[:milk] || 0)
  return false if args.state.chocolate_count < (recipe[:chocolate] || 0)
  return false if args.state.cherry_count < (recipe[:cherry] || 0)
  true
end

def consume_recipe_ingredients(args, recipe)
  args.state.flour_count -= recipe[:flour] || 0
  args.state.milk_count -= recipe[:milk] || 0
  args.state.chocolate_count -= recipe[:chocolate] || 0
  args.state.cherry_count -= recipe[:cherry] || 0
end

def show_items(args, item)
  args.state.baked[item[:type]] += 1
end

def check_delivery(args, baked_type)
  # Check if any order matches
  matching_order = args.state.orders.find { |order| order[:item] == baked_type }
  
  if matching_order && args.state.baked[baked_type] > 0
    # Complete the order
    args.state.orders.delete(matching_order)
    args.state.completed_orders << matching_order
    args.state.shop_money += matching_order[:revenue]
    
    # Remove the baked item
    args.state.baked_items.delete_if { |item| item[:type] == baked_type }
    args.state.baked[baked_type] -= 1

    # Delivery guy messages
    args.state.delivery_guy_message = "Someone ordered that!"
    args.state.delivery_guy_message_timer = 120
    
    # After a delay, show completion message
    add_shop_message(args, "Receipt ##{matching_order[:id]} Done! +$#{matching_order[:revenue]}")
    add_floating_money(args, matching_order[:revenue], 640, 400)
  elsif args.state.baked[baked_type] > 0
    # No matching order but we have the item
    args.state.delivery_guy_message = "Nobody ordered it so I'm going to eat it"
    args.state.delivery_guy_message_timer = 120
    
    # Remove the baked item
    args.state.baked_items.delete_if { |item| item[:type] == baked_type }
    args.state.baked[baked_type] -= 1
    
    add_shop_message(args, "Item was eaten by delivery guy!")
  else
    # No baked items to deliver
    args.state.delivery_guy_message = "I don't have anything to deliver!"
    args.state.delivery_guy_message_timer = 120
  end
end

# Shop management functions
def update_shop(args)
  # Update message timers
  args.state.shop_messages.each { |msg| msg[:timer] -= 1 if msg[:timer] }
  args.state.shop_messages.reject! { |msg| msg[:timer] && msg[:timer] <= 0 }

  # Update game time
  args.state.game_time += 0.08

  # Update floating money
  args.state.floating_money.each do |money|
    money[:y] += 2
    money[:alpha] -= 3
  end
  args.state.floating_money.reject! { |m| m[:alpha] <= 0 }
end

def add_shop_message(args, text)
  args.state.shop_messages ||= []
  args.state.shop_messages << { text: text, timer: 300 }
  args.state.shop_messages = args.state.shop_messages.last(3)
end

def add_floating_money(args, amount, x = 600, y = 300)
  args.state.floating_money ||= []
  args.state.floating_money << {
    amount: amount,
    x: x,
    y: y,
    alpha: 255
  }
end

def formatted_time(game_time)
  hours = (game_time / 60).to_i
  minutes = (game_time % 60).to_i
  am_pm = hours >= 12 ? "PM" : "AM"
  hours = hours % 12
  hours = 12 if hours == 0
  "#{hours}:#{minutes.to_s.rjust(2, '0')} #{am_pm}"
end

# UI rendering functions
def render_shop_ui(args)
  render_blocks(args)
  render_progress_bar(args)
  render_messages(args)
  render_floating_money(args)
end

def checkOrderTimers(args)
  args.state.orders.each do |order|
    waitTime = args.state.game_time - order[:time_placed]
    if waitTime >= 60 
      if !args.state.shop.onFire
        args.state.shop.onFire = true
        args.state.fireStarted = true
        add_shop_message(args, "A customer waited too long...")
        add_shop_message(args, "your store is on fire!")
      else
        add_shop_message(args, "Another order was cancelled!")
      end
      args.state.orders.delete(order)
      break
    end
  end
end

#rendering for money, time, and messages
def render_blocks(args)
	# messages
  args.outputs.primitives << {
    x: 0, y: 665,
    w: 140, h: 50,
    a: 130,
    r: 0, g: 0, b: 0,
		path: 'sprites/panel_brown.png',
    primitive_marker: :sprite
  }
  args.outputs.primitives << {
    x: 0, y: 670,
    w: 135, h: 50,
    r: 140, g: 58, b: 44, a: 250,
		path: 'sprites/panel_brown.png',
    primitive_marker: :sprite
  }
  args.outputs.primitives << {
    x: 1135, y: 665,
    w: 120, h: 50,
    a: 130,
    r: 0, g: 0, b: 0,
		path: 'sprites/panel_brown.png',
    primitive_marker: :sprite
  }
  args.outputs.primitives << {
    x: 1130, y: 670,
    w: 120, h: 50,
    r: 140, g: 58, b: 44, a: 250,
		path: 'sprites/panel_brown.png',
    primitive_marker: :sprite
  }
end

def render_fire(args)
  return unless args.state.shop.onFire

  fireTimeInGameTicks = (args.state.fireTimeElapsed || 0) * 0.08  # Convert frames to game time
  firePhase = if fireTimeInGameTicks < 20
                1
              elsif fireTimeInGameTicks < 40
                2
              else
                3
              end

  fireFrame = args.state.fireFrame || 0

  sprite_path = case firePhase
                when 1
                  fireFrame == 0 ? 'sprites/Fire1.png' : 'sprites/Fire2.png'
                when 2
                  fireFrame == 0 ? 'sprites/Fire1.1.png' : 'sprites/Fire1.2.png'
                when 3
                  fireFrame == 0 ? 'sprites/Fire2.1.png' : 'sprites/Fire2.2.png'
                end
  
  args.outputs.sprites << {
    x: 0,
    y: 0,
    w: 1280, h: 720,
    path: sprite_path
  }
end

def render_progress_bar(args)
  bar_height = 40
  time_box_x = 0
  time_box_width = 210
  time_box_y = 720 - bar_height

  args.outputs.primitives << {
    x: time_box_x + 10,
    y: time_box_y + 2,
    w: 24,
    h: 24,
    path: 'sprites/sun.png',
    primitive_marker: :sprite
  }
  args.outputs.labels << {
    x: time_box_x + 44,
    y: time_box_y + 24,
    text: formatted_time(args.state.game_time),
    size_px: 24,
    font: "fonts/manaspc.ttf",
    r: 255, g: 255, b: 200
  }
  money_box_x = 1140
  money_box_y = time_box_y
  args.outputs.primitives << {
    x: money_box_x + 10,
    y: money_box_y - 2,
    w: 32,
    h: 32,
    path: 'sprites/money.png',
    primitive_marker: :sprite
  }
  args.outputs.labels << {
    x: money_box_x + 44,
    y: money_box_y + 24,
    text: "$#{args.state.shop_money.round(2)}",
    size_px: 24,
    font: "fonts/manaspc.ttf",
    r: 255, g: 255, b: 200
  }
end

def render_floating_money(args)
  args.state.floating_money ||= []
  args.state.floating_money.each do |money|
    args.outputs.labels << {
      x: money[:x],
      y: money[:y],
      text: "+$#{money[:amount]}",
      size_px: 24,
      r: 0,
      g: 255,
      b: 0,
      a: money[:alpha]
    }
  end
end

def render_messages(args)
  if args.state.shop_messages && !args.state.shop_messages.empty?
    messages_x = 0
    messages_y = 600
    args.outputs.primitives << {
      x: messages_x,
      y: messages_y - 105,
      w: 400,
      h: 140,
      r: 140, g: 58, b: 44, a: 250,
      path: 'sprites/panel_brown.png',
      primitive_marker: :sprite
    }
    args.state.shop_messages.each_with_index do |msg, i|
      args.outputs.labels << {
        x: messages_x + 30,
        y: messages_y - i * 30,
        text: msg[:text],
        size_px: 20,
        r: 255, g: 255, b: 255
      }
    end
  end
end
  end
end
