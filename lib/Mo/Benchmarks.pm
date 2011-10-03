##
# name:      Mo::Benchmarks
# abstract:  Benchmarks for Moose Family Modules
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

use 5.010;

use Mouse 0.93 ();
use MouseX::App::Cmd 0.08 ();

#------------------------------------------------------------------------------#
package Mo::Benchmarks;

our $VERSION = '0.10';

#------------------------------------------------------------------------------#
package Mo::Benchmarks::Command;
use App::Cmd::Setup -command;
use Mouse;
extends 'MouseX::App::Cmd::Command';

sub validate_args {}

# Semi-brutal hack to suppress extra options I don't care about.
around usage => sub {
    my $orig = shift;
    my $self = shift;
    my $opts = $self->{usage}->{options};
    @$opts = grep { $_->{name} ne 'help' } @$opts;
    return $self->$orig(@_);
};

#-----------------------------------------------------------------------------#
package Mo::Benchmarks;
use App::Cmd::Setup -app;
use Mouse;
extends 'MouseX::App::Cmd';

use Module::Pluggable
  require     => 1,
  search_path => [ 'Mo::Benchmarks::Command' ];
Mo::Benchmarks->plugins;

#------------------------------------------------------------------------------#
package Mo::Benchmarks::Command::constructor;
Mo::Benchmarks->import( -command );
use Mouse;
extends 'Mo::Benchmarks::Command';

use Benchmark ':all';

use constant abstract => 'Run constructor benchmarks';
use constant usage_desc =>
    'mo-benchmarks constructor --count=1000000 Moose Mouse Moo Mo';

has count => (
    is => 'ro',
    isa => 'Num',
    documentation => 'Number of times to run a test',
);

sub execute {
    my ($self, $opt, $args) = @_;
    my @mo = map lc, grep !/^--/, @$args;
    @mo = qw'mo moo mouse moose' unless @mo;
    my $tests = {
        map {
            my $t = $_;
            my $l = lc($t);
            my $m =
            eval <<"...";
package $l;
use $t;
has good => (is => 'ro');
has bad => (is => 'ro');
has ugly => (is => 'rw');
$l->new(good => 'Perl', bad => 'Python', ugly => 'Ruby');
...
            my $v = do { no strict 'refs'; ${$t."::VERSION"} };
            ($l => [ "$t $v" =>
                sub {
#                     my $m =
                    $l->new(good => 'Perl', bad => 'Python', ugly => 'Ruby');
#                     $m->good;
#                     $m->bad;
#                     $m->ugly;
#                     $m->ugly('Bunny');
                }
            ])
        } qw(Mo Moo Mouse Moose)
    };

    my $count = $self->count || 1000;
    my $num = 1;
    timethese($count, {
        map {
            (
                $num++ . ") $_->[0]",
                $_->[1]
            )
        } map $tests->{$_}, @mo
    });
}

#------------------------------------------------------------------------------#
package Mo::Benchmarks::Command;

# Common subroutines:

1;

=head1 SYNOPSIS

    > mo-benchmarks help
    > mo-benchmarks constructor --count=1000000 Mo Moo Mouse Moose

=head1 DESCRIPTION

This tool lets you can various precanned sets of benchmarking tests, and
compare the performance of Moose family implementations. Works with L<Moose>,
L<Mouse>, L<Moo> and L<Mo>.

=head1 TESTS

Mo::Benchmarks has a bunch of test sets and options for them. Each set has a
name that is a L<mo-benchmarks> subcommand.

The general command usage is:

    mo-benchmarks test-set-name --count=number Moxxx-names-list

=over

=item constructor

This test constructs a Moxxx object.

=item get

This test does a get operation on a readonly accessor.

=back

=head1 CONJECTURE

Here are some things you should know when comparing L<Moose>, L<Mouse>, L<Moo>
and L<Mo>.

=head2 Moose

...

=head2 Mouse

...

=head2 Moo

...

=head2 Mo

...

=cut

__DATA__
# From http://blogs.perl.org/users/michael_g_schwern/2011/03/and-the-fastest-oo-accessor-is.html

#!/usr/bin/env perl

use strict;
use warnings;

use Carp;

BEGIN {
     # uncomment to test pure Perl Mouse
#    $ENV{MOUSE_PUREPERL} = 1;
}

# ...........hash...............

my $hash = {};
sub hash_nc {
    $hash->{bar} = 32;
    my $x = $hash->{bar};
}


# ...........hash with check...............

my $hash_check = {};
sub hash {
    my $arg = 32;
    croak "we take an integer" unless defined $arg and $arg =~ /^[+-]?\d+$/;
    $hash_check->{bar} = $arg;
    my $x = $hash_check->{bar};
}


# ...........by hand..............
{
    package Foo::Manual::NoChecks;
    sub new { bless {} => shift }
    sub bar {
        my $self = shift;
        return $self->{bar} unless @_;
        $self->{bar} = shift;
    }
}
my $manual_nc = Foo::Manual::NoChecks->new;
sub manual_nc {
    $manual_nc->bar(32);
    my $x = $manual_nc->bar;
}


# ...........by hand with checks..............
{
    package Foo::Manual;
    use Carp;

    sub new { bless {} => shift }
    sub bar {
        my $self = shift;
        if( @_ ) {
            # Simulate argument checking
            my $arg = shift;
            croak "we take an integer" unless defined $arg and $arg =~ /^[+-]?\d+$/;
            $self->{bar} = $arg;
        }
        return $self->{bar};
    }
}
my $manual = Foo::Manual->new;
sub manual {
    $manual->bar(32);
    my $x = $manual->bar;
}


#.............Mouse.............
{
    package Foo::Mouse;
    use Mouse;
    has bar => (is => 'rw', isa => "Int");
    __PACKAGE__->meta->make_immutable;
}
my $mouse = Foo::Mouse->new;
sub mouse {
    $mouse->bar(32);
    my $x = $mouse->bar;
}


#............Moose............
{
    package Foo::Moose;
    use Moose;
    has bar => (is => 'rw', isa => "Int");
    __PACKAGE__->meta->make_immutable;
}
my $moose = Foo::Moose->new;
sub moose {
    $moose->bar(32);
    my $x = $moose->bar;
}


#.............Moo...........
{
    package Foo::Moo;
    use Moo;
    has bar => (is => 'rw', isa => sub { $_[0] =~ /^[+-]?\d+$/ });
}
my $moo = Foo::Moo->new;
sub moo {
    $moo->bar(32);
    my $x = $moo->bar;
}


#........... Moo using Sub::Quote..............
{
    package Foo::Moo::QS;
    use Moo;
    use Sub::Quote;
    has bar => (is => 'rw', isa => quote_sub q{ $_[0] =~ /^[+-]?\d+$/ });
}
my $mooqs = Foo::Moo::QS->new;
sub mooqs {
    $mooqs->bar(32);
    my $x = $mooqs->bar;
}


#............Object::Tiny..............
{
    package Foo::Object::Tiny;
    use Object::Tiny qw(bar);
}
my $ot = Foo::Object::Tiny->new( bar => 32 );
sub ot {
    my $x = $ot->bar;
}


#............Object::Tiny::XS..............
{
    package Foo::Object::Tiny::XS;
    use Object::Tiny::XS qw(bar);
}
my $otxs = Foo::Object::Tiny::XS->new(bar => 32);
sub otxs {
    my $x = $otxs->bar;
}


use Benchmark 'timethese';

print "Testing Perl $], Moose $Moose::VERSION, Mouse $Mouse::VERSION, Moo $Moo::VERSION\n";
timethese(
    6_000_000,
    {
#        Moose                   => \&moose,
        Mouse                   => \&mouse,
        manual                  => \&manual,
        "manual, no check"      => \&manual_nc,
        'hash, no check'        => \&hash_nc,
        hash                    => \&hash,
#        Moo                     => \&moo,
#        "Moo w/quote_sub"       => \&mooqs,
        "Object::Tiny"          => \&ot,
        "Object::Tiny::XS"      => \&otxs,
    }
);


__END__
Testing Perl 5.012002, Moose 1.24, Mouse 0.91, Moo 0.009007, Object::Tiny 1.08, Object::Tiny::XS 1.01
Benchmark: timing 6000000 iterations of Moo, Moo w/quote_sub, Moose, Mouse, Object::Tiny, Object::Tiny::XS, hash, manual, manual with no checks...
Object::Tiny::XS:  1 secs ( 1.20 usr + -0.01 sys =  1.19 CPU) @ 5042016.81/s
hash, no check  :  3 secs ( 1.86 usr +  0.01 sys =  1.87 CPU) @ 3208556.15/s
Mouse           :  3 secs ( 3.66 usr +  0.00 sys =  3.66 CPU) @ 1639344.26/s
Object::Tiny    :  3 secs ( 3.80 usr +  0.00 sys =  3.80 CPU) @ 1578947.37/s
hash            :  5 secs ( 5.53 usr +  0.01 sys =  5.54 CPU) @ 1083032.49/s
manual, no check:  9 secs ( 9.11 usr +  0.02 sys =  9.13 CPU) @  657174.15/s
Moo             : 17 secs (17.37 usr +  0.03 sys = 17.40 CPU) @  344827.59/s
manual          : 17 secs (17.89 usr +  0.02 sys = 17.91 CPU) @  335008.38/s
Mouse no XS     : 20 secs (20.50 usr +  0.03 sys = 20.53 CPU) @  292255.24/s
Moose           : 21 secs (21.33 usr +  0.03 sys = 21.36 CPU) @  280898.88/s
Moo w/quote_sub : 23 secs (23.07 usr +  0.04 sys = 23.11 CPU) @  259627.87/s

