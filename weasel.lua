--**********************************************************
--* Weasel Game Engine for LÖVE                            *
--*                                           Version 0.01 *
--*                                                        *
--* Copyright (C) 2022 michyo (Michiyo Tagami)             *
--* Released under the MIT license                         *
--* https://opensource.org/licenses/mit-license.php        *
--**********************************************************

--* Game ***************************************************
--**********************************************************
function initGame(title,icon)
  love.window.setTitle(title)
  local icong = love.image.newImageData(icon)
  love.window.setIcon(icong)
  local game = {}
  game.sound = {}
  game.sound.BGM = nil
  game.setBGM = function(game,path)
    if game.sound.BGM ~= nil then
      love.audio.stop(game.sound.BGM)
    end
    game.sound.BGM = love.audio.newSource(path, "stream")
    game.sound.BGM:setLooping(true)
    game.sound.BGM:play()
  end
  return game
end

--* Animation **********************************************
--**********************************************************
function newAnimation(imgpath, width, height, duration)
    local image = love.graphics.newImage(imgpath)
    local animation = {}
    animation.spriteSheet = image;
    animation.quads = {};
    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end
    animation.duration = duration or 1
    animation.currentTime = 0
    return animation
end

function getFrameNo(sprite)
  local spriteNum = math.floor(sprite.currentTime / sprite.duration * #(sprite.quads)) + 1
  spriteNum = math.min(spriteNum, #(sprite.quads))
  return  spriteNum
end

function updateFrame(sprite, dt)
  sprite.currentTime = sprite.currentTime + dt
  if sprite.currentTime >= sprite.duration then
      sprite.currentTime = sprite.currentTime - sprite.duration
  end
end

--* Interval ***********************************************
--**********************************************************
function initInterval(dt)
  local keyInput = {}
  keyInput.interval = dt
  keyInput.currentTime = 0
  keyInput.checkInterval = function(keyInput, dt)
    local doitnow = false
    keyInput.currentTime = keyInput.currentTime + dt
    if (keyInput.currentTime >= keyInput.interval) then
      doitnow = true
      keyInput.currentTime = keyInput.currentTime - keyInput.interval
    end
    return doitnow
  end
  return keyInput
end

function clamp(param, min, max)
  local ret = param
  ret = math.min(ret,max)
  ret = math.max(ret,min)
  return ret
end

--* Map ****************************************************
--**********************************************************
function createMap()
  local map = {}
  map.map = {}
  map.chip = {}
  map.background = 0
  map.obstacles = {1}
  map.goal = {}
  map.goal.X = -1
  map.goal.Y = -1
  math.randomseed(os.time())
  map.drawMap = function(map)
    for tmpX=0,19 do
      for tmpY=0,14 do
        love.graphics.draw(map.chip[map.map[tmpX][tmpY]], tmpX*40, tmpY*40)
      end
    end
  end
  map.registerChip = function(map,cno,chipPath)
    map.chip[cno] = love.graphics.newImage(chipPath)
  end
  map.createRandom = function(map)
    for tmpX=0,19 do
      for tmpY=0,13 do
        map.map[tmpX][tmpY] = map.background
      end
      map.map[tmpX][14] = map.obstacles[1]
    end
    for tmpX=0,19 do
      for tmpY=0,13,2 do
        local tmpI = math.random(0,5)
        if tmpI<=1 then
          map.map[tmpX][tmpY] = map.obstacles[1]
        end
      end
    end
  end
  map.setGoal = function(map, x, y, chip)
    map.goal.X = x
    map.goal.Y = y
    map.map[x][y] = chip
  end
  map.checkGoal = function(map, player)
    local goaled = false
    if ((map.goal.X == player.X) and (map.goal.Y == player.Y)) then
      goaled = true
    end
    return goaled
  end
  for tmpX=0,19 do
    map.map[tmpX] = {}
    for tmpY=0,14 do
      map.map[tmpX][tmpY] = map.background
    end
  end
  return map
end

--* Player *************************************************
--**********************************************************
function createPlayer(initX, initY, filePath)
  local player = {}
  player.Animation = newAnimation(filePath, 40, 40, 0.5)
  player.X = initX
  player.Y = initY
  player.Jumping = 0
  player.sound = {}
  player.sound.jump = nil
  player.sound.move = nil
  player.setSound = function(player,type,path)
    if type=="JUMP" then
      player.sound.jump = love.audio.newSource(path, "stream")
    end
    if type=="MOVE" then
      player.sound.move = love.audio.newSource(path, "stream")
    end
  end
  player.draw = function(player)
    local spriteNum = getFrameNo(player.Animation)
    love.graphics.draw(player.Animation.spriteSheet, player.Animation.quads[spriteNum], player.X*40, player.Y*40, 0, 1)
  end
  player.move = function(player, map)
    local myX = player.X
    local myY = player.Y
    local bkX = myX
    if love.keyboard.isDown('right') then
      myX = myX + 1
      if player.sound.move~=nil then
        player.sound.move:play()
      end
    end
    if love.keyboard.isDown('left') then
      myX = myX - 1
      if player.sound.move~=nil then
        player.sound.move:play()
      end
    end
    myX = clamp(myX, 0, 19)
    if map.map[myX][myY] == 1 then
      myX = bkX
    end
    if love.keyboard.isDown('space') then
      if (player.Jumping == 0) then
        player.Jumping = 1
        if player.sound.jump~=nil then
          player.sound.jump:play()
        end
      end
    end
    if player.Jumping==1 then
      myY = myY - 1
      player.Jumping = 2
    elseif player.Jumping==2 then
      myY = myY - 1
      player.Jumping = 3
    elseif player.Jumping==3 then
      if map.map[myX][myY+1] == 1 then
        player.Jumping = 0
      else
        myY = myY + 1
      end
    end
    if ((map.map[myX][myY+1] ~= 1) and (player.Jumping==0))then
      Jumping = 3
      myY = myY + 1
    end
    player.X = myX
    player.Y = myY
  end
  player.moveTo = function(player,x,y)
    player.X = x
    player.Y = y
  end
  return player
end
