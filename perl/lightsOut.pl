#!/usr/bin/perl
# lightsOut_input.pl ver 0.1 20151024 alexx @ cpan dot org
use strict;
#no strict "refs";
use Data::Dumper;
use feature qw/say/;

$|=1;


=head1 NAME

lightsOut.pl

=head1 VERSION

0.01

=cut

our $VERSION = 0.01;

=head1 ABSTRACT

Expects a matrix in MxN:010... format
Then solves for the game LightsOut and some variations.
Is tolerant of various forms of input; it will discover
the dimentions of the input matrix where possible.
(See test.pl for examples).

=head1 DESCRIPTION

Another LightsOut solver

=head1 OPTIONS

%opt stores the global variables
%ignore overrides %opt

=cut

my (%opt,%ignore);

=head2 ARGS

=over 8

=item B<-h> send for help (just spits out this POD by default, but we can chose something else if we like 

=back

=head3 other arguments and flags that are valid

-d -v -i[!] (value) 

=cut

for(my $args=0;$args<=(@ARGV -1);$args++){
    if ($ARGV[$args]=~m/^-+h/i){ &help; }
    elsif ($ARGV[$args] eq '-d'){ $opt{D}++; }
    elsif ($ARGV[$args] eq '-s'){ $opt{show}++; }
    elsif ($ARGV[$args] eq '-t'){ $opt{test}++; } # this should ONLY format the output to match test (still a bad idea)
    elsif ($ARGV[$args] eq '-shortest_path'){ $opt{full_search_for_shortest_path}++; }
    elsif ($ARGV[$args] eq '-on'){ $opt{turn_the_lights_on_rather_than_off}++; $opt{on}++; }
    elsif ($ARGV[$args] eq '-v'){ $opt{verbose}++;  print "Verbose output not implemented yet - try debug\n";}
    elsif ($ARGV[$args]=~m/-+i!(.+)/){ delete($ignore{$1}); }
    elsif ($ARGV[$args]=~m/-+record(.+)/){ $opt{record_data}++; }
    elsif ($ARGV[$args]=~m/-+w(ipe_home_dirs)?/){ $opt{wipe_home_dirs}++; }
    elsif ($ARGV[$args]=~m/-+i(.+)/){ $ignore{$1}=1; }
    elsif ($ARGV[$args]=~m/-+path(.+)/){ $opt{BASE_PATH} = $1; }
    elsif ($ARGV[$args]=~m/-+path/){ $args++; $opt{BASE_PATH} = $ARGV[$args]; }
    elsif ($ARGV[$args]=~m/-+dir(.+)/){ $opt{BASE_PATH} = $1; }
    elsif ($ARGV[$args] eq '-no-xml'||$ARGV[$args] eq '-no_xml'){ delete $opt{xml}; }
    elsif ($ARGV[$args] eq '-no-mkdir'||$ARGV[$args] eq '-no_mkdir'){ delete $opt{mkdir}; }
    elsif ($ARGV[$args] !~m/^-/ && -d "$ARGV[$args]"){ push @{ $opt{paths} }, $ARGV[$args] }
    else{ push @{ $opt{input} }, $ARGV[$args]; }
}


=head1 METHODS

=head3 footer

Adds the Copyright line to any output that needs it

=cut

sub footer { print "perldoc $0 \nCopyright 2011,2015 Cahiravahilla publications\n"; }

=head3 help

Just the help output

=cut

sub help {
    print `perldoc $0`;
    #print "Usage: $0\n";
    #&footer;
    exit(0);
}

##### code


sub parse_raw_str{
    my $in = shift;
    #print STDERR $in;
    #print STDERR "0";

    if($in=~m/^\d+$/){
    #print STDERR "1";
        return('1',length($in),$in);
    }elsif($in=~m/(\s?\\)/){
        my @m = split(/\s?\\/,$in);
    #print STDERR "2";
        return($#m + 1,length($m[0]),join('', @m));
    }elsif($in=~m/(\.)/){
    #print STDERR "3";
        my @m = split(/\./,$in);
        return($#m + 1,length($m[0]),join('', @m));
    }elsif($in=~m/[\{]/){
    #print STDERR "4";
        # NTS you are here doing the last valid delimiters
        #print STDERR "before $in\n";
        $in=~s/,//g;
        $in=~s/\{//g;
        $in=~s/\}$//g;
        #print STDERR "after $in\n";
        my @m = split(/\}/,$in);
        return($#m + 1,length($m[0]),join('', @m));
    }elsif($in=~m/([,\/ ])/){
    #print STDERR "4";
        #print STDERR "matrix in " . $1 . " delim' form\n";
        my @m = split(/$1/,$in);
        #print STDERR Dumper(@m);
        return($#m + 1,length($m[0]),join('', @m));
    }else{ return 'Error: unable to parse_raw ' . $in; }
}

sub parse_input {
    my $in = shift;
    my $out = shift;
    my $dimentions;
    my $str;
    if($in->[0]=~m/^(.+):(\d*)$/){
        $dimentions = $1;
        $str = $2;
        my ($w,$h);
        if($dimentions=~m/(\d+)?x(\d)?/){
            $opt{width} = $1;
            $opt{height} = $2;
            $w = $opt{width};
            $h = $opt{height};
            #print STDERR "Width: $opt{width} Height: $opt{height}\n";
            die "Error: unable to parse width or height from $in->[0]\n"
                unless($w >=1 || $h >=1);
            unless($w && $w >=1){
                $w = int( length($str) / $h );
                print STDERR "width must be: $w\n" if $opt{D}>=3;
                if( $w ne ( length($str) / $h ) ){
                    die "Error: matrix string is not an intiger multiple of $h\n";
                }
            }
            unless($h && $h >=1){
                $h = int( length($str) / $w );
                print STDERR "height must be: $h\n" if $opt{D}>=3;
                if( $h ne ( length($str) / $w ) ){
                    die "Error: matrix string is not an intiger multiple of $w\n";
                }
            }
            unless($opt{no_pad_input}){
                while ( length($str) < $w * $h){  $str .= '0'; }
            }
        }elsif( ! $opt{strict_dimentions} && $dimentions=~m/(\d+)/ ){
            $w = $1;
            $h = int( length($str) / $w );
            print STDERR "height must be: $h\n" if $opt{D}>=10;
            if( $h ne ( length($str) / $w ) ){
                die "Error: matrix string is not an intiger multiple of $w\n";
            }
        }
        print $w . 'x' . $h . ':' . $str if $out;
        return($w,$h,$str);
        
    }elsif($in->[0]=~m/[,\.\{\/]?/ || $in->[0]=~m/^\d+$/){
         my ($w,$h);
        ($w,$h,$str) =  &parse_raw_str($in->[0]);
        print $w . 'x' . $h . ':' . $str if $out;
        return($w,$h,$str);
    }elsif($in->[0]=~m/:/){
        die 'Error: ambiguous use of : as a delimiter';
    }else{
        die 'Error: unable to parse input ' . $in->[0];
    }

}

=head2 show

output in ascii the matrix

=cut

sub show {
    #print STDERR "We are showing you the output of $opt{input}\n";
    my ($w,$h,$str) = &parse_input($opt{input});
    #print STDERR "Width: $w Height: $h Matrix string: $str\n";
    my @m = split(//,$str);
    #for(my $index=0;$index<=$#m;$index++){ # not sure which is faster
    #foreach my $index (0..$#m){             # but this is less to type
    for my $index (0..$#m){             # and this is even less
        print $m[$index];
        if ( ($index + 1) % $w  == 0 && $index >=1){
            print "\n";
        }else{
           #print "  : $index $w : \n";
        }
    }
    exit;
}

=head2 output

same as &show but expects the bitwise version of the matrix

=cut

sub output {
}

# Here we are trying another approach to solving:
#  by maping out the search space and trying each and EVERY
#  combinations of buttons. It is a slow system, but it can
#  be used to brute-force locate the shortest path and
#  how many unique solutions there are for a given position

=head2 make_mask

This dynamically creates the button mask
(well it will, but for now 3x3 is hard coded
    0 => 0,1,3; 2 => 1,2,5 6=> 3,6,7 8 => 5,7,8;             #4 corners
    1 => 0,1,2,4; 3 => 0,3,4,6; 5 => 2,4,5,8; 7 => 4,6,7,8;  #4 edges
    4 => 1,3,4,5,7;                                          #1 middle

=cut

sub make_mask {

}

=head2 search_tre 

This creates and searches the tree, depth first for a solution.
It remembers the layouts that it has already seen, to prevent loops.

=cut

sub search_tree {

}

#####################################################
# This is the code that actually solves the problem #
#####################################################


=head1 MAIN solving Code

The solving engine is a direct port from
 the javascript version at
 http://www.ueda.info.waseda.ac.jp/~n-kato/lightsout/


 My work and additional code are released under the MIT Licence 1.0
 Alexx Roche, 2015
 
=cut


my ($rows,$cols,$matrix,$dime,@initial_matrix);
#($dime,$matrix) = split(/:/, $input);
#($rows,$cols) = split(/x/, $dime);


sub true{ return 1;}
sub false{ return 0;}
sub min{ my ($a,$b) = @_; return $a if($a<= $b); return $b;}
sub max{ my ($a,$b) = @_; return $a if($a>= $b); return $b;}


=head3 dm

Dump Matrix; output function

=cut

sub dm{ 
	my $m = shift;
	die "Looks like you need -help\n" unless $m->[0] ;
	my $m_rows = @{ $m};
	my $m_cols = @{ $m->[0]};
	if($opt{test}){ print "${rows}x${cols}:"; }
	for (my $row = 0; $row < $m_rows; $row++){
		for (my $col = 0; $col < $m_cols; $col++){
			print $m->[$row][$col];
		}	
		print "\n" unless($opt{test});
    }

}


# --- global variables ---

my @solution;	#This holds the solution matrix, or the "which buttons you press how many times"
my $solved_cells=0;
my $m_size; #= $rows * $cols;

=head3 unique_int_count

	This expects an ref to an array of int
	it returns the number of unique intergers

=cut

sub unique_int_count{
	my $m = shift;
	#print Dumper($m);
	my @return;
	for(my $i=0;$i < @{$m};$i++){
		$return[$m->[$i]] = 1;
	}
	return @return;
}


#   integer, number of states of a tile "the modulo that we will be working from GF(2) for LightsOut"
my $imgcount; #   integer, number of states of a tile
my @cells; #      integer[row][col], current states of tiles
#				it said [row][col] but it was storing [col][row]. I've swaped those in this code.
  
my $np; # used in the solver == $m_size+1;

=head3 init

populate @cells with the matrix

=cut

sub init {

	print "becuase we are using crazy globals we know that the matrix in linea form is: $matrix\n" if $opt{D}>=1;
	$m_size = $rows * $cols;
	$np = $m_size+1;     # count of columns of the enlarged matrix
	
	my @initial_matrix = split(//, $matrix);
	$imgcount = &unique_int_count(\@initial_matrix); #   integer, number of states of a tile
	print "im = " . @initial_matrix . " modulo: " . $imgcount . "\n" if $opt{D}>=11;

	my($rw,$cl) = (0,0);

=pod

	my $loop=0;
	for(@initial_matrix){
		$cells[$rw][$cl] = $initial_matrix[$loop];
		$cl++;
		$loop++;
		if($cl % $cols == 0){ $rw++; $cl=0;}
	}

=cut	

#=pod
	# We don't have to preserve $initial_matrix so it might 
	# be better or faster to shift
	
	while(@initial_matrix){
		$cells[$rw][$cl] = shift(@initial_matrix);
		$cl++;
		if($cl % $cols == 0){ $rw++; $cl=0;}
	}
#=cut	
} #/ sub init


# --- operation methods ---
=head3 setanscellimage

if we have to press a button, mark how many time

=cut


sub setanscellimage{
	my ($row,$col,$imgsrc) = @_;
	$solution[$row][$col] = $imgsrc;
	$solved_cells++;
	# should only need == here, but >= catches internal bugs
	if($solved_cells >= $m_size){
		print "To solve lightsOut in this state:\n" unless($opt{test});
		dm(\@cells) unless($opt{test});
		print "Press: \n" unless($opt{test});
		dm(\@solution);
	}
	#dm(\@solution) if($solved_cells >= $m_size);
}


# --- finite field algebra solver
sub modulate {
	my $x = shift;
    # returns z such that 0 <= z < imgcount and x == z (mod imgcount)
    return $x % $imgcount if($x >= 0);
    $x = (-$x) % $imgcount;
    return 0 if ($x == 0);
    return $imgcount - $x;
}

sub gcd{ # call when: x >= 0 and y >= 0
	my($x,$y) = @_;
    return $x if ($y == 0 || $x == $y);
    #if (x == y) return x;
    if ($x > $y){  $x = $x % $y;} # x < y
    while ($x > 0) {
        $y = $y % $x; # y < x
        return $x if ($y == 0);
        $x = $x % $y; # x < y
    }
    return $y;
}

sub invert{ # call when: 0 <= value < imgcount
	my $value = shift;
    # returns z such that value * z == 1 (mod imgcount), or 0 if no such z
    return $value if ($value <= 1);
    my $seed = gcd($value,$imgcount);
    return 0 if ($seed != 1);
	my($a,$b,$c,$d,$x,$y);
    $a = 1, $b = 0, $x = $value; #    invar: a * value + b * imgcount == x
    $c = 0, $d = 1, $y = $imgcount; # invar: c * value + d * imgcount == y
    while ($x > 1) {
        my $tmp = int($y / $x);
        $y -= $x * $tmp;
        $c -= $a * $tmp;
        $d -= $b * $tmp;
        $tmp = $a;  $a = $c;  $c = $tmp;
        $tmp = $b;  $b = $d;  $d = $tmp;
        $tmp = $x;  $x = $y;  $y = $tmp;
    }
    return $a;
}


# --- finite field matrix solver

my @mat;    # integer[i][j]
my @columns;   # integer[]
#my $np = $m_size+1;     # count of columns of the enlarged matrix
my $rs = 0;      # minimum rank of the matrix in sweep

sub a{ my ($i,$j)= @_; return $mat[$i][$columns[$j]]; }
sub setmat{ my ($i,$j,$val) = @_;  $mat[$i][$columns[$j]] = modulate($val); }

sub solve{
    my($col,$row);
    for (my $goal = 0; $goal < $imgcount; $goal++) {
        if (solveProblem($goal)) { # found an integer solution
            my @anscols = ();
            for (my $jk = 0; $jk < $m_size; $jk++){ $anscols[$columns[$jk]] = $jk; }
        	for (my $row = 0; $row < $rows; $row++) {
				for (my $col = 0; $col < $cols; $col++){		
					my $value;
					my $jv = $anscols[$row * $cols + $col];
					#if ($jv < $rs){ #haven't found a case where $jv >= $rs lxr
						$value = a($jv,$m_size); 
					#}else{ $value = 0; }
					setanscellimage($row,$col,$value);
				}
			}
            return true;
        }
    }
	dm(\@cells);
 	die "Has no solutions that I can see.\n" unless($opt{test});
}


sub initMatrix {  
	for (my $row = 0; $row < $rows; $row++){
		for (my $col = 0; $col < $cols; $col++){  
			my $i = $row * $cols + $col;
			my @line;
			#for (my $j = 0; $j < $m_size; $j++){ $line[$j] = '0'; }
			$line[$i] = 1;
			if ($col > 0){         $line[$i - 1]     = 1; }
			if ($row > 0){         $line[$i - $cols] = 1; }
			if ($col < $cols - 1){ $line[$i + 1]     = 1;}
			if ($row < $rows - 1){ $line[$i + $cols] = 1;}
			push @{ $mat[$i] }, @line;
		}
	}
	for (my $j = 0; $j < $np; $j++){ $columns[$j] = $j; }
}

sub solveProblem{
	my $goal = shift;
    initMatrix();
	for (my $row = 0; $row < $rows; $row++){
		for (my $col = 0; $col < $cols; $col++){
			$mat[$row * $cols + $col][$m_size] = modulate($goal - $cells[$row][$col]);
		}
	}
    return sweep();
}

sub sweep{
    for ($rs = 0; $rs < $m_size; $rs++) {
        return false unless sweepStep(); # failed in founding a solution
        last if ($rs == $m_size);
    }
    return true; # successfully found a solution
}

sub sweepStep {
    my $finished = true;
	for (my $i = $rs; $i < $m_size; $i++){
      for (my $j = $rs; $j < $m_size; $j++){
			my $aij = a($i,$j);
            $finished = false if ($aij != 0);
            my $inv = invert($aij);
            if ($inv != 0) {
                for (my $jj = $rs; $jj < $np; $jj++){
                    setmat($i,$jj, a($i,$jj) * $inv);
				}	
                doBasicSweep($i,$j);
                return true;
            }
        }
    }
    if ($finished) { # we have: 0x = b (every matrix element is 0)
        for (my $i = $rs; $i < $m_size; $i++){
			for (my $j = $m_size; $j < $np; $j++){        
                return false if (a($i,$j) != 0); # no solution since b != 0
			}
		}
        return true;    # 0x = 0 has solutions including x = 0
    }
    return false;   # failed in finding a solution
}

sub swap{
	my ($array,$x,$y) = @_;
    my $tmp  = $array->[$x];
    $array->[$x] = $array->[$y];
    $array->[$y] = $tmp;
}

sub doBasicSweep{
	my ($pivoti, $pivotj) = @_;
    if ($rs != $pivoti){ swap(\@mat,$rs,$pivoti); }
    if ($rs != $pivotj){ swap(\@columns,$rs,$pivotj); }
    for (my $i = 0; $i < $m_size; $i++) {
        if ($i != $rs) {
            my $air = a($i,$rs);
            if ($air != 0){
                for (my $j = $rs; $j < $np; $j++){
                    setmat($i,$j, a($i,$j) - a($rs,$j) * $air);
				}
			}
        }
    }
}




###################
# The main() code #
###################

if($opt{show}){
    &show($opt{input});
    exit(1);
}else{
    #&parse_input($opt{input},'out');
($rows,$cols,$matrix) = &parse_input($opt{input});
    print "We are looking at $rows x $cols : $matrix \n" if $opt{D}>=11;
    &init();
    &solve() || die "We have no solutions today ;-(\n";
}


exit(0);


##### end of code

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests

=head1 SEE ALSO

L<http://www.ueda.info.waseda.ac.jp/~n-kato/lightsout/>

=head1 MAINTAINER

Alexx

=head1 AUTHOR

C<N-Kato> <n-kato@ueda.info.waseda.ac.jp>

C<Alexx Roche> <alexx at cpan dot org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alexx Roche, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: Eclipse Public License, Version 1.0 ; 
 MIT Licence, Version 1.0 and
 the GNU Lesser General Public License as published 
by the Free Software Foundation; or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

print "Done that\n" if $opt{verbose}>=1;
exit(0);
__END__

<h3>How does it work?</h3>
<p>
In case of 6x5 grid and two colors, a bit vector x of length 30
can contain an answer.
Each element of the vector corresponds to a field cell
and its bit value expresses whether the cell should be pressed
or not.
A board state can also be stated as a bit vector b of length n = 30
where each element expresses whether the cell is lit or not.
</p><p>
Pressing a cell inverts the state of some cells,
which is expressed as a 30-vector [a1j ... anj] where each bit aij
contains whether the cell i is inverted or not by pressing the cell j.
The whole effect of pressing the cells as specified by the answer vector x
is determined by, for each cell i, whether the times of inversions at i
is odd or even.  This can be expressed as (ai1*x1 + ... + ain*xn) mod 2.
</p><p>
The puzzle is now stated as a problem to find an x such that
</p><pre>  (ai1*x1 + ... + ain*xn + bi) mod 2 = c
</pre>
for all i with some final lightness c, or equivalently:
<pre>  (ai1*x1 + ... + ain*xn) mod 2 = (c - bi) mod 2
</pre>
This can be solved with Gaussian elimination
since mod 2 effectively distributes over anything.
<p>
---Using finite field linear algebra, this method is stated as follows:
</p><pre>  A x = c - b
    x = A^<sup>{-1}</sup>(c - b)
</pre>
Although A^<sup>{-1}</sup> can be computed in advance
for better performance,
the script in this page computes A x = c - b every time.


</body></html>

C1G
