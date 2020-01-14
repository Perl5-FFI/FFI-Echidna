package FFI::Echidna::Location;

use strict;
use warnings;
use 5.020;
use Path::Tiny ();

# ABSTRACT: Original location of FFI artifact
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class, $path, $line, $column) = @_;

  $path = Path::Tiny->new($path) unless ref $path;

  bless [ $path, $line, $column ];
}

=head1 ATTRIBUTES

=head2 path

=head2 line

=head2 column

=cut

sub path   { shift->[0] }
sub line   { shift->[1] }
sub column { shift->[2] }

1;
