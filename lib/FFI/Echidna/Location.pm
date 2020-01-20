package FFI::Echidna::Location;

use strict;
use warnings;
use 5.020;
use Path::Tiny ();
use overload
  '""' => sub { shift->as_string },
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Original location of FFI artifact
# VERSION

=head1 SYNOPSIS

 use FFI::Echidna::Location;
 
 my $loc = FFI::Echidna::Location->new($path, $line, $column);

=head1 DESCRIPTION

This class represents the location of an object in the input
source.

=head1 CONSTRUCTORS

=head2 new

 my $loc = FFI::Echidna::Location->new($path);
 my $loc = FFI::Echidna::Location->new($path, $line, $column);

C<$path> maybe either a L<Path::Tiny> object, or a string containing
the path.  Either way it will be converted internally to a absolute
L<Path::Tiny> object.

The C<$line> and <$column> are optional, so for example if the
source is a binary file where line number and column do not make
sense you can skip them.

=cut

sub new
{
  my($class, $path, $line, $column) = @_;

  $path = Path::Tiny->new($path) unless ref $path;

  $path = $path->absolute unless $path->is_absolute;

  bless [ $path, $line, $column ], $class;
}

=head1 ATTRIBUTES

=head2 path

 my $path = $loc->path;

(ro)

The absolute path to the location filename.

=head2 line

 my $line = $loc->line;

(ro)

The line number.

=head2 column

 my $column = $loc->column;

(ro)

The column.

=cut

sub path   { shift->[0] }
sub line   { shift->[1] }
sub column { shift->[2] }

=head1 METHODS

=head2 as_string

 my $str = $loc->as_string;

=cut

sub as_string
{
  my($self) = @_;
  my $str = $self->path->stringify;
  if(defined $self->line)
  {
    $str .= ":" . $self->line;
    $str .= "." . $self->column if defined $self->column;
  }
}

1;
