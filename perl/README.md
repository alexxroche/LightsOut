Usage: ./play_lightsOut.pl [-h|-d|-s] [board_width, i.e. 1..9)
    -h this help message
    -d incement debug
    -s solve the game
    --display_board   just display the board with the given settings 
    -V version
  You can set the initial board one of two ways:
    -b begin,with,these,board,lamps,lit,at,the,begining
    OR
    -i {initial bitmask to set}


   During play [1..|2,1,3|r|q]
    you can enter single moves or a
    chain of CSV moves are acceptale i.e. 1,2,3,4

    r resets the board
    d displays the existing internals
    q quits
Copyright 2015 Alexx Roche, MIT Licence 1.0

