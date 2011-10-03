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
package Mo::Benchmarks::Command::xxx;
Mo::Benchmarks->import( -command );
use Mouse;
extends 'Mo::Benchmarks::Command';

use constant abstract => '...';
use constant usage_desc => 'mo-benchmarks xxx ...';

has yyy => (
    is => 'ro',
    isa => 'Str',
    documentation => '...',
);

sub execute {
    my ($self, $opt, $args) = @_;
    ...    
}

#------------------------------------------------------------------------------#
package Mo::Benchmarks::Command;

# Common subroutines:

1;

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...
