<p align="center">
<img src="weasel.png" width="500" alt="Weasel Engine Trademark">
</p>

Weasel Game Engine
==================

About Weasel Game Engine
------------------------

The Weasel Game Engine is built on the LÖVE game engine and is primarily intended for the speedy development of platformer games.

Overview
--------

Games created with the Weasel Game Engine typically have the following structure.

    Game
    ├Title Scene (Stage)
    ├Stage1
    │├Map
    ││└MapChip
    │├Player
    │└Enemy
    ├Stage2
    │└ ...
    ...
    ├Complete Scene (Stage)
    ├GameOver Scene (Stage)
    ...
    ├Sound Effect
    └Back Ground Music

The game object has as many stage objects as the game requires. The title screen, complete screen, game over screen, and demo scenes shown during the game are all made as stage objects. The stage object has a map object, a player object, and enemy objects, and the map object is composed of a map chip object.

Require "weasel.lua" to use. For example:

    require("lib/weasel")

This allows you to use all the objects and functions described below.

MapChip Object
---------------

MapChip objects can be made with the following instructions. This function returns the made mapchip object.

    createMapChip()

This function makes and returns a mapchip object. This function takes no arguments.

    [MapChip Object]:addMapChip(name,imagePath)

This function adds a mapchip to [MapChip Object] with the name specified by name and the image file specified by imagePath. For example:

    mapchip = createMapChip()
    mapchip:addMapChip("sky","img/sky.png")

This example creates a mapchip object as a variable named mapchip and adds a mapchip named "Sky" to it." The image used to display "Sky" is "img/sky.png".

Map Object
----------

Map objects can be made with the following instructions. This function returns the made map object.

    createMap()

This function makes and returns a map object. This function takes no arguments.

    [Map Object]:registerChip(cno,chip)

Add the mapchip object specified in chip as the cno th mapchip to be used in [Map Object].

    [Map Object]:Obstacles = {}

Designates the map chip with the number in the list you give as an obstacle. Obstacles also have the property of being footholds.

    [Map Object]:GoalChips = {}

Specify the map tip of the number in the list you gave as the goal. When a player reaches the chip with the specified number, he/she has completed the stage.

    [Map Object]:Load(path)

Loads the map file specified by path for use in [Map Object]. The map file will be a plain text file with the characters of the map chip written side by side without any delimiters in the x-direction and separated by line breaks in the y-direction. For example:

    map = createMap()
    map:registerChip(0,mapchip.sky)
    map:registerChip(1,mapchip.ground)
    map:registerChip(2,mapchip.goal)
    map.Obstacles = {1}
    map.GoalChips = {2}
    map:Load("map/map.txt")

In this sample, a map object named map is created, and three map chips registered in the map chip object named sky, ground, and goal are registered as map chips to be used. The first chip "ground" is designated as the obstacle and the second chip "goal" is designated as the goal. Finally, "map/map.txt" is loaded as a map.

Player Object
-------------

Player objects can be made with the following instructions. This function returns the made player object.

    createPlayer(filePath)

filePath specifies the path to the image file of the sprite sheet you wish to use as the player's character. The sprite sheet should be 160px wide by 160px tall, and each frame should be 40px wide by 40px tall, with four images lined up horizontally and vertically. The animation of the sprite is four images in a horizontal line. The four rows of them will be, from the top row to the bottom row, backward, leftward, forward, and rightward.

    [Player Object]:setSound(type,path)

Set the SE in [Player Object]. If type is set to "JUMP", the sound when jumping will be set; if "MOVE", the sound when walking will be set. path should specify the SE file to be used.

    player = createPlayer("img/player.png")
    player:setSound("JUMP","snd/jump.wav")

This sample creates a player object with a variable named player. The sprite sheet "img/player.png" is used. In addition, the SE is specified so that "snd/jump.wav" is played when the player jumps.

Enemy Object
------------

Enemy objects can be made with the following instructions. This function returns the made enemy object.

    createEnemy(filePath)

filePath specifies the path to the image file of the sprite sheet you wish to use as the enemy's character. The specifications of the sprite sheet are the same as those for the player object.

    enemy = createEnemy("img/enemy.png")
    enemy.Move = game.enemyMove[0]

In this example, the "img/enemy.png" is used as the sprite sheet, and an Enemy object is created as a variable named enemy and the default Enemy movement (game.enemyMove[0]) provided by the Weasel engine is specified as its movement. The number of movement patterns available by default will be increased in future versions, but for now, only this one pattern is available.

The Move parameter of enemy can be used to specify a function to move the enemy. This function takes two arguments: function(enemy, stage). The Enemy object is passed to the enemy, and the Stage object is passed to the stage. The Player object, like the Enemy object, has a current position in (X,Y). So, for example, stage.Map.Map\[stage.Player.X\]\[stage.Player.Y+1\] will give you a map chip of the player's feet at that point.

Stage Object
------------

Stage objects can be made with the following instructions. This function returns the made stage object.

    createStage(type,next)

Setting type to 0 means that normal stages are made, and setting type to -1 means that the contents of the stage object are not automatically made. (You can use it if you want to create a stage other than a normal game stage, such as a demo scene.) Next means the number of the next stage to advance to when the stage is finished; setting next to -1 means to advance to the next stage according to the sequence of stages the game object has. (i.e. you cannot use -1 as a stage number. This stage number has special meaning.) For example:

    stage1 = createStage(0,-1)

In this sample, a normal game stage is made and received in a variable named stage1. When this stage is completed, the player will go to the next stage in the game's registered number sequence.

    preparePictureStage(picture)

This function sets the stage prepared with type=-1 to the image display stage. With this instruction, you can easily make the title screen, etc. For example:

    title = createStage(-1,-1)
    title:preparePictureStage("img/title.jpg")

This example makes a stage frame named title and sets it as an image display stage. The image to be displayed is "img/title.png". like this, you can easily make a title screen.

    [Stage Object]:addEnemy(enemyNo,enemy,x,y)

Add an enemy object specified as enemyNo to [Stage Object]. The position of the added enemy will be at the coordinates specified by x and y.

    [Stage Object]:setStart(x,y)

Specify the starting position of the player in [Stage Object] as (x,y).

    [Stage Object].Player = [Player Object]

Specify [Player Object] as the player in [Stage Object]. Since a different character can be specified as the player for each stage, it is possible to express story development in which the player's line of sight changes.

    [Stage Object].Map = [Map Object]

Specify [Map Object] as the map in [Stage Object].

    [Stage Object]:addGoal(x,y,chip,next)

Add a goal point to the coordinates (x,y) of [Stage Object] using the map chip specified in "chip". The next stage when this goal is entered will be the stage specified in next. This allows for the development of multiple goals in a given stage, with the next stage changing depending on the goal entered.

Game Object
-----------

Game objects can be made with the following instructions. This function returns the made game object.

    createGame(title,icon)

The title and icon must be strings of the title and icon file path, respectively, that will be displayed in the game window.

    [Game Object]:setBGM(path)

Specify the file specified by path as background music for [Game Object]. The specified BGM will start playing automatically.

    [Game Object]:setSound(type,path)

For [Game Object], specify the SE for the file specified by path, currently only "DEATH" can be specified for type. This is the sound that is played when the player is hit by an enemy.

    [Game Object]:addStage(stageNo,stageObj)

Specify the Stage object specified in stageObj as the stageNo th stage in [Game Object]. You cannot specify -1 for the stage number.

    [Game Object]:Init(startStage)

Initializes the game in [Game Object] for the start. startStage is the number of the first stage to be executed at the start of the game. This might often be the stage number of the title screen.

    [Game Object]:Update(dt)

Update the state of [Game Object] according to delta time dt. You would normally call this in love.update(dt). Unless you have a specific intention, there is no need to include anything other than this one statement in move.update(dt).

    [Game Object]:Draw()

Draw the current state of [Game Object] on the screen. You would normally call this in love.draw(). The screen size for games created with the Weasel Game Engine is fixed at 800px wide and 600px high, and there is no consideration for changing this. The Weasel Game Engine is designed to allow customization of various elements, but if you want to change this screen size, you will have to go through a lot of trouble.

    [Game Object].gameOverStage = StageNo

In [Game Object], StageNo specifies the stage to fly to when the player is hit by an enemy. If neither this property nor retryMode (described next) is specified, nothing will happen when the player is hit by an enemy.

    [Game Object].retryMode = true/false

If this property is set to true, the game will not be over when the player is hit by an enemy, and retries will begin immediately from the start of the stage that was being played.

For example:

    game = createGame("My Game","img/icon.png")

In this example, the variable named game receives the game object that was created. "img/icon.png" is used as the window icon.

    game:addStage(0,title)
    game:addStage(1,stage1)
    game.retryMode = true
    game:Init(0)

In this sample, in the game object named game, the title stage is added as the 0th stage and the stage1 stage is added as the 1st stage. When the player is hit by an enemy, a retry is set to start immediately from the beginning of the stage. Finally, the game is started from stage 0.

License
-------

Weasel Game Engine is released under the MIT License. And the copyright is owned by michyo.

The Weasel Game Engine Trademark was created by F4momi and is copyrighted by F4momi. It may be used freely without special permission only when referring to the Weasel Game Engine.

See LICENSE.txt for more information about the license.
