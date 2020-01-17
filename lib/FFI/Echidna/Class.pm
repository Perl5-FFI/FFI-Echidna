package FFI::Echidna::Class;

use strict;
use warnings;
use feature 'postderef';
use 5.020;

# ABSTRACT: Class extracted for use with FFI
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class, %args) = @_;

  my @libs;
  if(!defined $args{libs})
  {
    @libs = ('foo');
  }
  elsif(ref $args{libs} eq 'ARRAY')
  {
    @libs = $args{libs}->@*;
  }
  elsif(ref $args{libs} eq '')
  {
    @libs = ($args{libs});
  }

  bless {
    name      => $args{name}      || 'My::Class::FFI',
    libs      => \@libs,
    constants => $args{constants} || [],
    functions => $args{functions} || [],
  }, $class;
}

=head1 ATTRIBUTES

=head2 constants

=head2 name

=head2 libs

=head2 constants

=head2 functions

=cut

sub name      { shift->{name}      }
sub libs      { shift->{libs}      }
sub constants { shift->{constants} }
sub functions { shift->{functions} }

1;
