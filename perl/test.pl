#!/usr/bin/env perl
# name_of_script ver 0.1 YYYYMMDD authors@email.address
use strict;
no strict "refs";
use Data::Dumper;

use Test::More;


=head1 NAME

name_of_script

=head1 VERSION

0.01

=cut

our $VERSION = 0.01;

=head1 ABSTRACT

A synopsis of the new script

=head1 DESCRIPTION

Provide an overview of functionality and purpose of
this script

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
    elsif ($ARGV[$args] eq '-o'){ $opt{no_test_inputs}++;  } # just test outputs
    elsif ($ARGV[$args] eq '-v'){ $opt{verbose}++;  print "Verbose output not implemented yet - try debug\n";}
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

sub footer { print "perldoc $0 \nCopyright 2011 Cahiravahilla publications\n"; }

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

#my $script = 'lightsOut_input.pl';
my $script = 'lightsOut.pl -t';
my $test_input = [
 # delimeted strings
    { input => '100,000,000',   output => '3x3:101001110' },
    { input => '100:000:000',   output => 'Error: ambiguous use of : as a delimiter', type => 'isnt', name => 'ambiguous use of : as a delimiter' },
    { input => '100.000.000',   output => '3x3:101001110' },
    { input => '100/000/000',   output => '3x3:101001110' },
    {input =>'100 \000 \000 \\',output => '3x3:101001110' },
   {input =>'{100},{000},{000}',output => '3x3:101001110' },
    { input =>'{100}{000}{000}',output => '3x3:101001110' },
    { input => '100000000',     output => '1x9:011011011', name=>"test 8" },
 # WxH:full str
    { input => '3x3:100000000', output => '3x3:101001110' },
 # xH:full str
    { input => 'x3:100000000',  output => '3x3:101001110' },
 # Wx:full str
    { input => '3x:100000000',  output => '3x3:101001110' },
    { input => '3:100000000',   output => '3x3:101001110' },
 # WxH:partial string
    { input => '3x3:1',         output => '3x3:101001110' },
 # Error
    { input => '3:123', output => '1x3:123', type => 'isnt', name => '1x3:123'},
    { input => '2x3:1', output => '2x3:100000', type => 'isnt', name => 'unsolveable'},

# other standard tests

    { input => '3x3:011001000',         output => '3x3:001000000', name=>'top right' },
    { input => '3x3:110100000',         output => '3x3:100000000' , name=>'top left'},
    { input => '3x3:211110220',         output => '3x3:221002010' , name=>'modulo 3'},
    { input => '3x3:222222222',         output => '3x3:020222020' , name=>'all the 2s'},
    { input => '2x6:101010101011',      output => '2x6:000000101010' , name=>'rectangular'},
    { input => '3x3:123456789', output => '3x3:535159575', name=>'mod 10'}, # this is a limit of the program: it can't deal with lights that have more than 10 states
# actual lightsOut board
    { input => '5:1111111111111111111111111',      output => '5x5:0110101110001111101111000' , name=>'original LightsOut'},
];

unless( $opt{no_test_inputs} ){

foreach my $t (@{ $test_input }){

   # print Dumper($t) . "\n";
    #print  "Input: " . $t->{input} . "\t should producte: \t" . $t->{output} . "\n";
    if("$t->{input}"=~m/-/){
        ok (`./$script $t->{input}` eq "$t->{output}", 'Input: ' .  $t->{input});
        #print  "Input: " . $t->{input} . "\t should producte: \t" . $t->{output} . "\n";
        #print "and it ACTUALLY produces:\n";
        #print "`./$script $t->{input}`";
        #print `./$script $t->{input}`;
        #print " THAT\n";
    }else{
        if($t->{type} && $t->{type} eq 'isnt'){
            isnt (`./$script '$t->{input}'` eq "$t->{output}", 'Input: ' .  $t->{input}, $t->{name});
        }else{
            ok (`./$script '$t->{input}'` eq "$t->{output}", 'Input: ' .  $t->{input});
        }
    }
}

}

my $test_output = [
    { input => '-s 3:123', output => "123\n" },
    { input => '-s 100,000,000',   output => "100\n000\n000\n" },
    { input => '-s 3x3:1',   output => "100\n000\n000\n", type => 'ok', name => 'compressed notation' },
];

unless ( $opt{no_test_outputs} ){

foreach my $t (@{ $test_output }){
    if("$t->{input}"=~m/-/){
        if($t->{type} && $t->{type} eq 'isnt'){
            isnt (`./$script $t->{input}` eq "$t->{output}", 'Input: ' .  $t->{input}, $t->{name});
        }else{ 
            ok (`./$script $t->{input}` eq "$t->{output}", 'Input: ' .  $t->{input});
        }
    }
}

}



   done_testing();



##### end of code

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests

=head1 SEE ALSO

#L<My::Modules>

=head1 MAINTAINER

is the AUTHOR

=head1 AUTHOR

Alexx Roche, C<< <notice-dev at alexx.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alexx Roche, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: Eclipse Public License, Version 1.0 ; 
 the GNU Lesser General Public License as published 
by the Free Software Foundation; or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

print "Done that\n" if $opt{verbose}>=1;
exit(0);
__END__

# __END__ is usally only used if we are going to have POD after the code
