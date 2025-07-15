def tick args
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
  args.state.flour_count ||= 0
  args.state.milk_count ||= 0
  args.state.cherry_count ||= 0
  args.state.chocolate_count ||= 0
  args.state.tablet_gui_open ||= false
  args.state.selected_receipt ||= nil
  args.state.employee_facing_right = true if args.state.employee_facing_right.nil?

  # New state flags for overlays
  args.state.oven_failure_overlay ||= false
  args.state.tablet_success_overlay ||= false

  args.state.recipes = [[:flour, :milk, :chocolate]]
  args.state.baked = {donut:3, bread:5, cupcake:4}

  # Oven failure overlay
  if args.state.oven_failure_overlay
    args.outputs.sprites << {
      x: 0, y: 0, w: screen_w, h: screen_h,
      path: :pixel, r: 50, g: 50, b: 50, a: 180
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2 + 40,
      text: "You did not meet customer requirements",
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

  # Tablet success overlay
  if args.state.tablet_success_overlay
    args.outputs.sprites << {
      x: 0, y: 0, w: screen_w, h: screen_h,
      path: :pixel, r: 50, g: 50, b: 50, a: 180
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2 + 60,
      text: "Congrats! You met customer requirements",
      size: 36, alignment_enum: 1,
      r: 255, g: 255, b: 255
    }
    args.outputs.labels << {
      x: screen_w / 2, y: screen_h / 2 + 10,
      text: "Orders Completed: 75",
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

  # Oven
  oven_x = screen_w / 2 - 600
  oven_y = screen_h / 2 - 230
  oven_w = 200
  oven_h = 200
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
  tablet_x = screen_w / 2 + 250
  tablet_y = screen_h / 2 - 230
  args.outputs.sprites << {
    x: tablet_x, y: tablet_y, w: tablet_w, h: tablet_h,
    path: "sprites/Tablet.png"
  }

  # Hotbar background
  hotbar_x = 20
  hotbar_y = 20
  args.outputs.solids << {
    x: hotbar_x, y: hotbar_y, w: 500, h: 70,
    r: 30, g: 30, b: 30, a: 220
  }

  # Ingredient display
  ingredients = [
    { icon: "Flour.png", count: args.state.flour_count, w: 50, h: 50 },
    { icon: "Milk.png", count: args.state.milk_count, w: 25, h: 60 },
    { icon: "Cherry.png", count: args.state.cherry_count, w: 32, h: 32 },
    { icon: "Chocolate.png", count: args.state.chocolate_count, w: 32, h: 32 }
  ]

  ingredients.each_with_index do |item, i|
    icon_x = hotbar_x + 10 + i * 110
    icon_y = hotbar_y + 10

    args.outputs.sprites << {
      x: icon_x, y: icon_y,
      w: item[:w], h: item[:h],
      path: "sprites/#{item[:icon]}"
    }

    args.outputs.labels << {
      x: icon_x + item[:w] + 6, y: icon_y + 10,
      text: "x #{item[:count]}", size: 24,
      r: 255, g: 255, b: 255
    }
  end

  # SupplyBox (adds ingredients)
  supply_box_w, supply_box_h = 150, 200
  supply_box_x, supply_box_y = screen_w - supply_box_w - 0, -30
  args.outputs.sprites << {
    x: supply_box_x, y: supply_box_y, w: supply_box_w, h: supply_box_h,
    path: "sprites/SupplyBox.png"
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

  oven_popup_offset_x = 128
  oven_popup_offset_y = 256  

  # Click logic
  if args.inputs.mouse.click
    mx = args.inputs.mouse.x
    my = args.inputs.mouse.y

    if args.state.ovenpopupenabled && mx.between?(args.state.cupcakebutton.x + oven_popup_offset_x , args.state.cupcakebutton.x + args.state.cupcakebutton.w + oven_popup_offset_x)
      # Logic for baking cupcakes
    elsif args.state.ovenpopupenabled && mx.between?(args.state.donutbutton.x + oven_popup_offset_x, args.state.donutbutton.x + args.state.donutbutton.w + oven_popup_offset_x)
      # Logic for baking cupcakes
      # 
    elsif args.state.ovenpopupenabled && mx.between?(args.state.breadbutton.x + oven_popup_offset_x, args.state.breadbutton.x + args.state.breadbutton.w + oven_popup_offset_x)

    elsif
    # Oven click triggers failure overlay
     mx.between?(oven_x, oven_x + oven_w) &&
       my.between?(oven_y, oven_y + oven_h)
      args.state.ovenpopupenabled = !args.state.ovenpopupenabled
    end


    # Tablet click triggers success overlay
    if mx.between?(tablet_x, tablet_x + tablet_w) &&
       my.between?(tablet_y, tablet_y + tablet_h)
      args.state.tablet_success_overlay = true
      return
    end

    # SupplyBox click
    if mx.between?(supply_box_x, supply_box_x + supply_box_w) &&
       my.between?(supply_box_y, supply_box_y + supply_box_h)
      case rand(4)
      when 0 then args.state.flour_count += 1
      when 1 then args.state.milk_count += 1
      when 2 then args.state.cherry_count += 1
      when 3 then args.state.chocolate_count += 1
      end
    end

    # Employee flip
    if mx.between?(employee_x, employee_x + employee_w) &&
       my.between?(employee_y, employee_y + employee_h)
      args.state.employee_facing_right = !args.state.employee_facing_right
    end
  end

  # Tablet GUI rendering can go here (if needed)

  # Show selected receipt
  if args.state.selected_receipt
    args.outputs.labels << {
      x: screen_w - 20, y: 130,
      text: "Selected Receipt ##{args.state.selected_receipt}",
      size: 28, alignment_enum: 2,
      r: 255, g: 255, b: 255
    }
  end

  # Show Oven popup
  if args.state.ovenpopupenabled 
    args.outputs.sprites << {
      x: oven_popup_offset_x,
      y: oven_popup_offset_y,
      w: args.outputs[:oven_popup].w,
      h: args.outputs[:oven_popup].h,
      path: :oven_popup,
    } 
  end
end
