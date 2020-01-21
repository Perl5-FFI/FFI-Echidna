package FFI::Echidna::Type;

use strict;
use warnings;
use 5.020;
use experimental 'postderef';
use Carp qw( croak );
use PerlX::Maybe;

# ABSTRACT: Type extracted for use with FFI
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class, %args) = @_;

  $args{shape} ||= 'scalar';

  croak "shape must be one of: scalar, array, pointer"
    unless $args{shape} =~ /^(scalar|array|pointer)$/;

  $args{lang} ||= 'c';

  croak "lang must be one of: c, asm"
    unless $args{lang} =~ /^(c|asm)$/;

  croak "name must be provided"
    unless $args{name};
  croak "type must be provided"
    unless $args{type};

  my @alias;
  if(defined $args{alias})
  {
    if(ref $args{alias} eq 'ARRAY')
    {
      push @alias, $args{alias}->@*;
    }
    else
    {
      push @alias, $args{alias};
    }
  }

  my $alias = @alias > 0 ? \@alias : undef;

  bless {
          name  => $args{name},
          lang  => $args{lang},
          type  => $args{type},
          shape => $args{shape},
    maybe count => $args{count},
    maybe alias => $alias,
  }, $class;
}

=head1 ATTRIBUTES

=head2 name

=head2 lang

=head2 type

=head2 shape

=head2 count

=head2 alias

=cut

sub name  { shift->{name}             }
sub lang  { shift->{lang}             }
sub type  { shift->{type}             }
sub shape { shift->{shape}            }
sub count { shift->{count}            }
sub alias { @{ shift->{alias} // [] } }

=head1 METHODS

=head2 to_alias

=cut

sub to_alias
{
  my($self, $new) = @_;
  my $class = ref $self;
  $class->new(
    name  => $new,
    lang  => $self->lang,
    type  => $self->type,
    shape => $self->shape,
    count => $self->count,
    alias => [$self->name, $self->alias],
  );
}

1;
