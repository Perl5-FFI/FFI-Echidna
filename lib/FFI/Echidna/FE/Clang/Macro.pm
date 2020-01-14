package FFI::Echidna::FE::Clang::Macro;

use strict;
use warnings;
use overload '""' => sub { shift->as_string };

# ABSTRACT: Clang macro declaration
# VERSION

sub new
{
  my($class, $name, $value) = @_;
  bless { name => $name, value => $value }, $class;
}

sub name  { shift->{name}  }
sub value { shift->{value} }

sub as_string
{
  my $self = shift;
  return "[Clang::Macro @{[ $self->name ]} -> @{[ $self->value ]}]";
}

sub parse_to_constant
{
  my($self, $value) = @_;

  $value ||= $self->value;

  if($value =~ /^\s*\((.*)\)\s*$/)
  {
    return $self->parse_to_constant($1);
  }

  require FFI::Echidna::Constant;

  if($value =~ /^\s*(-?[1-9][0-9]+)\s*$/)
  {
    return FFI::Echidna::Constant->new(
      name  => $self->name,
      type  => 'integer',
      value => "$1",
    );
  }

  if($value =~ /^\s*(0[0-7]+)\s*$/)
  {
    return FFI::Echidna::Constant->new(
      name  => $self->name,
      type  => 'integer',
      value => "$1",
    );
  }

  if($value =~ /^\s*(0x[0-9a-f]+)\s*$/i)
  {
    return FFI::Echidna::Constant->new(
      name  => $self->name,
      type  => 'integer',
      value => "$1",
    );
  }

  if($value =~ /^\s*(-?[0-9]*(\.[0-9]+)?(e-?[0-9]+)?)\s*$/i)
  {
    return FFI::Echidna::Constant->new(
      name  => $self->name,
      type  => 'float',
      value => "$1",
    );
  }

  return;
}

1;
