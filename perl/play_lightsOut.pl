#!/usr/bin/env perl
# play_lightsOut.pl ver 0.01 20150309 notice-dev at alexx dot net
use strict;
no strict "refs";
use Math::BigInt only => 'GMP';
$|=1;

=head1 NAME

play_lightsOut.pl

=head1 VERSION

0.01

=cut

our $VERSION = 0.01;

# copyright 

our $copyright = 'Copyright 2015 Alexx Roche, MIT Licence 1.0';

=head1 ABSTRACT

Play the game LightsOut

=head1 DESCRIPTION

This is a puzzle-game where you want to turn the lights out.
Each lamp that is lit is represented by "o" and each one that
is dark is represented by "x" The tricky part is that any
lamp can be toggled at any time, but the imediate orthagonal 
neighbours will also toggle. This means that each move will
change between 3 and 5 lamps; 3x3 is the default, but if that
is too easy you can try 4x4 or 5x5

=head1 OPTIONS

%opt stores the global variables

=cut

my %opt=(x=>3);
#my $initial = 1 << ($p);
my $initial = 0;

=head2 ARGS

=over 8

=item B<-h> send for help

=item B<-d> increment the debug level

=item B<-b>(1,5,9,..) Set which lamps are initially on.  Try -b1,5,9

=item B<-i>(0..) Set the initial board configuartion.  Try -i273

=item B<-s> Solve the game, (optionally with a board configuration).

=back

=cut

for(my $args=0;$args<=(@ARGV -1);$args++){
    if ($ARGV[$args]=~m/^-+h/i){ &help; }
    elsif ($ARGV[$args] eq '-d'){ $opt{D}++; }
    elsif ($ARGV[$args] eq '-s'){ $opt{solve}++; }
    elsif ($ARGV[$args] eq '--display_board'){ $opt{display_board}++; }
    elsif ($ARGV[$args]=~m/^\d+$/){ $opt{x} = $ARGV[$args]; }
    elsif ($ARGV[$args]=~m/^-+V/i){ die "$0 $VERSION, $copyright\n"; exit; }
    elsif ($ARGV[$args]=~m/^-+x(\d+)$/){ $opt{x} = $1; }
    elsif ($ARGV[$args]=~m/^-+x$/){ $args++; $opt{x} = $ARGV[$args]; }
    elsif ($ARGV[$args]=~m/^-+y(\d+)$/){ $opt{y} = $1; }
    elsif ($ARGV[$args]=~m/^-+y$/){ $args++; $opt{y} = $ARGV[$args]; }
    elsif ($ARGV[$args]=~m/^-+i(\d+)$/){ $initial = $1; }
    elsif ($ARGV[$args]=~m/^-+i$/){ $args++; $initial = $ARGV[$args]; }
    elsif ($ARGV[$args]=~m/^-+b((\d+,)*\d+)$/){ $opt{begin_with_these_board_lamps_on} = $1; }
    elsif ($ARGV[$args]=~m/^-+b$/){ $args++; if ($ARGV[$args]=~m/((\d+,)*\d+)$/){ $opt{begin_with_these_board_lamps_on} = $1; } }
    else{ die "Unknown flag"; }
}

sub help {
 die "Usage: $0 [-h|-d|-s] [board_width, i.e. 1..9)
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
    q quits
$copyright
";
}

if($opt{begin_with_these_board_lamps_on}){
    # We have to calculate the starting lamps bits
    my @lit = split(",",$opt{begin_with_these_board_lamps_on});
    foreach my $on (@lit){
        $initial = $initial|1<<$on-1;
    }
}

# We make the board square by default.

unless($opt{y}){
    $opt{y} = $opt{x};
}
my $p = $opt{x}*$opt{y};

# Fill the board, unless the user has already.
unless($initial){
    for (my $n=0; $n < $p; $n++){
        $initial += 1 << $n;
    }
}

# an array for labels for the lamps, so that the
# user can indicate which one they want toggled
my @full;
if($p<=62){
    #@full = (('A'..'Z'),('a'..'z'));
    @full = (1..9,'A'..'Z','a'..'z',0);
   print "We have $p lamps, which we will name from the " . @full . " labels, and call them: " if $opt{D}>=20;
}elsif($p<= 676){
    @full = ('aa'..'ZZ');
}elsif($p<= 17576){
    @full = ('aaa'...'zzz');
}else{
    print "That's a lot of lamps... going to take a really long time\n You should use a real language like Haskell or C\n";
    exit;
}
my @r; 
#push @r, @full[0..($p-1)]; # To use this we will have to add a key from @r back to {I think it is the @mask index}
push @r, (1..$p);
#push @r, @{(1..$p)}[1..$p];

# this converts a bitwise mask back into the lamp name
my %move_index; 

=head2 create_board

    A little overloaded, (but in a good way?)
    This creates the ASCII board for display
    but more importanly it also populates the 
    array-of-arrays @aa so that the mask can
    be generated programatically.

=cut

sub create_board {
    my $initial = shift;
    my $ah = shift ||undef; # array_handel
    #my @aa = $$ah;
    my $board='';
    my @c;
    for (my $nn=0; $nn < $p; $nn++){
        $c[$nn] = ($initial & (1<<$nn)) ? 'o' : 'x';
    }

    for(my $row=0; $row<$opt{y}; $row++){
        my $offset= (($row*$opt{x})-($row));
        if($offset<=0){ $offset=0;}
        $board .= sprintf("\t");
        for(my $col=0; $col<$opt{x}; $col++){
            $board .= sprintf("%s ", $c[$col+$row+$offset]);
        }
        $board .= sprintf("\t");
        for(my $col=0; $col<$opt{x}; $col++){
            if($p<10){
                $board .= sprintf("%s ", $r[$col+$row+$offset]);
            }elsif($p<100){
                $board .= sprintf("%2d ", $r[$col+$row+$offset]);
            }elsif($p<1000){
                $board .= sprintf("%3d ", $r[$col+$row+$offset]);
            }elsif($p<10000){
                $board .= sprintf("%4d ", $r[$col+$row+$offset]);
            }
        }
        if($ah != undef){
            for(my $col=0; $col<$opt{x}; $col++){
                print " \tsetting $row,$col = " if $opt{D}>=10;
                print 1 << ($col+$row+$offset) if $opt{D}>=10;
                #$ah->[$row][$col] = (1 << ($col+$row+$offset)); # useful, the actual bitwise values
                $ah->[$row][$col] = ($col+$row+$offset+1);
            }
        }
        print "\n" if $opt{D}>=10;
        $board .= sprintf("\n");
    }
    return $board;
}


=head2 snooze

like sleep but faster

=cut

sub snooze {
    my $button = shift | 0.5;
    select undef,undef,undef,$button;
}

=head2 display

This is a mess, but thanks to 

system("clear"); 

it functions. The original idea was to issue the right number of backspaces
to delete the previous display and comments and then print the new display.


=cut

sub display {
    my $board = shift;
    my $no_clear = shift || system("clear");
    # we need to know how large the previous output was
    # remove the previous output
    if($opt{output_size} && !$no_clear){
        #print "Deleting $opt{output_size} characters\n";
       # &snooze;
        for ( my $i=1; $i<$opt{output_size}*$opt{x}*$opt{y}; $i++){
            print "\b";
            #print "\r\b";
            # not enough print "\b";
            #print "\b\b\b\b\b\b\b\b\b\b";
            #print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";  #  good with "So far..." but too much
            # too much print "\b\b\b\b\b\b\r";
            #print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";
        }
        #    print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";
        #    print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";
        #    print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";
        #    print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";
        #    print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";
        #    print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";
    }
    # print the new output
    #print "So far we have >>" . $. . "<< output\n";
    my $show = &create_board($board) . "\n";
    $opt{output_size} = length($show);
    print $show;
    #print &create_board($board) . "\n";
}

# we know that there are $opt{x}*$opt{y}  lamps 
use Data::Dumper;
my @aa; # array of arrays (2 dimentional representation
&create_board($initial,\@aa);
#print Dumper(\@aa);

if($opt{display_board}){
    &display($initial,'no_clear');
    exit;
}

my @mask=();

# yuck! why create this by hand - humans make mistakes... and irony ;-)
#@mask = (
#1<<0|1<<1|1<<3,      1<<0|1<<1|1<<2|1<<4,       1<<1|1<<2|1<<5,
#1<<0|1<<3|1<<4|1<<6, 1<<1|1<<3|1<<4|1<<5|1<<7,  1<<2|1<<4|1<<5|1<<8,
#1<<3|1<<6|1<<7,      1<<4|1<<6|1<<7|1<<8,       1<<5|1<<7|1<<8,
#);
#print Dumper(\@mask);
#print join(",", @mask) . "\n";

=head2 mk_mask

Programatically create the mask

=cut

sub mk_mask {
   for(my $m=0;$m<$p;$m++){ #for each location on the board
        $mask[$m] = 1<<$m; # center
        my $x = int($m/$opt{x});
        my $y = $m-($opt{x}*$x);
        if($y-1>=0){ $mask[$m] = $mask[$m]|1<<($aa[$x][$y-1])-1; }#above
        if($y+1<$opt{y}){ $mask[$m] = $mask[$m]|1<<($aa[$x][$y+1])-1; }#below
        if($x-1>=0){ $mask[$m] = $mask[$m]|1<<($aa[$x-1][$y])-1; }#left
        if($x+1<$opt{x}){ $mask[$m] = $mask[$m]|1<<($aa[$x+1][$y])-1; }#right
        $move_index{$mask[$m]} = $m+1;
   } 
}
&mk_mask($initial); 

print join(",", @mask) . "\n" if $opt{D}>=11;
#print Dumper(\@mask);

sub main {
    my $board = $initial;
    #while($board>(1<<$p)){
    while($board){
        &display($board);
        print "Welcome. Please select a number between 1..9: ";
        my $move=0;
        while(1){
            $move = <STDIN>; chomp($move);
            #last if $move=~m/^[1|2|3|4|5|6|7|8|9]$/;
            if($move=~m/^(\d+,)+\d+$/){ # this has the bug that it will accept numbers that are outside of the board
                my @moves = split(",", $move);
                print "You have entered: " . @moves . "\n";
                foreach my $mc (@moves){ #move chain
                    print "$mc,";
                    if($mask[${mc}-1]){
                        $board = $board ^ ($mask[${mc}-1]);
                        push @{ $opt{moves} }, $mc;
                    }else{
                        die "$mc is not a known location on this board\n";
                    }
                }
                last;
            }
            push @{ $opt{moves} }, $move;
            last if $move=~m/^\d+$/ && $move <= $p;
            pop(@{ $opt{moves}});
            if ($move=~m/^r$/){
                 $board = $initial;
                    print "\b";
                 last;
            }elsif ($move=~m/^d$/){
                print "{ \"$opt{x},$opt{y}(" . $initial . ")\": [" . join(",", @{ $opt{moves} }) . "] }";
            }elsif ($move=~m/^q$/){
                exit;
            }else{
                print " ($move) HAS to be A number between ONE and $p";
            }
        }
        next if $move!~m/^\d+$/; # for CSV we have already played
        # here we "make" the move;
        if($mask[${move}-1]){
            $board = $board ^ ($mask[${move}-1]);
        }else{
            print "ERROR: no mask for $move\n";
            snooze(5);
            #$board = $board ^ (1 << ($move-1));
        }
        
    }
    &display($board);
    print "CoNgRaTuLaTiOnS - you won $opt{x},$opt{y}(" . $initial . "): with " . join(",", @{ $opt{moves} }) . "\n";
}

=head1 solve

Brute-force: recurse through each mask searching the tree for a solution and backing off
    if we meet a board that has already been seen.
    
We should probably rotate and reflect the board to prune the symetrical solutions.

=cut

my %t; # tested
sub solve {
    my $this_board = shift;
    for my $m (@mask){
        my $this_move = $this_board ^ $m;
        next if ($t{$this_move});
        $t{$this_move}++;
        print "playing $move_index{$m} produces\n" if $opt{D}>=2;
        select undef, undef, undef, 0.52 if $opt{D}>=3;
        &display($this_move,'no_clear') if $opt{D}>=2;
        select undef, undef, undef, 0.52 if $opt{D}>=3;
        if($this_move<=0){
            print "RECORDING $move_index{$m} into the move list\n";
            unshift @{ $opt{moves} }, $move_index{$m};
            return 0;
        }else{
            &display($this_board,'no_clear') if $opt{D}>=4;
            select undef, undef, undef, 0.52 if $opt{D}>=3;
            if(&solve($this_move)<=0){
                unshift @{ $opt{moves} }, $move_index{$m};
                return 0;
            }else{
                return $this_move;
            }
        }
    }
}

if($opt{solve}){
    my $this_board = $initial;
    $t{$this_board}++;
    print "Starting with:\n";
        &display($this_board,'no_clear');
    print "========================================================================\n";
            select undef, undef, undef, 0.52 if $opt{D}>=1;
    if(&solve($this_board)){
        print "No solution found for \n";
        &display($this_board,'no_clear');
    }else{
        print "CoNgRaTuLaTiOnS - you won $opt{x},$opt{y}(" . $initial . "): with " . join(",", @{ $opt{moves} }) . "\n";
    }
}else{
    &main;
}

=head2 Notation

x[,|x]y(initial board lamps|all_of_them): (move,)*(move)?

so 9x9() means a nine by nine board with all of the lamps initially lit.
3,3(1) 3x3 with just the top left lit.

=head1 BUGS AND LIMITATIONS

B1. 
Boards larger than 8x8 toggle the wrong lamps. e.g. 9x9(): 1, spuriously
toggles lamps 65,66,74 (as if 65 were a top left corner as well. 
Not sure if this is a 
mask issue, (probably not) or a problem with the logic (probably.)

(Am I abusing Math::BigInt or GMP?)

Running play_lightsOut.pl 20 and then pressing 5 shows that the
correct lamp, (and its left,right and below neighbours are toggeled in a T
shape); but then the same T-shape pattern is ALSO toggled at other locations,
every 64 lamps. So the game is playing 5,69,133,197,261,325,389 (rather than just 5).

B2../play_lightsOut.pl '{ "3,2(63)": [5,1,3,4,1,5] }'
This produces a cleared board, that is not considered as a solution.
You can demonstrate the error with
./play_lightsOut.pl -y2
and pressing 5  - the last lamp does not toggle - this feels like a mask issue.

L1. moves on boards larger than 10x10 (and certainly on ones larger than 20x20)
take a significate length of time to re-calculate the board.
Removing the overloading of &create_board; with the creation of &show_board;
will improve things.

other than that...

 There are no known problems with this script. The initial board should 
probably be a CSV of lamps that should be toggled OFF, as the default is
to have them all on; but it is far easier to toggle lights on, from how
the oard is crated, with:  -b 1,5,9 

=head1 TODO

./play_lightsOut.pl '{ "3,2(63)": [5,1,3,4,1,5] }'

should set up a 3x2 board with all of the lamps lit and play the initial moves
5,1,3,4,1,5. If it is a solution it should exit as if the player had played.

-n no-clear 

-api json output


Please fork and implement and feature requests, or porting to other languages

=head1 SEE ALSO

Phil J Taylor's Peg solitair code, (that was an indirect inspiration for this code).
#L<http://www.planet-source-code.com/vb/scripts/ShowCode.asp?txtCodeId=6966&lngWId=3>

=head1 MAINTAINER

is the AUTHOR

=head1 AUTHOR

C<Alexx Roche> <alexx at cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Alexx Roche, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: MIT License, Version 1.0 ; 
 or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

__END__

# So how do we programatically find 
 %solutions = (
    1x1 => [1],
    2x2 => [1,2,3,4],[1,2,1,3,1,2,1,4,1,2],
    3x3 => [1,3,7,9,5],[5,1,3,7,9]),
    4x4 => [1,16,13,10,15,5,1,16,7,3,4,8],
    XxY =>
    ...
 ); 

#and avoid the valid, but useless

    3x3 => [1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,6,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,7,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,6,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,8,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,6,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,7,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,6,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,9,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,6,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,7,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,6,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,8,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1]

$solutions{2x2][1] is a sympton of the problem of a depth first search

# without a brute force, (pruned) search of the tree?
# Is there a system for clearing a square patch within an infinite board?
# Is there a structual method as there is with creating an {odd}x{odd} magic square ?
#  - surely we can tile a surface with "+","T","˩" shaped pieces, (that can rotate.)



––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
################################ Research ##############################
––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
Found this interesting output:

./play_lightsOut.pl -y2 -s
Starting with:
        o o o   1 2 3 
        o o o   4 5 6 

========================================================================
CoNgRaTuLaTiOnS - you won 3,2(63): with 1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1
./play_lightsOut.pl -x2 -y3 -s
Starting with:
        o o     1 2 
        o o     3 4 
        o o     5 6 

========================================================================
CoNgRaTuLaTiOnS - you won 2,3(63): with 1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1

??? Is this true? << was my eloquent note on the subject.

Some of the questions that this produces:
    1. Is this true? Are these universal solutions; a skelliton-key for 2x3 and 3x2 ?
    2. Are there other, (hopefully shorter solutions) for 2x3 that are also valid for 3x2 ?
    3. Can this type of solution be reduced to an equation for XxY ?

after all 1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1 with the addition of ,3,7,9,1 is a valid solution for 3x3
(so effectively "1,2,1,3,1,2,1,4,1,2,1,3,1,2,1,5,1,2,1,3,1,2,1,4,1,2,1,3,1,2,1" = 5 for 3x3 ;-)
 - sort of a "and this is the number you first thought of" type thing.
