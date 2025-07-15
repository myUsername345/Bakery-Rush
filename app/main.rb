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
  args.state.show_how_to_play ||= false
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

  if args.state.show_how_to_play
  args.outputs.sprites << {
    x: 0, y: 0, w: screen_w, h: screen_h,
    path: :pixel, r: 0, g: 0, b: 0, a: 220
  }

  args.outputs.labels << [
    { x: screen_w / 2, y: screen_h - 100, text: "How to Play", size: 48, alignment_enum: 1, r: 255, g: 255, b: 255 },
    { x: screen_w / 2, y: screen_h - 180, text: "- Click the Supply Box to get ingredients.", size: 28, alignment_enum: 1, r: 255, g: 255, b: 255 },
    { x: screen_w / 2, y: screen_h - 220, text: "- Click the Oven to combine ingredients", size: 28, alignment_enum: 1, r: 255, g: 255, b: 255 },
    { x: screen_w / 2, y: screen_h - 260, text: "- Click the Tablet for new orders", size: 28, alignment_enum: 1, r: 255, g: 255, b: 255 },
  ]

  # Back button
  back_btn_x = screen_w / 2 - 100
  back_btn_y = 100
  back_btn_w = 200
  back_btn_h = 50

  args.outputs.solids << {
    x: back_btn_x, y: back_btn_y, w: back_btn_w, h: back_btn_h,
    r: 200, g: 80, b: 80, a: 200
  }
  args.outputs.labels << {
    x: screen_w / 2, y: back_btn_y + 15,
    text: "Back", size: 28, alignment_enum: 1,
    r: 255, g: 255, b: 255
  }

  if args.inputs.mouse.click
    mx = args.inputs.mouse.x
    my = args.inputs.mouse.y

    if mx.between?(back_btn_x, back_btn_x + back_btn_w) &&
       my.between?(back_btn_y, back_btn_y + back_btn_h)
      args.state.show_how_to_play = false
      args.state.starting_screen = true
    end
  end

  return
end

  if args.state.starting_screen
  args.outputs.sprites << {
    x: 0, y: 0, w: screen_w, h: screen_h,
    path: :pixel, r: 50, g: 50, b: 50, a: 180
  }

  # Button dimensions
  btn_w = 200
  btn_h = 60

  play_btn_x = screen_w / 2 - btn_w / 2
  play_btn_y = screen_h / 2 + 20

  how_btn_x = screen_w / 2 - btn_w / 2
  how_btn_y = screen_h / 2 - 60

  # Draw PLAY button (with border)
  args.outputs.borders << {
    x: play_btn_x - 2, y: play_btn_y - 2, w: btn_w + 4, h: btn_h + 4,
    r: 255, g: 255, b: 255
  }
  args.outputs.solids << {
    x: play_btn_x, y: play_btn_y, w: btn_w, h: btn_h,
    r: 100, g: 200, b: 100, a: 220
  }
  args.outputs.labels << {
    x: screen_w / 2, y: play_btn_y + 40,
    text: "Play", size: 32, alignment_enum: 1,
    r: 255, g: 255, b: 255
  }

  # Draw HOW TO PLAY button (with border)
  args.outputs.borders << {
    x: how_btn_x - 2, y: how_btn_y - 2, w: btn_w + 4, h: btn_h + 4,
    r: 255, g: 255, b: 255
  }
  args.outputs.solids << {
    x: how_btn_x, y: how_btn_y, w: btn_w, h: btn_h,
    r: 80, g: 80, b: 200, a: 220
  }
  args.outputs.labels << {
    x: screen_w / 2, y: how_btn_y + 40,
    text: "How to Play", size: 28, alignment_enum: 1,
    r: 255, g: 255, b: 255
  }

  # Handle mouse clicks
  if args.inputs.mouse.click
    mx = args.inputs.mouse.x
    my = args.inputs.mouse.y

    if mx.between?(play_btn_x, play_btn_x + btn_w) &&
       my.between?(play_btn_y, play_btn_y + btn_h)
      args.state.starting_screen = false
      return
    end

    if mx.between?(how_btn_x, how_btn_x + btn_w) &&
       my.between?(how_btn_y, how_btn_y + btn_h)
      args.state.show_how_to_play = true
      return
    end
  end

  return
end

  # Oven
  oven_x = screen_w / 2 - 600
  oven_y = screen_h / 2 - 230
  oven_w = 221
  oven_h = 162
  args.outputs.sprites << {
    x: oven_x, y: oven_y,
    w: oven_w, h: oven_h, path: "sprites/Oven.png"
  }

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

  # Click logic
  if args.inputs.mouse.click
    mx = args.inputs.mouse.x
    my = args.inputs.mouse.y

    # Oven click triggers failure overlay
    if mx.between?(oven_x, oven_x + oven_w) &&
       my.between?(oven_y, oven_y + oven_h)
      args.state.oven_failure_overlay = true
      return
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
end
