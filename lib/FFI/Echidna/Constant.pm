package FFI::Echidna::Constant;

use strict;
use warnings;
use Carp qw( croak );
use 5.020;

# ABSTRACT: Constant extracted for use with FFI
# VERSION

=head1 SYNOPSIS

 use FFI::Echidna::Constant;
 
 my $const = FFI::Echidna::Constant->new(
   name  => 'FOO',
   type  => 'integer',
   value => 42,
 );

=head1 DESCRIPTION

This class represents a constant in the output module (usually Perl
source), derived from an input constant (usually a C C<#define>
macro, although it could come from another language or source).

=cut


my %types = (
  integer => 1,
  string  => 1,
  float   => 1,
);

=head1 CONSTRUCTORS

=head2 new

 my $const = FFI::Echidna::Constant->new(%attr);

Create a new instance of the constant.  Attributes are:

=over 4

=item name

(required)

The name of the constant.

=item type

(required)

The type of constant.  One of C<integer>, C<float>, or C<string>.

=item value

(required)

The value of the constant.  For an C<integer> or C<float> constant,
this should be a string representation of the value in either decimal,
hex or octal format.  For a string this should be the literal value
of the string.

=item location

(optional)

The location from where the constant came from.  If provided, this
should be an instance of L<FFI::Echidna::Location> or a array reference
in the form of C<[ $path, $line, $column ]> (C<$line> and C<$column> are
optional).

=back

=cut

sub new
{
  my($class, %args) = @_;

  croak "name is required" unless defined $args{name} && $args{name} ne '';
  croak "type must be one of integer, string, or float" unless defined $args{type} && $types{$args{type}};
  croak "value is required" unless defined $args{value};

  my $location = $args{location};

  if(ref $location eq 'ARRAY')
  {
    require FFI::Echidna::Location;
    $location = FFI::Echidna::Location->new($location->@*);
  }

  bless {
    original_name => $args{name},
    name          => $args{name},
    type          => $args{type},
    value         => $args{value},
    location      => $location,
  }, $class;
}

=head1 ATTRIBUTES

=head2 name

 my $name = $const->name;
 $const->name($name);

(rw)

The name of the constant.

=head2 original_name

 my $name = $const->original_name;

(ro)

The original name of the constant.

=head2 type

 my $type = $const->type;

(ro)

The type of the constant.  One of C<integer>, C<float> or C<string>.

=head2 value

 my $value = $const->value;

(ro)

The value of the constant.

=head2 location

 my $location = $const->location;

(ro)

The location from where the constant came.  An instance of L<FFI::Echidna::Location>.

=cut

sub original_name { shift->{original_name} }
sub type          { shift->{type}          }
sub value         { shift->{value}         }
sub location      { shift->{location}      }

sub name
{
  my($self, $new) = @_;
  $self->{name} = $new if defined $new;
  $self->{name};
}

1;
