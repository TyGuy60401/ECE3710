# Notes for the project

Unfortunately, when I was writing the code I did not have the schematic
in front of me and I did not realize which LEDs were tied to which ends of
the output, so often when it says moving right or moving left it's actually
wrong. Unfortunately, I don't know when it is wrong, so you might need to
test each time it says what it's doing to actually know which side it's
referring to.

## commit bd1243
"I think I got the mashing problem fixed but need to check for bugs"

At this point I believe that the code for the delay loop looks good,
and I moved the manage_left_win and manage_right_win subroutines within
the delay loop after it checks the buttons so that you can't mash
to progress the loop. A side effect is that pressing a button
within the proper window no longer progress the LED immediately.
It must wait until the entire delay ends.

The only thing that still needs to be fixed is one of the windows (I
can't remember which one) does not properly increase with the variable
and the buttons can be pressed extremely early, and the direction
will change. At one point I was able to slow down the delay function
a lot and click both buttons in succession and the LED bounced
between two adjacent positions. So I think the window was increasing rather
than decreasing.
