function love.load()
    bg = love.graphics.newImage("images/space.jpg")
    zim_font = love.graphics.newImageFont("images/zim_font.png", " abc")
    shuvver = love.graphics.newImage("images/shuvver.png")
    dib = love.graphics.newImage("images/dib.png")
    earth = love.graphics.newImage("images/earth.png")

    hero = {}
    hero.x          = 300
    hero.y          = 450
    hero.width      = 34
    hero.height     = 38
    hero.speed      = 150
    hero.y_velocity = 0

    hero.shots = {}

    enemy_speed = .025
    enemy_count = 7

    spawn_enemies(150, enemy_count)
    respawn = false
    spawn_delay_time = 1

    gravity = 400
    jump_height = 300
    time_difference = 0

    level = 0

    -- change in horizontal and vertical for the ships
    dt_x_max = 200
    dt_y_max = 50

    dt_x = dt_x_max
    dt_y = dt_y_max

    game_over = false
end

function spawn_enemies(altitude, num_enemies)
    enemies = {}

    max_columns = 7
    column_spacing = 60
    row_spacing = 20

    for i=0,num_enemies-1 do
        enemy = {}
        enemy.width = 32
        enemy.height = 50

        column_offset =  (i % max_columns) * 80
        row_offset = math.floor(i / max_columns) * 60

        enemy.x = enemy.width + 120 + column_offset
        enemy.y = enemy.height + altitude - row_offset

        table.insert(enemies, enemy)
    end
end

function love.keypressed(key)
    -- Allow the hero to jump when spacebar is pressed
    if (key == 'j') then
        if hero.y_velocity == 0 then -- on the ground
            hero.y_velocity = jump_height
        end
    end
end

function love.keyreleased(key)
    if (key == ' ') then
        shoot()
    end
end

function love.update(dt)
    -- Allow 2D movement
    if love.keyboard.isDown("left") then
        hero.x = hero.x - temp_speed
    elseif love.keyboard.isDown("right") then
        hero.x = hero.x + temp_speed
    elseif love.keyboard.isDown("up") then
        hero.y = hero.y - temp_speed
    elseif love.keyboard.isDown("down") then
        hero.y = hero.y + temp_speed
    end

    local remEnemy = {}
    local remShot = {}

    -- update those shots
    for i,v in ipairs(hero.shots) do
        v.y = v.y - dt * 200

        -- mark shots that are not visible for removal
        if v.y < 0 then
            table.insert(remShot, i)
        end

        -- check for collision with enemies
        for ii,vv in ipairs(enemies) do
            if CheckCollision(v.x, v.y, 2, 5, vv.x, vv.y, vv.width, vv.height) then
            -- mark that enemy for removal
            table.insert(remEnemy, ii)
            -- mark the shot for removal
            table.insert(remShot, i)
            end
        end
    end

    temp_speed = hero.speed*dt

    -- Speed up when shift is held
    if love.keyboard.isDown("lshift") then
        temp_speed = hero.speed*dt * 2
    end


    -- Handle horizontal screen bounds
    if hero.x > 800 - hero.width then
        hero.x = 800 - hero.width
    elseif hero.x < 0 then
        hero.x = 0
    end

    -- Handle vertical screen bounds
    if hero.y > 600 - hero.height then
        hero.y = 600 - hero.height
    elseif hero.y < 0 then
        hero.y = 0
    end

    -- Handle jumping
    if hero.y_velocity ~= 0 then -- we're probably jumping
        hero.y = hero.y - hero.y_velocity * dt
        hero.y_velocity = hero.y_velocity - gravity * dt
        if hero.y > 475 - hero.height then -- we hit the ground again
            hero.y_velocity = 0
            hero.y = 475 - hero.height
        end
    end

    -- make left and right shifts a function of time
    time_difference = time_difference + dt
    if time_difference > 6 then
        time_difference = 0
        if move_right then
            move_right = false
        else
            move_right = true
        end
    end

    -- let the space invaders descend
    for i,v in ipairs(enemies) do
        -- move down
        if dt_y > 0 then
            dt_y = dt_y - dt

            v.y = v.y + enemy_speed + dt

        -- move to the side
        elseif dt_x > 0 then
            dt_x = dt_x - dt

            -- move right or left accordingly
            if move_right then
                v.x = v.x + enemy_speed + dt * 2
            else
                v.x = v.x - enemy_speed - dt * 2
            end
        else
            -- reset the time/shifts by dimension
            dt_x = dt_x_max
            dt_y = dt_y_max
        end

        -- collision check with the ground
        if v.y > 485 - enemy.height then
            game_over = true
            for ii,vv in ipairs(enemies) do
                table.insert(remEnemy, ii)
            end
        end

        -- collision check with the hero
        if CheckCollision(hero.x, hero.y, hero.width, hero.height, v.x, v.y, v.width, v.height) then
            for ii,vv in ipairs(enemies) do
                table.insert(remEnemy, ii)
            end
            game_over = true
        end
    end

    if next(enemies) == nil and game_over ~= true then
        respawn = true
        for i,v in ipairs(hero.shots) do
            table.insert(remShot, i)
        end
    end

    if respawn == true then
        spawn_delay_time = spawn_delay_time - dt

        if spawn_delay_time < 0 then
            respawn = false

            new_level()
        end
    end

    -- remove the marked enemies
    for i,v in ipairs(remEnemy) do
        table.remove(enemies, v)
    end

    for i,v in ipairs(remShot) do
        table.remove(hero.shots, v)
    end
end

function new_level()
    enemy_speed = enemy_speed + .02
    enemy_count = enemy_count + 7
    spawn_enemies(150, enemy_count)
    spawn_delay_time = .5

    level = level + 1
end


function love.draw()
    -- let's draw a background
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(bg)

    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(earth, 400, 500)

    -- let's draw our hero
    -- Debug: bounding box for hero
    -- love.graphics.rectangle("fill", hero.x,hero.y, hero.width, hero.height)
    love.graphics.draw(dib, hero.x, hero.y)

    love.graphics.setColor(255,255,255,255)
    for i,v in ipairs(hero.shots) do
        love.graphics.rectangle("fill", v.x, v.y, 2, 5)
    end

    -- draw some space invaders
    love.graphics.setColor(255,255,255,255)
    for i,v in ipairs(enemies) do
        -- Debug: draw bounding boxes
        -- love.graphics.rectangle("fill", v.x, v.y, v.width, v.height)
        love.graphics.draw(shuvver, v.x, v.y)
    end

    -- Experimenting with Irken fonts
    --love.graphics.setFont(zim_font)
    --love.graphics.print("a b c abc", 380, 200)

    if game_over == true then
        love.graphics.setColor(255,0,0,255)
        love.graphics.print("Game Over", 270, 200, 0,4)
    end

    -- Draw the game over line
    love.graphics.setColor(255,0,0,100)
    love.graphics.print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ", 0, 470, 0,2)

    love.graphics.setColor(255,255,255,255)
    level_str = "Level: " .. level
    love.graphics.print(level_str, 20, 20, 0)
end

function shoot()
    local shot = {}
    shot.x = hero.x + hero.width/2
    shot.y = hero.y

    table.insert(hero.shots, shot)
end

-- Collision detection function.
-- Checks if a and b overlap.
-- w and h mean width and height.
function CheckCollision(ax1, ay1, aw, ah, bx1, by1, bw, bh)
    local ax2, ay2, bx2, by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh

    return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end
