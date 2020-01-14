package FFI::Echidna::Constant;

use strict;
use warnings;
use Carp qw( croak );
use 5.020;

# ABSTRACT: Constant extracted for use with FFI
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut


my %types = (
  integer => 1,
  string  => 1,
  float   => 1,
);

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class, %args) = @_;

  croak "name is required" unless defined $args{name} && $args{name} ne '';
  croak "type must be one of integer, string, or float" unless defined $args{type} && $types{$args{type}};
  croak "value is required" unless defined $args{value};

  bless {
    original_name => $args{name},
    name          => $args{name},
    type          => $args{type},
    value         => $args{value},
    location      => $args{location},
  }, $class;
}

=head1 ATTRIBUTES

=head2 name

=head2 original_name

=head2 type

=head2 value

=head2 location

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
