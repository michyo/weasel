--**********************************************************
--* Weasel Game Engine for LÖVE                            *
--*                                           Version 0.03 *
--*                                                        *
--* Copyright (C) 2022 michyo (Michiyo Tagami)             *
--* Released under the MIT license                         *
--* https://opensource.org/licenses/mit-license.php        *
--**********************************************************

local utf8 = require("utf8")

local function clamp(param, min, max)
  local ret = param
  ret = math.min(ret,max)
  ret = math.max(ret,min)
  return ret
end

local function checkClone(origin,clone,otype)
  if (otype~='table') then
    return (origin==clone)
  else
    for key,oriVal in pairs(origin) do
      local cloVal = clone[key]
      if cloVal == nil then
        return false
      else
        return checkClone(oriVal,cloVal,type(oriVal))
      end
    end
  end
  return true
end

local function cloneTable(origin)
  local oriType = type(origin)
  local clone
  if oriType == 'table' then
    clone = {}
    for oriKey, oriVal in pairs(origin) do
      clone[cloneTable(oriKey)] = cloneTable(oriVal)
    end
  else
    clone = origin
  end
  repeat until (checkClone(origin,clone,oriType))
  return clone
end

--* Game ***************************************************
--**********************************************************
function createGame(title, icon)
  local game = {}
  game.State = nil
  game.Stages = {}
  game.Name = title
  game.Icon = icon
  game.goNext = nil
  game.firstStage = nil
  game.gameOverStage = nil
  game.retryMode = false
  game.Sound = {}
  game.enemyMove = getBuiltInEnemyMove()
  game.setBGM = function(game,path)
    if game.Sound.BGM ~= nil then
      love.audio.stop(game.Sound.BGM)
    end
    game.Sound.BGM = love.audio.newSource(path, "stream")
    game.Sound.BGM:setLooping(true)
    game.Sound.BGM:play()
  end
  game.setSound = function(game,type,path)
    if type=="DEATH" then
      if game.Sound.Death ~= nil then
        love.audio.stop(game.Sound.Death)
      end
      game.Sound.Death = love.audio.newSource(path, "stream")
    end
  end
  game.Init = function(game,startStage)
    local tmpS
    game.State = startStage
    repeat
      tmpS = game.Stages[game.State]
      if (game.Stages[game.State]~=nil) then
        if (game.Stages[game.State].Init ~= nil) then
          game.Stages[game.State]:Init()
        end
        game.firstStage = game.State
      else
        game.State = game.State + 1
      end
    until ((tmpS~=nil) or (game.State>table.maxn(game.Stages)))
  end
  game.addStage = function(game,stageNo,stageObj)
    game.Stages[stageNo] = stageObj
  end
  game.Update = function(game,dt)
    if (game.Stages[game.State]~=nil) then
      if (game.Stages[game.State].Completed) then
        if game.Stages[game.State].waitTime then
          if (love.keyboard.isDown('space')~=true) then
            game.Stages[game.State].waitTime = false
          end
        else
          if (game.goNext~=nil) then
            if (game.goNext==-1) then
              game.goNext = game.State+1
            end
            game.State = game.goNext
            if (game.Stages[game.State]~=nil) then
              love.timer.sleep(0.1)
              game.Stages[game.State]:Init()
            else
              if game.firstStage~=nil then
                game.State = game.firstStage
                love.timer.sleep(0.1)
                game.Stages[game.firstStage]:Init()
              end
            end
            game.goNext = nil
          end
        end
      else
        if (game.Stages[game.State].Update~=nil) then
          game.goNext = game.Stages[game.State]:Update(game, dt)
        end
      end
    end
  end
  game.Draw = function(game)
    if (game.Stages[game.State]~=nil) then
      if (game.Stages[game.State].Draw~=nil) then
        game.Stages[game.State]:Draw()
      end
    end
  end
  love.window.setTitle(title)
  local icong = love.image.newImageData(icon)
  love.window.setIcon(icong)
  keyInput = initInterval(0.1)
  return game
end

--* Stage **************************************************
--**********************************************************
function createStage(type, next)
  if (next==nil) then
    print("Weasel: Warning! Next stage is nil.")
  end
  local stage = {}
  stage.Type = type
  stage.Map = nil
  stage.Player = nil
  stage.UpdateFunc = nil
  stage.DrawFunc = nil
  stage.Next = next
  stage.Completed = false
  stage.Start = {X=-1,Y=-1}
  stage.waitTime = false
  stage.Enemies = {}
  stage.posTopLeft = {X=0,Y=0}
  stage.Init = function(stage)
    stage.Completed = false
    if (stage.Player~=nil) then
      stage.Player:moveTo(stage.Start.X,stage.Start.Y)
      stage.Player.Direction = 3
    end
    for j=0,#stage.Enemies do
      if (stage.Enemies[j]~=nil) then
        stage.Enemies[j]:moveTo(stage.Enemies[j].posStart.X,stage.Enemies[j].posStart.Y)
      end
    end
    stage.waitTime = true
  end
  stage.setStart = function(stagem,x,y)
    stage.Start.X = x
    stage.Start.Y = y
  end
  stage.Update = function(stage, game, dt)
    local result = nil
    if (stage.Type==0) then
      if (stage.Player~=nil) then
        stage.Player.Animation:updateFrame(dt)
        for j=0,#stage.Enemies do
          if (stage.Enemies[j]~=nil) then
            stage.Enemies[j].Animation:updateFrame(dt)
          end
        end
        if (keyInput:checkInterval(dt)) then
          for j=0,#stage.Enemies do
            if (stage.Enemies[j]~=nil) then
              if (stage.Enemies[j].Move~=nil) then
                stage.Enemies[j]:Move(stage)
              end
            end
          end
          stage.Player:Move(stage)
          stage:calcTopLeft()
        end
      end
      for i=1,#stage.Map.Goals do
        if (stage.Player~=nil) then
          if ((stage.Map.Goals[i].X == stage.Player.X)
            and (stage.Map.Goals[i].Y == stage.Player.Y)) then
            result = stage.Map.Goals[i].Next
          end
        end
      end
      if (stage.Enemies~=nil) then
        for j=0,#stage.Enemies do
          if (stage.Enemies[j]~=nil) then
            if (stage.Player~=nil) then
              if ((stage.Enemies[j].X==stage.Player.X)and(stage.Enemies[j].Y==stage.Player.Y)) then
                if game.retryMode then
                  result = game.State
                else
                  result = game.gameOverStage
                end
                if game.Sound.Death~=nil then
                  game.Sound.Death:play()
                end
              end
            end
          end
        end
      end
      if (result~=nil) then
        stage.Completed = true
        if (result==-1) then
          result = stage.Next
        end
      end
    elseif (stage.Type==1) then
      stage:UpdateFunc()
      if stage.Completed then
        result = stage.Next
      end
    else

    end
    return result
  end
  stage.Draw = function(stage)
    if (stage.Type==0) then
      if (stage.Map~=nil) then
        stage.Map:Draw(stage)
      end
      if (stage.Enemies~=nil) then
        for j=0,#stage.Enemies do
          if (stage.Enemies[j]~=nil) then
            stage.Enemies[j]:Draw(stage)
          end
        end
      end
      if (stage.Player~=nil) then
        stage.Player:Draw(stage)
      end
    elseif (stage.Type==1) then
      stage:DrawFunc()
    else

    end
  end
  stage.preparePictureStage = function(stage,picture)
    stage.Type = 1
    stage.Picture = love.graphics.newImage(picture)
    stage.UpdateFunc = function(stage)
      if love.keyboard.isDown('space') then
        stage.Completed = true
      end
    end
    stage.DrawFunc = function(stage)
      local x = stage.Picture:getWidth()
      local y = stage.Picture:getHeight()
      love.graphics.draw(stage.Picture, (800-x)/2, (600-y)/2)
    end
  end
  stage.calcTopLeft = function(stage)
    local ox,oy = 0,0
    if (stage.Player.X <= 9) then
      ox = 0
    elseif (stage.Player.X >= stage.Map.Width-10) then
      ox = stage.Map.Width-20
    else
      ox = stage.Player.X - 9
    end
    if (stage.Player.Y <= 7) then
      oy = 0
    elseif (stage.Player.Y >= stage.Map.Height-7) then
      oy = stage.Map.Height-15
    else
      oy = stage.Player.Y - 7
    end
    if (stage.Map.Width < 20) then
      ox = 0
    end
    if (stage.Map.Height < 15) then
      oy = stage.Map.Height-15
    end
    stage.posTopLeft.X = ox
    stage.posTopLeft.Y = oy
  end
  stage.addEnemy = function(stage,enemyNo,enemy,x,y)
    stage.Enemies[enemyNo] = cloneTable(enemy)
    stage.Enemies[enemyNo].X = x
    stage.Enemies[enemyNo].Y = y
    stage.Enemies[enemyNo].posStart = {}
    stage.Enemies[enemyNo].posStart.X = x
    stage.Enemies[enemyNo].posStart.Y = y
  end
  return stage
end

--* Map ****************************************************
--**********************************************************
function createMap()
  local map = {}
  map.Map = {}
  map.Chip = {}
  map.Width = 0
  map.Height = 0
  map.Obstacles = {}
  map.Goals = {}
  map.GoalChips = {}
  map.Load = function(map,path)
    local width = 0
    local i = 0
    for line in love.filesystem.lines(path) do
      local tmpI = utf8.len(line)
      if (tmpI>width) then
        width = tmpI
      end
      if tmpI > 0 then
        i = i + 1
      end
    end
    map.Width = width
    map.Height = i
    map.Map = {}
    for tmpX=0,50 do
      map.Map[tmpX] = {}
      for tmpY=0,50 do
        map.Map[tmpX][tmpY] = nil
      end
    end
    for tmpX=0,map.Width-1 do
      map.Map[tmpX] = {}
      for tmpY=0,map.Height-1 do
        map.Map[tmpX][tmpY] = 0
      end
    end
    i = 0
    for line in love.filesystem.lines(path) do
      for pos, code in utf8.codes(line) do
        local tmpC = utf8.char(code)
        local tmpI = string.byte(tmpC)
        if ((48<=tmpI) and (tmpI<=57)) then
          tmpI = tmpI - 48
        elseif ((65<=tmpI) and (tmpI<=90)) then
          tmpI = tmpI - 55
        elseif ((97<=tmpI) and (tmpI<=122)) then
          tmpI = tmpI - 61
        end
        map.Map[pos-1][i] = tmpI
        for j=1,#map.GoalChips do
          if (tmpI==map.GoalChips[j]) then
            map:addGoal(pos-1,i,tmpI,-1)
          end
        end
      end
      i = i + 1
    end
  end
  map.Draw = function(map,stage)
    local ox,oy = stage.posTopLeft.X,stage.posTopLeft.Y
    for tmpX=ox,ox+19 do
      for tmpY=oy,oy+14 do
        if (map.Map[tmpX][tmpY]~=nil) then
          if (map.Chip[map.Map[tmpX][tmpY]]~=nil) then
            love.graphics.draw(map.Chip[map.Map[tmpX][tmpY]], (tmpX-ox)*40, (tmpY-oy)*40)
          end
        end
      end
    end
  end
  map.registerChip = function(map,cno,chip)
    map.Chip[cno] = chip
  end
  map.createRandom = function(map,width,height)
    map.Width = width
    map.Height = height
    math.randomseed(os.time())
    for tmpX=0,width-1 do
      map.Map[tmpX] = {}
      for tmpY=0,height-1 do
        map.Map[tmpX][tmpY] = 0
      end
      map.Map[tmpX][height-1] = map.Obstacles[1]
    end
    for tmpX=0,width-1 do
      for tmpY=height-1,0,-2 do
        local tmpI = math.random(0,5)
        if tmpI<=1 then
          map.Map[tmpX][tmpY] = map.Obstacles[1]
        end
      end
    end
    for tmpI=0,math.floor(width*height/20) do
      map.Map[math.random(0,width-1)][math.random(0,height-1)] = map.Obstacles[1]
    end
    for tmpI=0,map.Width-1 do
      map.Map[tmpI][map.Height-1] = 1
    end
    map:addGoal(math.random(0,map.Width-1),math.random(0,map.Height-5),map.GoalChips[1],-1)
  end
  map.addGoal = function(map, x, y, chip, next)
    local goal = {}
    goal.X = x; goal.Y = y; goal.Next = next
    table.insert(map.Goals,goal)
    map.Map[x][y] = chip
  end
  map.Init = function(width,height)
    for tmpX=0,width-1 do
      map.Map[tmpX] = {}
      for tmpY=0,height-1 do
        map.Map[tmpX][tmpY] = map.Background
      end
    end
  end
  return map
end

--* Animation **********************************************
--**********************************************************
function createAnimation(imgpath, width, height, duration)
  local animation = {}
  local image = love.graphics.newImage(imgpath)
  animation.spriteSheet = image;
  animation.quads = {};
  for y = 0, image:getHeight() - height, height do
    for x = 0, image:getWidth() - width, width do
      table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
    end
  end
  animation.duration = duration or 1
  animation.currentTime = 0
  animation.getFrameNo = function(sprite)
    local spriteNum = math.floor(sprite.currentTime / sprite.duration * #(sprite.quads)/4) + 1
    spriteNum = math.min(spriteNum, #(sprite.quads)/4)
    return  spriteNum
  end
  animation.updateFrame = function(sprite, dt)
    sprite.currentTime = sprite.currentTime + dt
    if sprite.currentTime >= sprite.duration then
      sprite.currentTime = sprite.currentTime - sprite.duration
    end
  end
  return animation
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

--* Player *************************************************
--**********************************************************
function createPlayer(filePath)
  local player = {}
  --player.Animation = createAnimation(filePath, 40, 40, 0.5)
  player.Animation = createAnimation(filePath, 40, 40, 0.1)
  player.X = 0
  player.Y = 0
  player.Jumping = 0
  player.JumpPower = 4
  player.sound = {}
  player.sound.jump = nil
  player.sound.move = nil
  player.Direction = 3
  player.oldPosition = {X=0,Y=0}
  player.setSound = function(player,type,path)
    if type=="JUMP" then
      player.sound.jump = love.audio.newSource(path, "stream")
    end
    if type=="MOVE" then
      player.sound.move = love.audio.newSource(path, "stream")
    end
  end
  player.Draw = function(player,stage)
    local ox,oy = stage.posTopLeft.X,stage.posTopLeft.Y
    local spriteNum = player.Animation:getFrameNo()
    if ((player.oldPosition.X~=player.X)or(player.oldPosition.Y~=player.Y)) then
      love.graphics.draw(player.Animation.spriteSheet,
        player.Animation.quads[spriteNum+player.Direction*4],
        (player.X-ox)*40, (player.Y-oy)*40, 0, 1)
      player.oldPosition.X=player.X
      player.oldPosition.Y=player.Y
    else
      love.graphics.draw(player.Animation.spriteSheet,
        player.Animation.quads[player.Direction*4+2],
        (player.X-ox)*40, (player.Y-oy)*40, 0, 1)
    end
  end
  player.Move = function(player, stage)
    map = stage.Map
    local myX = player.X
    local myY = player.Y
    local bkX,bkY = myX,myY
    if love.keyboard.isDown('up') then
      player.Direction = 0
    end
    if love.keyboard.isDown('left') then
      myX = myX - 1
      player.Direction = 1
    end
    if love.keyboard.isDown('down') then
      player.Direction = 2
    end
    if love.keyboard.isDown('right') then
      myX = myX + 1
      player.Direction = 3
    end
    myX = clamp(myX, 0, map.Width-1)
    if love.keyboard.isDown('space') then
      if (player.Jumping == 0) then
        player.Jumping = 1
        if player.sound.jump~=nil then
          player.sound.jump:play()
        end
      end
    end
    if ((player.Jumping>=1) and (player.Jumping<player.JumpPower)) then
      myY = myY - 1
      player.Jumping = player.Jumping + 1
      --myY = myY - player.JumpPower + 1
      --player.Jumping = player.JumpPower
    elseif player.Jumping==player.JumpPower then
      if map.Map[myX][myY+1] == 1 then
        player.Jumping = 0
      else
        myY = myY + 1
      end
    end
    if ((map.Map[myX][myY] == 1) and (player.Jumping==0)) then
      myX = bkX
    end
    if ((map.Map[myX][myY+1] ~= 1) and (player.Jumping==0))then
      Jumping = 3
      myY = myY + 1
    end
    if ((myX~=bkX)or(myY~=bkY)) then
      if player.sound.move~=nil then
        player.sound.move:play()
      end
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

--* MapChip ************************************************
--**********************************************************
createMapChip = function()
  local mapchip = {}
  mapchip.addMapChip = function(mapchip,name,imagePath)
    mapchip[name] = love.graphics.newImage(imagePath)
  end
  return mapchip
end

--* Enemy **************************************************
--**********************************************************
createEnemy = function(filePath)
  local enemy = {}
  enemy.Animation = createAnimation(filePath, 40, 40, 0.1)
  enemy.X = 0
  enemy.Y = 0
  enemy.Jumping = 0
  enemy.Direction = 3
  enemy.Draw = function(enemy,stage)
    local ox,oy = stage.posTopLeft.X,stage.posTopLeft.Y
    if ((ox<=enemy.X)and(enemy.X<=ox+19)
      and(oy<=enemy.Y)and(enemy.Y<=oy+14)) then
      local spriteNum = enemy.Animation:getFrameNo()
      love.graphics.draw(enemy.Animation.spriteSheet,
        enemy.Animation.quads[spriteNum+enemy.Direction*4],
        (enemy.X-ox)*40, (enemy.Y-oy)*40, 0, 1)
    end
  end
  enemy.Move = function(enemy, stage)
    if (enemy.X>stage.Player.X) then
      enemy.Direction = 1
    elseif (enemy.X<stage.Player.X) then
      enemy.Direction = 3
    else
      if (enemy.Y<stage.Player.Y) then
        enemy.Direction = 2
      else
        enemy.Direction = 0
      end
    end
  end
  enemy.moveTo = function(enemy,x,y)
    enemy.X = x
    enemy.Y = y
  end
  return enemy
end


getBuiltInEnemyMove = function()
  local enemyMove = {}

  enemyMove[0] = function(enemy, stage)
    local map = stage.Map
    local myX = enemy.X
    local myY = enemy.Y
    local bkX,bkY = myX,myY
    if (math.random(1,3)==1) then
      if (enemy.X>stage.Player.X) then
        enemy.Direction = 1
        if (math.random(1,5)==1) then
          enemy.Direction = 3
        end
      elseif (enemy.X<stage.Player.X) then
        enemy.Direction = 3
        if (math.random(1,5)==1) then
          enemy.Direction = 1
        end
      else
        if (enemy.Y<stage.Player.Y) then
          enemy.Direction = 2
        else
          enemy.Direction = 0
        end
        if (math.random(1,5)==1) then
          if math.random(1,2)==2 then
            enemy.Direction = 3
          else
            enemy.Direction = 1
          end
        end
      end
      if (enemy.Jumping == 0) then
        if (stage.Player.Y<enemy.Y) then
          enemy.Jumping = 1
          --if enemy.sound.jump~=nil then
            --enemy.sound.jump:play()
          --end
        end
        if (math.random(1,5) == 1) then
          enemy.Jumping = 1
        end
      end
    end
    if (math.random(1,3)==1) then
      if (enemy.Direction == 1) then
        myX = myX - 1
      elseif (enemy.Direction == 3) then
        myX = myX + 1
      end
      myX = clamp(myX, 0, map.Width-1)
      if ((map.Map[myX][myY] == 1) and (enemy.Jumping==0)) then
        myX = bkX
      end
    end
    if enemy.Jumping==1 then
      myY = myY - 1
      enemy.Jumping = 2
    elseif enemy.Jumping==2 then
      myY = myY - 1
      enemy.Jumping = 3
    elseif enemy.Jumping==3 then
      if map.Map[myX][myY+1] == 1 then
        enemy.Jumping = 0
      else
        myY = myY + 1
      end
    end
    if ((map.Map[myX][myY+1] ~= 1) and (enemy.Jumping==0))then
      Jumping = 3
      myY = myY + 1
    end
    --if ((myX~=bkX)or(myY~=bkY)) then
      --if enemy.sound.move~=nil then
        --enemy.sound.move:play()
      --end
    --end
    enemy.X = myX
    enemy.Y = myY
  end
  return enemyMove
end
