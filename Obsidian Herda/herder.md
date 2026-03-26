#wiki 
*game entity*

The herder is the player character. It is the only entity players can directly control.

### Perspective
The camera follows the herder in third person, maybe sometimes shifting to first person to scan the landscape.

### Controls
The player can control the herder in the following ways:
- [[#Movement]] - move the herder around the map
- [[#Nudging]] - interact directly with a [[schaap]] to navigate the herd
- Other interactions - probably other more complex interactions with animals and the environment can be accessed through diegetic menus, this is for later.

##### Movement
Movement should feel somewhat realistic, immersive and slow (?), but not clunky. The herder can't constantly sprint and jump over everything, but movement should still be responsive and not become a source of frustration.

Implementation options:
- Regular WASD controls. No jumping. Provisional sprinting with speed buildup. Strafe controls for scooting in between sheep?
- Walking into obstacles: maybe start pushing against them or smth.

##### Nudging
The main interaction through which the herder can directly get a [[schaap]] moving. In the end the herd needs to collectively understand where they're going, but this is sheep psychology. This is about the immediate 1-on-1 schaap - herder interaction.
- A nudge reorients the schaap and refreshes the schaap's goal state.
	- This doesn't mean they will necessarily start moving

### Animation
I want some level of procedural animation to account for the complex movements between sheep and environment. this means i need poses it can blend between multidimensionally. probably. or i need to configure the fucking animation style where you move the target and it adjusts the bone rotations automatically but idk i dont fuck with that so much it always gets goofy in a way thats no longer interesting.