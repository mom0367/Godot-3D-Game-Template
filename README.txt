(This project is still a heavy work-in-progress, expect missing features and breaking changes)

Multipurpose character controller and game template for 3D games that involve moving a character body around, hopefully with more features than you actually need.

Controller Features:
	* Third and first person, with two ways of moving in third person
	* Keyboard and Controller support (No mobile as of now)
	* Basic character movement (walking, sprinting, crouching, swimming) with a large amount of included adjustable variables.
	* Animated and modeled characters (Credit to the wonderful people working on Mesh2Motion)
	* Material-based movement sound system with included effects and materials
	* Basic water logic for player and movement sounds
	* Head bobbing (Can be disabled)

Additional notes:
	
	* There is not currently a viewmodel for the player in first-person, the default model/animations will cause clipping.
	
	* Moving folders might break things as of now, especially if it's footstep sound related.
	

(NOT IMPLEMENTED) Future plans:
	
	High priority:
		* Basic interaction system
		* Footstep particle support
		* Coyote time
		
	* Medium priority:
		* Sliding, wallrunning, climbing/mantling
		* More included material sounds
		
	Low priority:
		* Procedural animations
		* Original player model
		
Known bugs:
	* Movement sounds don't play sometimes
	* Zooming camera out on controller behaves oddly

For use with the Godot engine, not officially related to Godot or any of its creators of course.
