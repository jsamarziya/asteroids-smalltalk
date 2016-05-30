Object subclass: #Asteroids
	instanceVariableNames: 'win display keyboard_handler player highScores thrustKey turnLeftKey turnRightKey hyperspaceKey fireKey '
	classVariableNames: 'SpriteScaleFactor WindowBounds WindowSize '
	poolDictionaries: ''
	category: 'Asteroids'!
Asteroids comment:
'The arcade classic, Asteroids.

Instance Variables:
	win <ScheduledWindow> the game window
	display <DisplayManager> the display manager that handles drawing into the window
	keyboard_handler <KeyboardManager> the keyboard manager that handles key events
	player <Player> the current player
	highScores <HighScoreList> list of high scores
	thrustKey <Character> The key pressed to accelerate
	turnLeftKey <Character> The key pressed to turn left
	turnRightKey <Character> The key pressed to turn right
	hyperspaceKey <Character> The key pressed to go into hyperspace
	fireKey <Character> The key pressed to fire a shot

Class Variables:
	SpriteScaleFactor <Number> a scale constant used by game sprites
	WindowBounds <Rectangle> the bounds of the window
	WindowSize <Point> the extent (width@height) of the window'!


!Asteroids methodsFor: 'initialize-release'!

initialize
	"initialize the game"

	win := (ScheduledWindow
				model: nil
				label: 'Asteroids'
				minimumSize: WindowSize)
				windowType: #dialog.
	win background: ColorValue black.
	keyboard_handler := KeyboardManager for: self.
	self setUpKeyPrefs.
	self addGlobalKeys.
	player := Player new die.
	highScores := HighScoreList new.
	highScores load.
	display := DisplayManager for: self!

quit
	"close the window associated with the receiver. when the processes associated with this game detect 
	that the window has been closed, they will terminate"

	win controller closeAndUnschedule!

start
	"start the program"

	win openIn: (Rectangle
			left: 50
			top: 10
			width: WindowSize x
			height: WindowSize y).
	display start.
	self beginDemo! !

!Asteroids methodsFor: 'accessing'!

display
	"answers the display manager associated with the receiver"

	^display!

keyboard_handler
	"answers the keyboard manager associated with this game"

	^keyboard_handler!

player
	"answers the receiver's current player"

	^player!

window
	"answers the receiver's window"

	^win! !

!Asteroids methodsFor: 'demo screens'!

addTitle
	"add the title to the background."

	| title |
	title := ComposedText withText: 'A S T E R O I D S'.
	display background add: title at: Asteroids windowSize x - title width / 2 @ 100!

beginDemo
	"begin the demo"

	| demoLoopProcess |
	demoLoopProcess := [self demoLoop] fork.
	display bgcolor: ColorValue black.
	keyboard_handler add: [self quit]
		toHandle: $q.
	keyboard_handler
		add: 
			[demoLoopProcess terminate.
			self quit]
		toHandle: Character esc.
	keyboard_handler
		add: 
			[demoLoopProcess terminate.
			self removeDemoKeys.
			self play]
		toHandle: Character cr.
	keyboard_handler
		add: 
			[demoLoopProcess terminate.
			self removeDemoKeys.
			self play]
		toHandle: Character space!

demoLoop
	"slideshow the demo screens."

	| delayBetweenScreens screens |
	delayBetweenScreens := 8.
	screens := #(#displayHighScoresScreen #displayPointScheduleScreen #displayKeysScreen #displayHaikuScreen).
	[win isOpen]
		whileTrue: [screens
				do: 
					[:s | 
					display bgcolor: ColorValue black.
					self perform: s.
					display fadeIn.
					(Delay forSeconds: delayBetweenScreens) wait.
					win isOpen ifFalse: [Processor terminateActive]]]!

displayHaikuScreen
	"display an Asteroids haiku"

	| haiku rect |
	display clearBackground.
	self addTitle.
	haiku := 'An Asteriods Haiku<n><n><n>Asteroids, chunks of<n>rock, floating, spinning in space<n>Watch out for E.T.''s' expandMacros asComposedText.
	haiku justified.
	display background add: haiku at: Asteroids windowSize x - haiku width / 2 @ (Asteroids windowSize y - haiku height / 2).
	rect := haiku preferredBounds scaledBy: 1.5.
	display background add: ((GraphicsAttributesWrapper on: rect asVisualComponent)
			attributes: (GraphicsAttributes new paint: ColorValue darkGray))
		at: Asteroids windowSize x - rect width / 2 @ (Asteroids windowSize y - rect height / 2)!

displayHighScoresScreen
	"display the high scores"

	| highScoresText |
	highScoresText := highScores asComposedText justified.
	display clearBackground.
	self addTitle.
	display background add: highScoresText at: Asteroids windowSize x - highScoresText width / 2 @ 200!

displayKeysScreen
	"display the key settings"

	| keyText fkeyText |
	keyText := ((String with: turnLeftKey)
				, '<t><t>turn left<n>' , (String with: turnRightKey) , '<t><t>turn right<n>' , (String with: thrustKey) , '<t><t>thrust<n>' , 'tab' , '<t><t>hyperspace<n>' , 'space' , '<t>fire<n>' , 'p<t><t>pause') expandMacros asComposedText.
	fkeyText := '%<F1%> display level                                             %<F2%> display frame rate                          %<F3%> display update loop delay' expandMacros asComposedText centered.
	display clearBackground.
	self addTitle.
	display background add: keyText at: Asteroids windowSize x - keyText width / 2 @ 200.
	display background add: fkeyText at: Asteroids windowSize x - fkeyText width / 2 @ 550!

displayPointScheduleScreen
	"display the point schedule"

	| pointSchedule |
	display clearBackground.
	self addTitle.
	pointSchedule := 'Small Asteroids<t>100 points<n>Medium Asteroids<t>50 points<n>Large Asteroids<t>20 points<n>Large Spacecraft<t>200 points<n>Small Spacecraft<t>1,000 points<n><n><n><n>Bonus ship awarded every 10,000 points' expandMacros asComposedText.
	pointSchedule centered.
	display background add: pointSchedule at: Asteroids windowSize x - pointSchedule width / 2 @ 200! !

!Asteroids methodsFor: 'game play'!

gameOver
	"the game has ended. ask for initials if a high score was achieved, and then start the demo again."

	self removePlayKeys.
	player die.
	display unpause.
	(Delay forSeconds: 3) wait.
	(highScores isHighScore: player score)
		ifTrue: [self getInitials].
	(Delay forMilliseconds: 500) wait.
	self beginDemo!

getInitials
	"ask the player for hir initials."

	| congratulations initials inputCharacter characters |
	initials := String fromString: '___'.
	display clearBackground.
	display bgcolor: ColorValue black.
	keyboard_handler deactivate.
	congratulations := ComposedText withText: 'Congratulations, you have acheived a high score!!<n> Enter your initials:' expandMacros.
	congratulations centered.
	display background add: congratulations at: Asteroids windowSize x - congratulations width / 2 @ 200.
	display background add: (ComposedText withText: initials)
		at: Asteroids windowSize x - initials asComposedText width / 2 @ 250.
	[display fadeIn] fork.
	keyboard_handler flushQueue.
	characters := 0.
	[characters < 3]
		whileTrue: 
			[[keyboard_handler queue isEmpty]
				whileTrue: [(Delay forMilliseconds: 50) wait].
			inputCharacter := keyboard_handler queue next keyValue.
			(inputCharacter isKindOf: Character)
				ifTrue: [(inputCharacter isAlphaNumeric or: [inputCharacter asInteger = 32])
						ifTrue: 
							[characters := characters + 1.
							initials at: characters put: inputCharacter]]].
	highScores add: (HighScore score: player score initials: initials).
	highScores save.
	keyboard_handler flushQueue.
	keyboard_handler activate!

play
	"start the game"

	
	[self addPlayKeys.
	display clearBackground.
	display bgcolor: ColorValue white.
	player := Player new.
	display newGame.
	[player hasShipsRemaining]
		whileTrue: 
			[Processor yield.
			[display centerIsClear and: [display paused not]]
				whileFalse: 
					[(Delay forMilliseconds: 300) wait.
					win isOpen ifFalse: [Processor terminateActive]].
			player ship: ((Ship at: Asteroids windowBounds center)
					ownedBy: player).
			player loseShip.
			display add: player ship.
			[player ship isDestroyed]
				whileFalse: 
					[(Delay forSeconds: 3) wait.
					win isOpen ifFalse: [Processor terminateActive]].
			player hasShipsRemaining ifTrue: [(Delay forSeconds: 3) wait]].
	self gameOver] fork! !

!Asteroids methodsFor: 'keyboard control'!

addGlobalKeys
	"add global key handlers to the handler dictionary."
	"global keys are valid keys during the entire duration of the program"

	keyboard_handler add: [display toggleFrameRateDisplay]
		toHandle: #F2.
	keyboard_handler add: [display toggleLoopDelayDisplay]
		toHandle: #F3.
	keyboard_handler add: [display toggleLevelDisplay]
		toHandle: #F1!

addPlayKeys
	"add handlers for keys used while playing a game"

	keyboard_handler add: [player ship thrust]
		toHandle: thrustKey.
	keyboard_handler add: [player ship turnLeft]
		toHandle: turnLeftKey.
	keyboard_handler add: [player ship turnRight]
		toHandle: turnRightKey.
	keyboard_handler add: [player ship hyperspace]
		toHandle: hyperspaceKey.
	keyboard_handler add: [player ship fire]
		toHandle: fireKey.
	keyboard_handler add: [display pause]
		toHandle: $p!

removeDemoKeys
	"remove the handlers for demo keys"

	keyboard_handler remove: Character esc.
	keyboard_handler remove: Character space.
	keyboard_handler remove: Character cr.
	keyboard_handler remove: $q!

removePlayKeys
	"remove the handlers for game keys"

	keyboard_handler remove: thrustKey.
	keyboard_handler remove: turnLeftKey.
	keyboard_handler remove: turnRightKey.
	keyboard_handler remove: hyperspaceKey.
	keyboard_handler remove: fireKey.
	keyboard_handler remove: $p!

setUpKeyPrefs
	"establish which keys perform various game functions"

	thrustKey := $k.
	turnLeftKey := $j.
	turnRightKey := $l.
	hyperspaceKey := Character tab.
	fireKey := Character space! !

!Asteroids methodsFor: 'printing'!

printOn: aStream 
	"Append to aStream a sequence of characters that describes the receiver."

	aStream nextPutAll: 'a game of Asteroids'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Asteroids class
	instanceVariableNames: ''!


!Asteroids class methodsFor: 'instance creation'!

new
	"create a new game of Asteroids."

	^super new initialize! !

!Asteroids class methodsFor: 'accessing'!

spriteScaleFactor
	"answers the scale factor that sprites should use to determine their size"

	^SpriteScaleFactor!

windowBounds
	"answers a Rectangle that is the same size as the game window. This rectangle does not grow or 
	shrink if the game window is resized. The game window isn't *supposed* to be resizable, but it seems 
	that the NT window manager won't prevent us from making it bigger..."

	^WindowBounds!

windowSize
	"answers a Point that describes the size of the game window. This size may not reflect the actual size 
	of the window."

	^WindowSize! !

!Asteroids class methodsFor: 'class initialization'!

initialize
	"set up class constants"

	WindowSize := 800 @ 600.
	WindowBounds := Rectangle origin: 0 @ 0 extent: WindowSize.
	SpriteScaleFactor := WindowBounds area / (Rectangle origin: 0 @ 0 extent: 1000 @ 700) area! !

Object subclass: #HighScore
	instanceVariableNames: 'score initials '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
HighScore comment:
'Instances of HighScore represent a high score and the initials of the player that scored it.

Instance Variables:
	score <Number> the score
	initials <String> the initials'!


!HighScore methodsFor: 'initialize-release'!

initialize
	score := 0.
	initials := String fromString: '...'! !

!HighScore methodsFor: 'accessing'!

initials
	"answer the initials"

	^initials!

initials: i 
	"sets the receiver's initials"

	initials := i!

score
	"answers the score"

	^score!

score: s 
	"sets the receiver's score"

	score := s! !

!HighScore methodsFor: 'converting'!

asString
	^(initials , '<t><t>' , (score printStringRadix: 10)) expandMacros! !

!HighScore methodsFor: 'comparing'!

< aHighScore 
	"Answer whether the receiver is less than the argument."

	^self score < aHighScore score!

> aHighScore 
	"Answer whether the receiver is greater than the argument."

	^self score > aHighScore score! !

!HighScore methodsFor: 'printing'!

printOn: aStream 
	"Append to aStream a sequence of characters that describes the receiver."

	score printOn: aStream.
	aStream nextPutAll: ' : '.
	initials printOn: aStream! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HighScore class
	instanceVariableNames: ''!


!HighScore class methodsFor: 'instance creation'!

new
	"answers a new high score"

	^super new initialize!

score: s initials: i 
	"answers a new high score with the fields set according to the arguments"

	| newHighScore |
	newHighScore := super new.
	newHighScore score: s.
	newHighScore initials: i.
	^newHighScore! !

Object subclass: #KeyboardManager
	instanceVariableNames: 'game queue handlerDictionary active '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
KeyboardManager comment:
'Instances of KeyboardManager perform actions when keyboard events occur.

Instance variables:
	game <Asteroids> the game this manager controls input for
	queue <SharedQueue> the keyboard event queue associated with the game window
	handlerDictionary <Dictionary> a dictionary consisting of character, block pairs. 
	active <Boolean> true if the manager should poll the keyboard and dispatch actions'!


!KeyboardManager methodsFor: 'initialize-release'!

flushQueue
	[queue isEmpty] whileFalse: [queue next]!

initialize
	handlerDictionary := Dictionary new.
	self flushQueue.
	active := true! !

!KeyboardManager methodsFor: 'accessing'!

activate
	"make the receiver active; that is, poll the keyboard and dispatch actions"

	active := true!

deactivate
	"make the receiver inactive; that is, don't poll the keyboard or dispatch actions"

	active := false!

game: aGame 
	"set the game for which the receiver is to handle input for"

	game := aGame!

queue
	"answers the receiver's keyboard event queue"

	^queue!

queue: aKeyboardDevice 
	"set the receiver's keyboard event queue"

	queue := aKeyboardDevice! !

!KeyboardManager methodsFor: 'handlers'!

add: aBlock toHandle: aCharacter 
	"add a keypress handler routine to the handler dictionary"

	handlerDictionary add: (Association key: aCharacter value: aBlock)!

remove: aCharacter 
	"remove the handler for aCharacter from the handler dictionary"

	handlerDictionary add: (Association key: aCharacter value: [])!

removeAll
	"remove all handlers from the dictionary"

	handlerDictionary := Dictionary new.! !

!KeyboardManager methodsFor: 'polling'!

pollKeyboard
	"poll the keyboard, dispatch events as required"

	| inputCharacter handler |
	active ifTrue: [queue isEmpty
			ifFalse: 
				[inputCharacter := queue next keyValue.
				game display paused
					ifTrue: [game display unpause]
					ifFalse: 
						[handler := handlerDictionary at: inputCharacter ifAbsent: [nil].
						handler isNil ifFalse: [handler value]]]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

KeyboardManager class
	instanceVariableNames: ''!


!KeyboardManager class methodsFor: 'instance creation'!

for: aGame
	"answers a new handler to handle keyboard events for an asteroids game"

	| handler |
	handler := super new.
	handler game: aGame.
	handler queue: aGame window sensor keyboardDevice.
	handler initialize.
	^handler! !

Link subclass: #SpriteLink
	instanceVariableNames: 'sprite '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
SpriteLink comment:
'Instances of SpriteLink are used as nodes in LinkedLists of Sprites.

Instance Variables:
	sprite <Sprite> the sprite value'!


!SpriteLink methodsFor: 'accessing'!

sprite
	"answers the sprite held in the receiver"

	^sprite!

sprite: aSprite 
	"sets the receiver's sprite slot"

	sprite := aSprite! !

Object subclass: #HighScoreList
	instanceVariableNames: 'list '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
HighScoreList comment:
'Instances of HighScoreList hold a list of high scores that can be loaded from and saved to a file.

Instance Variables:
	list <SortedCollection> a collection of HighScores'!


!HighScoreList methodsFor: 'initialize-release'!

initialize
	list := SortedCollection sortBlock: [:x :y | x > y].
	1 to: 10 do: [:i | list add: HighScore new]! !

!HighScoreList methodsFor: 'adding'!

add: highScore 
	"add a new high score to the list. The size of the list won't go above 10."

	list add: highScore.
	[list size > 10]
		whileTrue: [list removeLast]! !

!HighScoreList methodsFor: 'converting'!

asComposedText
	"answers a ComposedText representation of the list"

	| text |
	text := ComposedText withText: self asString.
	text rightFlush.
	^text!

asString
	"answers a String representation of the list"

	| text |
	text := ''.
	list do: [:i | text := text , i asString]
		separatedBy: [text := text , '<n>' expandMacros].
	^text! !

!HighScoreList methodsFor: 'file I/O'!

load
	"load high scores from a disk file"

	| boss |
	Signal noHandlerSignal handle: [:ex | ex return]
		do: 
			[boss := BinaryObjectStorage onOldNoScan: (FileConnection
							openFileNamed: 'Asteroids high scores'
							mode: #readOnly
							creationRule: #noCreate) input readStream.
			[list := boss next]
				valueNowOrOnUnwindDo: [boss close]]!

save
	"save high scores to a disk file"

	| boss |
	Signal noHandlerSignal handle: [:ex | ex return]
		do: 
			[boss := BinaryObjectStorage onNew: (FileConnection
							openFileNamed: 'Asteroids high scores'
							mode: #writeOnly
							creationRule: #truncateOrCreate) output writeStream.
			[boss nextPut: list]
				valueNowOrOnUnwindDo: [boss close]]! !

!HighScoreList methodsFor: 'printing'!

printOn: aStream 
	"Append to aStream a sequence of characters that describes the receiver."

	list printOn: aStream! !

!HighScoreList methodsFor: 'testing'!

isHighScore: score 
	"answers true if score is a high score"

	^score > list last score! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HighScoreList class
	instanceVariableNames: ''!


!HighScoreList class methodsFor: 'instance creation'!

new
	"answers a new high score list"

	^super new initialize! !

Object subclass: #Player
	instanceVariableNames: 'score ships level ship '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
Player comment:
'A Player holds the information about a person who is playing Asteroids.

Instance variables:
	score <Number> Player''s score.
	ships <Number> Number of ships remaining.
	level <Number> Level we''re playing on.
	ship <Number> The Ship associated with the player'!


!Player methodsFor: 'initialize-release'!

initialize
	"initialize the object"

	score := 0.
	ships := 3.
	level := 1.
	ship := nil! !

!Player methodsFor: 'accessing'!

award: points 
	"add points to the receiver's score"
	"award the player a new ship every 10000 points"

	score + points \\ 10000 < (score \\ 10000) ifTrue: [self gainShip].
	score := score + points!

die
	"kill off the receiver"

	ships := -1.
	ship notNil ifTrue: [ship destroy]!

gainLevel
	"move the receiver up a level"

	level := level + 1!

gainShip
	"receiver gains a ship"

	ships := ships + 1!

level
	"answers the level at which this player is currently playing at."

	^level!

level: l 
	"set the level of the receiver"

	level := l!

loseShip
	"receiver loses a ship"

	ships := ships - 1!

score
	"answers the player's score"

	^score!

score: s 
	"set the receiver's score"

	score := s!

ship
	"answers the Ship sprite associated with this player"

	^ship!

ship: aShip 
	"set aShip to be the player's ship."

	ship := aShip!

ships
	"answers the number of ships remaining"

	^ships max: 0!

ships: numberOfShips 
	"set the number of ships remaining"

	ships := numberOfShips! !

!Player methodsFor: 'testing'!

hasShipsRemaining
	"answers true if the player still has ships left."

	^ships > 0!

isAlive
	"answers true if the player is still alive."

	^ships > -1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Player class
	instanceVariableNames: ''!


!Player class methodsFor: 'instance creation'!

new
	"answers a new player"

	^super new initialize! !

Object subclass: #SpriteWorld
	instanceVariableNames: 'sprites '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
SpriteWorld comment:
'Instances of SpriteWorld hold a collection of sprites.

Instance Variables:
	sprites <MyLinkedList> the sprites contained in the world'!


!SpriteWorld methodsFor: 'initialize-release'!

initialize
	"initialize the receiver"

	sprites := MyLinkedList new! !

!SpriteWorld methodsFor: 'adding-removing'!

add: aSprite 
	"add a sprite to the world"

	sprites add: (SpriteLink new sprite: (aSprite world: self))!

addAll: aCollection 
	"add a collection of sprites to the world"

	aCollection do: [:s | self add: s]!

destroyAll
	"destroy all sprites in the receiver"

	self do: [:s | s destroy]! !

!SpriteWorld methodsFor: 'displaying'!

displayOn: aGraphicsContext 
	"display the receiver's sprites on aGraphicsContext"

	self do: [:s | s displayOn: aGraphicsContext]! !

!SpriteWorld methodsFor: 'enumerating'!

do: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument."

	sprites do: [:l | aBlock value: l sprite]! !

!SpriteWorld methodsFor: 'testing'!

isEmpty
	"answers true if there are no sprites in the world"

	^sprites isEmpty! !

!SpriteWorld methodsFor: 'updating'!

removeDestroyedSprites
	"remove sprites that are destroyed from the receiver"

	sprites removeIf: [:l | l sprite isDestroyed]!

update
	"update each of the receiver's sprites and remove destroyed sprites"

	self do: [:s | s update].
	self removeDestroyedSprites! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpriteWorld class
	instanceVariableNames: ''!


!SpriteWorld class methodsFor: 'instance creation'!

new
	^super new initialize! !

LinkedList subclass: #MyLinkedList
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
MyLinkedList comment:
'This is the basic LinkedList class with a method added to efficiently remove large numbers of elements all at once.'!


!MyLinkedList methodsFor: 'removing'!

removeIf: aBlock 
	"iterate over each link in the list, passing aBlock the link. If aBlock evaluates to true, remove that 
	link."

	| previousLink |
	[firstLink ~~ nil and: [aBlock value: firstLink]]
		whileTrue: [self removeFirst].
	firstLink ~~ nil
		ifTrue: 
			[previousLink := firstLink.
			[previousLink nextLink == nil]
				whileFalse: [(aBlock value: previousLink nextLink)
						ifTrue: 
							[previousLink nextLink == lastLink ifTrue: [lastLink := previousLink].
							previousLink nextLink: previousLink nextLink nextLink]
						ifFalse: [previousLink := previousLink nextLink]]]! !

Object subclass: #DisplayManager
	instanceVariableNames: 'world gameState background bgcolor gc paused asteroidSpitter shipSpitter showFrameRate showLoopDelay showLevel '
	classVariableNames: 'LittleShip UpdatePeriod '
	poolDictionaries: ''
	category: 'Asteroids'!
DisplayManager comment:
'A DisplayManager handles updating sprites and redrawing the screen.

Instance Variables:
	world <SpriteWorld> the set of sprites that this scheduler controls
	gameState <Asteroids> the game whose display this manager is controlling
	background <CompositePart> the component that holds static background elements
	bgcolor <ColorValue> the color with which the background component is drawn
	gc <GraphicsContext> the graphics context of the window this manager controlls
	paused <Boolean> true when the game is paused
	asteroidSpitter <Process> the process that creates new asteroids
	shipSpitter <Process> the process that creates spaceships
	showFrameRate <Boolean> if true, the frame rate is displayed on the screen
	showLoopDelay <Boolean> if true, the update loop delay is displayed on the screen
	showLevel <Boolean> if true, the player level is displayed on the screen

Class Variables:
	LittleShip <Polyline> the shape drawn to represent a ship that the player has in reserve
	UpdatePeriod <Number> the (minimum) period between updates'!


!DisplayManager methodsFor: 'initialize-release'!

initialize
	"initialize the receiver"

	world := SpriteWorld new.
	background := CompositePart new.
	bgcolor := ColorValue white.
	paused := false.
	showLoopDelay := false.
	showFrameRate := false.
	showLevel := true! !

!DisplayManager methodsFor: 'accessing'!

add: aSprite 
	"add aSprite to the world"

	world add: aSprite!

addMoreAsteroids
	"add asteroids to the playing field."

	| numberOfAsteroids |
	gameState player notNil
		ifTrue: [numberOfAsteroids := 3 + (gameState player level // 2) min: 8]
		ifFalse: [numberOfAsteroids := 5].
	1 to: numberOfAsteroids do: [:i | world add: Asteroid new]!

background
	"answer the compositePart that holds the background objects."

	^background!

background: aCompositePart
	"set the compositePart that holds the background objects."

	background := aCompositePart!

bgcolor
	"answers the receiver's background color (the color in which the background component is drawn)"

	^bgcolor!

bgcolor: c 
	"set the background color"

	bgcolor := c!

game: aGame 
	"set the game for which the receiver is to manage the display"

	gameState := aGame!

paused
	"answers true if the game is paused"

	^paused!

removeAllSprites
	"remove all sprites from the playing field"

	world destroyAll! !

!DisplayManager methodsFor: 'control'!

clearBackground
	"remove all objects from the background."

	background := CompositePart new!

fadeIn
	"fade the background color to white"

	bgcolor brightness
		to: 1
		by: 0.3
		do: 
			[:c | 
			bgcolor := ColorValue brightness: c. 
			(Delay forMilliseconds: UpdatePeriod) wait]!

fadeOut
	"fade the background color to black"

	bgcolor brightness
		to: 0
		by: -0.3
		do: 
			[:c | 
			bgcolor := ColorValue brightness: c.
			(Delay forMilliseconds: UpdatePeriod) wait]!

newGame
	"initialize the display for a new game"

	shipSpitter terminate.
	asteroidSpitter terminate.
	self removeAllSprites.
	asteroidSpitter := [self asteroidSpitter] fork.
	shipSpitter := [self shipSpitter] fork!

pause
	"pause the game"

	paused := true.
	shipSpitter suspend!

start
	"start managing the display"

	[self updateLoop] fork.
	asteroidSpitter := [self asteroidSpitter] fork.
	shipSpitter := [self shipSpitter] fork!

toggleFrameRateDisplay
	"toggle the state of displaying the frame rate on the screen"

	showFrameRate := showFrameRate not!

toggleLevelDisplay
	"toggle the state of displaying the player's level on the screen"

	showLevel := showLevel not!

toggleLoopDelayDisplay
	"toggle the state of displaying the update loop delay on the screen"

	showLoopDelay := showLoopDelay not!

unpause
	"take the game out of pause mode"

	paused ifTrue: [shipSpitter resume].
	paused := false! !

!DisplayManager methodsFor: 'processes'!

asteroidSpitter
	"spawns asteroids when there's no more left"

	[gameState window isOpen]
		whileTrue: 
			[self addMoreAsteroids.
			[self asteroidsExist]
				whileTrue: 
					[Processor yield.
					(Delay forSeconds: 2) wait.
					gameState window isOpen ifFalse: [Processor terminateActive]].
			(Delay forSeconds: 2) wait.
			gameState player isAlive ifTrue: [gameState player gainLevel]]!

shipSpitter
	"spawns spaceships"

	[gameState window isOpen]
		whileTrue: 
			[(Delay forSeconds: (20 - (gameState player level // 3) max: 15)) wait.
			gameState window isOpen ifFalse: [Processor terminateActive].
			gameState player level > 1 ifTrue: [gameState player level > 5
					ifTrue: [world add: Spaceship small]
					ifFalse: [world add: Spaceship large]]]!

updateLoop
	"polls the keyboard, updates the sprites in the world, and displays the next frame in the window"

	| windowGC buffer startTime loopDelay untilTimeToRefresh |
	windowGC := gameState window graphicsContext.
	buffer := Pixmap extent: Asteroids windowSize.
	gc := buffer graphicsContext.
	buffer background: ColorValue black.
	loopDelay := 1.
	Object errorSignal handle: [:ex | gameState window isOpen
			ifTrue: [ex reject]
			ifFalse: [ex return]]
		do: [[gameState window isOpen]
				whileTrue: 
					[startTime := Time millisecondClockValue.
					untilTimeToRefresh := Delay untilMilliseconds: startTime + UpdatePeriod.
					gc clear.
					gameState keyboard_handler pollKeyboard.
					Processor yield.
					self paused ifFalse: [world update].
					world displayOn: gc.
					gc paint: bgcolor.
					background displayOn: gc.
					self displayShipsRemaining.
					self displayScore.
					showLevel ifTrue: [self displayLevel].
					showLoopDelay ifTrue: [self displayDelayBar: loopDelay].
					showFrameRate ifTrue: [self displayFrameRate: loopDelay].
					buffer displayOn: windowGC.
					loopDelay := Time millisecondClockValue - startTime.
					untilTimeToRefresh wait]]! !

!DisplayManager methodsFor: 'testing'!

asteroidsExist
	"answers true if there are still asteroids on the screen"

	| retblock |
	retblock := [^true].
	world do: [:s | (s isMemberOf: Asteroid)
			ifTrue: [retblock value]].
	^false!

centerIsClear
	"answers true if the center is clear to add a ship."

	^((Ship at: Asteroids windowBounds center)
		world: world) isClear!

spriteExists: aSprite 
	"answers true if aSprite exists on the screen"

	| retblock |
	retblock := [^true].
	world do: [:s | s sprite = aSprite ifTrue: [retblock value]].
	^false! !

!DisplayManager methodsFor: 'private'!

displayDelayBar: loopDelay 
	"draw the update loop delay bar on the graphics buffer"

	| colorBar |
	colorBar := Rectangle origin: Asteroids windowSize - (50 @ 20) extent: 40 @ 20.
	gc paint: (ColorValue
			red: (loopDelay > (UpdatePeriod + 10)
					ifTrue: [0.75]
					ifFalse: [0])
			green: (loopDelay <= (UpdatePeriod + 20)
					ifTrue: [0.75]
					ifFalse: [0])
			blue: 0).
	colorBar displayFilledOn: gc.
	gc paint: ColorValue black.
	(loopDelay printStringRadix: 10) asComposedText displayOn: gc at: Asteroids windowSize - (40 @ 20)!

displayFrameRate: loopDelay 
	"draw the screen refresh rate on the graphics buffer"

	| aStream rate |
	gc paint: ColorValue gray.
	aStream := WriteStream on: (String new: 6).
	(1000 / loopDelay asFixedPoint: 1)
		printOn: aStream.
	rate := aStream contents asComposedText centered.
	rate displayOn: gc at: Asteroids windowSize x - rate width // 2 @ (Asteroids windowSize y - 20)!

displayLevel
	"draw the player's level on the graphics buffer"

	gc paint: ColorValue white.
	('Level: ' , (gameState player level printStringRadix: 10)) asComposedText displayOn: gc at: 20 @ (Asteroids windowSize y - 20)!

displayScore
	"draw the score on the graphics buffer"

	gc paint: ColorValue white.
	(gameState player score printStringRadix: 10) asComposedText displayOn: gc at: 80 @ 20!

displayShipsRemaining
	"draw the number of ships remaining on the graphics buffer"

	gc paint: ColorValue white.
	1 to: gameState player ships do: [:i | (LittleShip translatedBy: 65 + (20 * i) @ 60)
			displayStrokedOn: gc]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DisplayManager class
	instanceVariableNames: ''!


!DisplayManager class methodsFor: 'instance creation'!

for: aGame 
	"answers a new DisplayManager to handle the display for aGame."

	| engine |
	engine := super new.
	engine game: aGame.
	engine initialize.
	^engine! !

!DisplayManager class methodsFor: 'class initialization'!

initialize
	"set up class variables (constants)"

	Ship initialize.
	LittleShip := Ship new shape scaledBy: 1 / 3.
	UpdatePeriod := 80! !

Random subclass: #RandomNumber
	instanceVariableNames: ''
	classVariableNames: 'R '
	poolDictionaries: ''
	category: 'Asteroids'!
RandomNumber comment:
'Don''t make instances of this class.  Use the class methods for access.

Class Variables:
	R <Random> Random number generator.'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RandomNumber class
	instanceVariableNames: ''!


!RandomNumber class methodsFor: 'accessing'!

between: left and: right 
	"returns a value between left and right, inclusive"

	| retval |
	(left isKindOf: Point)
		ifTrue: [^self pointBetween: left and: right].
	right >= left
		ifTrue: 
			[retval := R next * (right - left) + left.
			((left isKindOf: Integer)
				and: [right isKindOf: Integer])
				ifTrue: [retval := retval rounded].
			^retval]
		ifFalse: [^self between: right and: left]!

chance: probability 
	"answers true if a random event of given probability occurs. 
	The probability is given as an integer between 0 and 100 or as a percentage between 0 and 1."

	(probability isKindOf: Integer)
		ifTrue: [^R next < (probability / 100)]
		ifFalse: [^R next < probability]!

lessThan: limit 
	"returns a number less than limit."

	| retval |
	(limit isKindOf: Point)
		ifTrue: [^self pointLessThan: limit].
	retval := R next * limit.
	(limit isKindOf: Integer)
		ifTrue: [retval := retval truncated].
	^retval!

pointBetween: left and: right 
	"returns an Point value between left and right, inclusive. You can pass Points to between:and: if you 
	like, since it just calls this."

	^Point x: (self between: left x and: right x)
		y: (self between: left y and: right y)!

pointLessThan: limit 
	"returns a Point less than limit. The limit is itself a Point. You can send Points to lessThan: if you 
	want, since it just calls this."

	^Point x: (self lessThan: limit x)
		y: (self lessThan: limit y)!

pointOutside: aRectangle by: limit 
	"returns a Point just outside aRectangle. Limit may be a scalar or a Point."
	"This looks like a mess... I wonder if there's a better way to do this."

	| xLimit yLimit select |
	(limit isKindOf: Point)
		ifTrue: 
			[xLimit := limit x.
			yLimit := limit y]
		ifFalse: 
			[xLimit := limit.
			yLimit := limit].
	select := self between: 1 and: 8.
	select = 1 ifTrue: [^self between: aRectangle left - xLimit @ (aRectangle top - yLimit) and: aRectangle left @ aRectangle top].
	select = 2 ifTrue: [^self between: aRectangle left @ (aRectangle top - yLimit) and: aRectangle right @ aRectangle top].
	select = 3 ifTrue: [^self between: aRectangle right @ (aRectangle top - yLimit) and: aRectangle right + xLimit @ aRectangle top].
	select = 4 ifTrue: [^self between: aRectangle left - xLimit @ aRectangle top and: aRectangle left @ aRectangle bottom].
	select = 5 ifTrue: [^self between: aRectangle right + xLimit @ aRectangle top and: aRectangle right + xLimit @ aRectangle bottom].
	select = 6 ifTrue: [^self between: aRectangle left - xLimit @ aRectangle bottom and: aRectangle left @ (aRectangle bottom + yLimit)].
	select = 7 ifTrue: [^self between: aRectangle left @ aRectangle bottom and: aRectangle right @ (aRectangle bottom + yLimit)].
	select = 8 ifTrue: [^self between: aRectangle right @ aRectangle bottom and: aRectangle right + xLimit @ (aRectangle bottom + yLimit)].
	self error: 'pointOutside failed to select an option'! !

!RandomNumber class methodsFor: 'instance creation'!

new
	"don't create instances of this class. use the class methods for access."

	self shouldNotImplement! !

!RandomNumber class methodsFor: 'class initialization'!

initialize
	"set up the random number generator"

	R := Random new! !

Object subclass: #Sprite
	instanceVariableNames: 'shape location velocity acceleration angular_speed state color world '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
Sprite comment:
'This is the superclass of all the sprites in Asteroids.

Instance Variables:
	shape <Polyline> The graphical object that represents the geometry of the sprite.
	location <Point> x,y coordinates of the center of the sprite
	velocity <Point> Add this to location at each update
	acceleration <Point> Add this to velocity at each update
	angular_speed <Number> rotate the sprite by this much at each update
	state <Object> Can be #visible, #hidden, or #destroyed
	color <ColorValue> color of the sprite
	world <SpriteWorld> the world (set of sprites) in which this sprite lives'!


!Sprite methodsFor: 'initialize-release'!

initialize
	"initialize the parameters of the sprite"

	state := #visible.
	shape := nil.
	color := ColorValue white.
	location := 0 @ 0.
	velocity := 0 @ 0.
	acceleration := 0 @ 0.
	angular_speed := 0.
	world := nil! !

!Sprite methodsFor: 'accessing'!

acceleration
	"answer the acceleration of the receiver"

	^acceleration!

acceleration: accel 
	"set the acceleration of the receiver"

	acceleration := accel!

angular_speed
	"answer the angular speed of the receiver"

	^angular_speed!

angular_speed: speed 
	"set the angular speed of the receiver"

	angular_speed := speed!

area
	"answer the area of the receiver"
	"this is used in momentum calculations"

	^shape bounds area!

color
	"answers the receiver's color"

	^color!

color: c 
	"set the receiver's color"

	color := c!

location
	"answer the location of the receiver"

	^location!

pointValue
	"answer the point value of the receiver"

	^0!

shape
	"answer the shape of the receiver"

	^shape!

shape: s 
	"set the shape of the receiver"

	shape := s!

state
	"answers the state of the receiver. Normally this will be #visible, #hidden, or #destroyed"

	^state!

velocity
	"answer the velocity of the receiver"

	^velocity!

velocity: speed
	"set the velocity of the receiver"

	velocity := speed!

world
	"answers the SpriteWorld in which the receiver lives"

	^world!

world: aSpriteWorld 
	"put the receiver into aSpriteWorld"

	world := aSpriteWorld! !

!Sprite methodsFor: 'collision detection'!

checkForCollision
	"check for collisions between the receiver and the sprites in the receiver's world"

	| retblock |
	retblock := [^nil].
	world do: [:s | s = self ifFalse: [s isVisible ifTrue: [(self isCollidingWith: s)
					ifTrue: 
						[self impact: s.
						retblock value]]]]!

collisionCheckRectangle
	"answers a Rectangle that can be used when checking for collisions"

	self isVisible
		ifTrue: [^(shape translatedBy: location) asRectangle]
		ifFalse: [^Rectangle origin: -9999 @ -9999 extent: 0 @ 0]!

isClear
	"returns true if none of the sprites in the world are near."

	| retblock |
	retblock := [^false].
	world do: [:s | s = self ifFalse: [s isVisible ifTrue: [(s collisionCheckRectangle intersects: ((shape asRectangle scaledBy: 3)
						translatedBy: location))
					ifTrue: [retblock value]]]].
	^true!

isCollidingWith: aSprite 
	"returns true if the receiver is colliding with a sprite"

	self isVisible ifFalse: [^false].
	^(shape translatedBy: location)
		regionIntersects: aSprite collisionCheckRectangle! !

!Sprite methodsFor: 'displaying'!

displayOn: aGraphicsContext 
	"display the sprite on aGraphicsContext"

	self isVisible
		ifTrue: 
			[aGraphicsContext paint: self color.
			(shape translatedBy: location)
				displayStrokedOn: aGraphicsContext]! !

!Sprite methodsFor: 'testing'!

isDestroyed
	"answers true if the receiver has been destroyed"

	^state = #destroyed!

isHidden
	"answers true if the receiver is hidden"

	^state = #hidden!

isOffscreen
	"answers true if the object is off the screen."

	^((shape translatedBy: location)
		outlineIntersects: Asteroids windowBounds) not!

isVisible
	"answers true if the receiver is visible"

	^state = #visible! !

!Sprite methodsFor: 'transforming'!

addFlamingBits
	"adds a collection of sprites that are the exploded remains of the receiver to the receiver's world"

	shape edgesDo: [:p1 :p2 | (RandomNumber chance: 0.70)
			ifTrue: [world add: (FlamingBit
						from: p1
						to: p2
						at: location
						velocity: velocity)]]!

destroy
	"destroy the receiver"

	state := #destroyed!

hide
	"make receiver invisible, but don't destroy it."

	self isVisible ifTrue: [state := #hidden]!

impact: aSprite 
	"run the receiver into a sprite, modifying both sprites' velocities."

	| myOldVelocity |
	myOldVelocity := self velocity.
	self velocity: self velocity + (aSprite velocity * aSprite area / self area / 3).
	aSprite velocity: aSprite velocity + (myOldVelocity * self area / aSprite area / 3).
	self addFlamingBits.
	aSprite addFlamingBits.
	self destroy.
	aSprite destroy!

moveTo: aPoint 
	"set the location of the sprite"

	aPoint = #offscreen
		ifTrue: [location := RandomNumber pointOutside: Asteroids windowBounds by: shape asRectangle extent]
		ifFalse: [location := aPoint]!

rotate: angle 
	"rotate the sprite by an angle (in radians)"

	angle isZero ifFalse: [1 to: shape vertices size
			do: 
				[:i | 
				| p |
				p := shape vertices.
				shape vertices at: i put: (Point r: (p at: i) r theta: (p at: i) theta + angle)]]!

unHide
	"make receiver visible"

	self isHidden ifTrue: [state := #visible]!

wrap
	"wrap the receiver around to the other side of the window"

	| width height windowWidth windowHeight |
	width := shape asRectangle width.
	height := shape asRectangle height.
	windowWidth := Asteroids windowSize x + width.
	windowHeight := Asteroids windowSize y + height.
	location x: location x + (width / 2) \\ windowWidth - (width / 2).
	location y: location y + (height / 2) \\ windowHeight - (height / 2)! !

!Sprite methodsFor: 'updating'!

update
	"update the parameters of the sprite. move the sprite to its new location, rotate it, and check for 
	collisions"

	self rotate: angular_speed.
	self moveTo: location + velocity.
	self isOffscreen ifTrue: [self wrap].
	self velocity: velocity + acceleration.
	self isVisible ifTrue: [self checkForCollision]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Sprite class
	instanceVariableNames: ''!


!Sprite class methodsFor: 'instance creation'!

at: location 
	"answers a new sprite at location"

	| newSprite |
	newSprite := super new initialize.
	newSprite moveTo: location.
	^newSprite!

new
	"answers a new sprite"

	^self at: 0 @ 0! !

Sprite subclass: #Spaceship
	instanceVariableNames: 'direction pointValue '
	classVariableNames: 'ShipShape '
	poolDictionaries: ''
	category: 'Asteroids'!
Spaceship comment:
'The spaceship sprite. These are the aliens that come out and shoot you down.

Instance Variables:
	direction <Number> a number that represents whether the spaceship is going left-to-right (positive) or right-to-left (negative)'!


!Spaceship methodsFor: 'initialize-release'!

initialize
	super initialize.
	direction := 10.
	(RandomNumber chance: 0.5)
		ifTrue: [self moveTo: (RandomNumber between: Asteroids windowBounds left - direction @ Asteroids windowBounds top and: Asteroids windowBounds left - direction @ Asteroids windowBounds bottom)]
		ifFalse: 
			[direction := direction negated.
			self moveTo: (RandomNumber between: Asteroids windowBounds right - direction @ Asteroids windowBounds top and: Asteroids windowBounds right - direction @ Asteroids windowBounds bottom)].
	self changeVelocity! !

!Spaceship methodsFor: 'accessing'!

pointValue
	"answers the point value of the ship"

	^pointValue!

pointValue: pv
	"sets the point value of the receiver"

	pointValue := pv! !

!Spaceship methodsFor: 'collision checking'!

checkForCollision
	"check for collisions with the sprites in the world"

	^nil!

isCollidingWith: aSprite 
	"returns true if the receiver is colliding with a sprite"

	^false! !

!Spaceship methodsFor: 'testing'!

hasEscaped
	"answers whether the receiver has reached the other side of the screen."

	direction > 0
		ifTrue: [^location x > (Asteroids windowSize x + direction)]
		ifFalse: [^location x < direction]! !

!Spaceship methodsFor: 'transforming'!

changeVelocity
	"do a dodge"

	velocity := Point x: direction y: (RandomNumber between: -20 and: 20)!

takeAShot
	"fire a shot."

	world add: (Bullet parent: self)!

update
	"update the parameters of the sprite"

	super update.
	(RandomNumber chance: 0.05)
		ifTrue: [self changeVelocity].
	(RandomNumber chance: 0.05)
		ifTrue: [self takeAShot].
	self hasEscaped ifTrue: [self destroy]!

wrap
	"wrap around to the other side of the window"

	| height windowHeight |
	height := shape asRectangle height.
	windowHeight := Asteroids windowSize y + height.
	location y: location y + (height / 2) \\ windowHeight - (height / 2)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Spaceship class
	instanceVariableNames: ''!


!Spaceship class methodsFor: 'class initialization'!

initialize
	"sets up the spaceship shape"

	| hemisphere returnPoint domeWidth |
	ShipShape := OrderedCollection new.
	hemisphere := (Circle center: 0 @ 0 radius: 120) asPolyline vertices select: [:p | p y < -35].
	ShipShape addAll: hemisphere.
	ShipShape add: hemisphere first.
	domeWidth := hemisphere first dist: hemisphere last.
	ShipShape add: ShipShape last + (-50 @ 50).
	returnPoint := ShipShape last + (domeWidth + 100 @ 0).
	ShipShape add: returnPoint.
	ShipShape add: hemisphere last.
	ShipShape add: returnPoint.
	ShipShape add: ShipShape last + (-50 @ 0).
	ShipShape add: ShipShape last + (-25 @ 25).
	ShipShape add: ShipShape last + (50 - domeWidth @ 0).
	ShipShape add: ShipShape last + (-25 @ -25)! !

!Spaceship class methodsFor: 'instance creation'!

large
	"answers a new large spaceship"

	^(super new initialize shape: ((Polyline vertices: ShipShape)
			scaledBy: 1 / 5 * Asteroids spriteScaleFactor))
		pointValue: 200!

new
	"answers a new large spaceship"

	^self large!

small
	"answers a new small spaceship"

	^(super new initialize shape: ((Polyline vertices: ShipShape)
			scaledBy: 1 / 8 * Asteroids spriteScaleFactor))
		pointValue: 1000! !

Sprite subclass: #Asteroid
	instanceVariableNames: 'scale '
	classVariableNames: 'LargeScale MediumScale SmallScale '
	poolDictionaries: ''
	category: 'Asteroids'!
Asteroid comment:
'The asteroid sprite.

Instance variables:
	scale <Number> size of the asteroid

Class variables:
	LargeScale <Number> scale of a large asteroid (constant)
	MediumScale <Number> scale of a medium asteroid (constant)
	SmallScale <Number> scale of a small asteroid (constant)
'!


!Asteroid methodsFor: 'initialize-release'!

newShape
	"create a new shape for the receiver"

	| angle list |
	angle := RandomNumber lessThan: 0.5.
	list := OrderedCollection new.
	[angle < 6.28319]
		whileTrue: 
			[list add: (Point r: scale - (RandomNumber lessThan: scale * 0.4) theta: angle).
			angle := angle + (RandomNumber between: 0.2 and: 0.4)].
	list add: list first.
	shape := Polyline vertices: list! !

!Asteroid methodsFor: 'accessing'!

pointValue
	"answer the point value of the receiver"

	scale = LargeScale ifTrue: [^20].
	scale = MediumScale ifTrue: [^50].
	scale = SmallScale ifTrue: [^100].
	self error: 'I dont know what size I am'!

scale
	"answer the scale of the receiver"

	^scale!

scale: s 
	"set the scale of the receiver"

	scale := s! !

!Asteroid methodsFor: 'collision detection'!

checkForCollision
	"check for collisions with the sprites in the world"
	"asteroids don't need to check for collisions. if another sprite runs into an asteroid, we'll detect it when 
	that sprite checks for collisions."

	^nil!

isCollidingWith: aSprite 
	"returns true if the receiver is colliding with aSprite"
	"Asteroids don't collide into anything. Other things collide into asteroids."

	^false! !

!Asteroid methodsFor: 'transforming'!

addFlamingBits
	"adds a collection of sprites that are the exploded remains of the receiver to the world"
	"we also add some smaller asteroids, if applicable"

	super addFlamingBits.
	scale = SmallScale ifFalse: [1 to: 2 do: [:a | world add: (Asteroid from: self)]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Asteroid class
	instanceVariableNames: ''!


!Asteroid class methodsFor: 'class initialization'!

initialize
	"set up scale constants"

	Asteroids initialize.
	LargeScale := 100 * Asteroids spriteScaleFactor.
	MediumScale := 30 * Asteroids spriteScaleFactor.
	SmallScale := 10 * Asteroids spriteScaleFactor! !

!Asteroid class methodsFor: 'instance creation'!

from: parent 
	"answers a new asteroid that is one size smaller than the parent. Raises an exception if parent is 
	SmallScale"

	| size child |
	parent scale = LargeScale
		ifTrue: [size := MediumScale]
		ifFalse: [parent scale = MediumScale
				ifTrue: [size := SmallScale]
				ifFalse: [self error: 'Asteroid from: called with a small parent']].
	child := Asteroid new: size at: parent location + (RandomNumber between: parent scale negated @ parent scale negated and: parent scale @ parent scale).
	child velocity: (Point r: parent velocity r + (RandomNumber between: 3.0 and: 8.0) theta: parent velocity theta + (RandomNumber between: -1.0 and: 1.0)).
	^child!

new
	"answers a new large asteroid."

	^self new: LargeScale at: #offscreen!

new: size at: location 
	"answers a new asteroid at a given location, which may be a Point or may be #offscreen."

	| newAsteroid maxAngularVelocity maxXSpeed maxYSpeed |
	newAsteroid := super new initialize.
	newAsteroid scale: size.
	newAsteroid newShape.
	newAsteroid moveTo: location.
	maxAngularVelocity := 4 / size.
	maxXSpeed := 125 / size.
	maxYSpeed := 250 / size.
	newAsteroid angular_speed: (RandomNumber between: maxAngularVelocity negated and: maxAngularVelocity).
	newAsteroid velocity: (RandomNumber between: maxXSpeed negated and: maxXSpeed)
			@ (RandomNumber between: maxYSpeed negated and: maxYSpeed).
	^newAsteroid! !

Sprite subclass: #FlamingBit
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Asteroids'!
FlamingBit comment:
'A FlamingBit is a piece of a sprite that remains after it explodes.
'!


!FlamingBit methodsFor: 'collision detection'!

checkForCollision
	"FlamingBits don't collide with anything"

	^nil!

isCollidingWith: aSprite 
	"answers true if the receiver is colliding with aSprite"

	^false! !

!FlamingBit methodsFor: 'transforming'!

addFlamingBits
	"FlamingBits don't explode into other FlamingBits"

	^nil!

rotate: angle 
	"rotate the flaming bit by an angle (in radians)"

	angle isZero ifFalse: [shape := LineSegment from: (Point r: shape end r theta: shape end theta + angle)
					to: (Point r: shape start r theta: shape start theta + angle)]! !

!FlamingBit methodsFor: 'updating'!

update
	"move the receiver to its new location, darken its color, and if it's black, destroy it."

	super update.
	color := ColorValue brightness: (color brightness - (RandomNumber lessThan: 0.15) max: 0).
	color brightness = 0 ifTrue: [self destroy]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FlamingBit class
	instanceVariableNames: ''!


!FlamingBit class methodsFor: 'instance creation'!

from: startPoint to: endPoint at: aPoint velocity: v 
	"answers a new flaming bit."

	| bit midpoint |
	bit := super new initialize.
	midpoint := startPoint x + endPoint x // 2 @ (startPoint y + endPoint y // 2).
	bit shape: ((LineSegment from: startPoint - midpoint to: endPoint - midpoint)
			scaledBy: (RandomNumber between: 0.7 and: 1)).
	bit moveTo: aPoint + midpoint.
	bit velocity: v + (RandomNumber between: -16 @ -16 and: 16 @ 16).
	bit angular_speed: (RandomNumber between: bit velocity r / 20 negated and: bit velocity r / 20).
	^bit! !

Sprite subclass: #Ship
	instanceVariableNames: 'direction shipShape thrustingShape player hypercount '
	classVariableNames: 'MaxVelocity MinVelocity Radius ShipShape ShipThrustShape TurnIncrement '
	poolDictionaries: ''
	category: 'Asteroids'!
Ship comment:
'A spaceship sprite.

Instance variables:
	direction <Number> Direction (radians) in which the ship is facing.
	shipShape <Polyline> the shape used when the ship isn''t thrusting
	thrustingShape <Polyline> the shape used when the ship is thrusting
	player <Player> the player associated with this ship
	hypercount <Number> the number of update cycles before the ship comes out of hyperspace

Class Variables:
	MaxVelocity <Number> maximum allowable velocity (constant)
	MinVelocity <Number> velocity below which the velocity becomes zero (constant)
	Radius <Number> Radius of the ship (constant)
	ShipShape <OrderedCollection> Collection of points that define the shape of a ship.
	ShipThrustShape <OrderedCollection> Collection of points that define the shape of a thrusting ship'!


!Ship methodsFor: 'initialize-release'!

initialize
	"initialize the receiver"

	super initialize.
	shipShape := Polyline vertices: ShipShape copy.
	thrustingShape := Polyline vertices: ShipThrustShape copy.
	shape := shipShape.
	hypercount := 0.
	direction := -1.571.
	self rotate: -1.571! !

!Ship methodsFor: 'accessing'!

direction
	"answer the current direction of the ship"

	^direction!

ownedBy: aPlayer 
	"let aPlayer own the receiver"

	player := aPlayer!

player
	"answers the player who owns the receiver"

	^player! !

!Ship methodsFor: 'collision detection'!

isCollidingWith: aSprite 
	"returns true if the receiver is colliding with a sprite"

	| isHit |
	(aSprite isMemberOf: FlamingBit)
		ifTrue: [^false].
	(aSprite isMemberOf: Bullet)
		ifTrue: [^false].
	aSprite isVisible ifFalse: [^false].
	isHit := (shape translatedBy: location)
				regionIntersects: aSprite collisionCheckRectangle.
	isHit ifTrue: [player award: aSprite pointValue].
	^isHit! !

!Ship methodsFor: 'controls'!

fire
	"fire a shot."

	self isVisible ifTrue: [world add: (Bullet parent: self)]!

hyperspace
	"jump into hyperspace"

	self isVisible
		ifTrue: 
			[self hide.
			hypercount := 30]!

thrust
	"increase ship speed"

	self isVisible
		ifTrue: 
			[acceleration := acceleration + (Point r: 0.3 theta: direction).
			acceleration := Point r: (acceleration r max: 1.5)
						theta: acceleration theta.
			
			[shape := thrustingShape.
			(Delay forMilliseconds: 100) wait.
			shape := shipShape] fork]!

turnLeft
	"Turn the ship left"

	self isVisible
		ifTrue: 
			[direction := direction - TurnIncrement \\ 6.28318.	"mod 2 pi"
			self rotate: 0 - TurnIncrement]!

turnRight
	"Turn the ship right"

	self isVisible
		ifTrue: 
			[direction := direction + TurnIncrement \\ 6.28318.	"mod 2 pi"
			self rotate: 0 + TurnIncrement]! !

!Ship methodsFor: 'transforming'!

rotate: angle 
	"rotate the ship by an angle (in radians)"

	angle isZero
		ifFalse: 
			[1 to: shipShape vertices size
				do: 
					[:i | 
					| p |
					p := shipShape vertices.
					shipShape vertices at: i put: (Point r: (p at: i) r theta: (p at: i) theta + angle)].
			1 to: thrustingShape vertices size
				do: 
					[:i | 
					| p |
					p := thrustingShape vertices.
					thrustingShape vertices at: i put: (Point r: (p at: i) r theta: (p at: i) theta + angle)]]! !

!Ship methodsFor: 'updating'!

update
	"update the parameters of the ship"

	hypercount > 0
		ifTrue: 
			[hypercount := hypercount - 1.
			hypercount = 0
				ifTrue: 
					[self moveTo: (RandomNumber pointLessThan: Asteroids windowSize).
					self velocity: 0 @ 0.
					self acceleration: 0 @ 0.
					self unHide]]
		ifFalse: 
			[super update.
			acceleration := acceleration / 1.5.
			velocity := velocity / 1.02.
			velocity r > MaxVelocity ifTrue: [velocity := Point r: MaxVelocity theta: velocity theta].
			velocity r < MinVelocity ifTrue: [velocity := 0 @ 0]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Ship class
	instanceVariableNames: ''!


!Ship class methodsFor: 'accessing'!

radius
	"answers the radius of a ship."

	^Radius!

shipShape
	"answers the collection of points that defines a ship's shape"

	^ShipShape! !

!Ship class methodsFor: 'class initialization'!

initialize
	"set up class constants"

	Asteroids initialize.
	MaxVelocity := 80.
	MinVelocity := 0.5.
	TurnIncrement := 0.261799.
	Radius := 30 * Asteroids spriteScaleFactor.
	ShipShape := OrderedCollection new.
	ShipShape add: (Point r: Radius theta: 0).
	ShipShape add: (Point r: Radius theta: 2.356).
	ShipShape add: (Point r: Radius / 2 theta: 3.142).
	ShipShape add: (Point r: Radius theta: 3.927).
	ShipShape add: (Point r: Radius theta: 0).
	ShipThrustShape := ShipShape copy.
	ShipThrustShape add: (Point r: Radius theta: 2.356).
	ShipThrustShape add: ((Point r: Radius theta: 3)
			nearestPointOnLineFrom: (Point r: Radius theta: 2.356)
			to: (Point r: Radius / 2 theta: 3.142)).
	ShipThrustShape add: (Point r: Radius * 1.3 theta: 3.142).
	ShipThrustShape add: ((Point r: Radius theta: 3.283)
			nearestPointOnLineFrom: (Point r: Radius theta: 3.927)
			to: (Point r: Radius / 2 theta: 3.142))! !

Sprite subclass: #Bullet
	instanceVariableNames: 'parent updateCount '
	classVariableNames: 'BulletShape '
	poolDictionaries: ''
	category: 'Asteroids'!
Bullet comment:
'The bullet class.

Instance Variables:
	parent <Sprite> the sprite that created this bullet
	updateCount <Number> number of times that the update method has been called on this bullet
	
Class Variables:
	BulletShape <Polyline> the shape shared by all Bullets.'!


!Bullet methodsFor: 'initialize-release'!

initialize
	"initialize the receiver"

	super initialize.
	shape := BulletShape.
	updateCount := 0! !

!Bullet methodsFor: 'accessing'!

area
	"answers the area of the bullet"
	"answers a value that is larger than the actual area, which gives bullets extra *punch* when colliding 
	with other things."

	^100!

parent
	"answers the parent of this bullet"

	^parent!

parent: p
	"set the parent of the receiver"

	parent := p! !

!Bullet methodsFor: 'testing'!

isCollidingWith: aSprite 
	"answers true if the receiver is colliding with aSprite"

	| isHit |
	self isVisible ifFalse: [^false].
	(aSprite isMemberOf: Bullet)
		ifTrue: [aSprite parent = parent ifTrue: [^false]].
	(aSprite isMemberOf: FlamingBit)
		ifTrue: [^false].
	aSprite = parent ifTrue: [^false].
	isHit := (LineSegment from: location to: location - velocity)
				outlineIntersects: aSprite collisionCheckRectangle.
	isHit ifTrue: [(parent isKindOf: Ship)
			ifTrue: [parent player award: aSprite pointValue]].
	^isHit! !

!Bullet methodsFor: 'transforming'!

addFlamingBits
	"bullets don't leave anything around after they explode"

	^nil! !

!Bullet methodsFor: 'updating'!

update
	"update the receiver's location, etc. if the receiver has been updated enough times, it is removed 
	from the world"

	super update.
	updateCount := updateCount + 1.
	updateCount > 11 ifTrue: [self destroy]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Bullet class
	instanceVariableNames: ''!


!Bullet class methodsFor: 'instance creation'!

fromSpaceship: myCreator 
	"answers a new bullet, owned by myCreator."
	"Sometimes, depending on the player's level, the bullet will be aimed directly at the player. Otherwise, 
	the direction is random."

	| missile playerShip |
	missile := super new initialize.
	missile parent: myCreator.
	missile moveTo: myCreator location + myCreator velocity.
	missile velocity: (Point r: 35 * Asteroids spriteScaleFactor theta: (RandomNumber between: 0.0 and: 2 * 3.14159))
			+ myCreator velocity.
	myCreator world do: [:s | (s isMemberOf: Ship)
			ifTrue: [playerShip := s]].
	Object messageNotUnderstoodSignal handle: [:ex | ex return]
		do: [(RandomNumber chance: playerShip player level * 4)
				ifTrue: [missile velocity: (Point r: missile velocity r theta: (playerShip location - missile location) theta)]].
	^missile!

parent: myCreator 
	"answers a new bullet, owned by myCreator."

	| missile |
	(myCreator isKindOf: Spaceship)
		ifTrue: [^self fromSpaceship: myCreator].
	missile := super new initialize.
	missile parent: myCreator.
	missile velocity: (Point r: 35 * Asteroids spriteScaleFactor theta: myCreator direction)
			+ myCreator velocity.
	missile moveTo: (Point r: Ship radius + 10 theta: myCreator direction)
			+ myCreator location + myCreator velocity.
	^missile! !

!Bullet class methodsFor: 'class initialization'!

initialize
	"set up bullet shape constant"

	BulletShape := Polyline vertices: (Array
					with: 0 @ 0
					with: 0 @ 1
					with: 1 @ 0
					with: 1 @ 1)! !
Asteroids initialize!

DisplayManager initialize!

RandomNumber initialize!

Spaceship initialize!

Asteroid initialize!

Ship initialize!

Bullet initialize!


