package FFI::Echidna::FE::Clang::Macro;

use strict;
use warnings;
use overload
  '""' => sub { shift->as_string },
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Clang macro declaration
# VERSION

=head1 DESCRIPTION

This module is used internally by L<FFI::Echidna::FE::Clang>.

=head1 SEE ALSO

=over 4

=item L<FFI::Echidna>

=item L<FFI::Echidna::FE::Clang>

=back

=cut

sub new
{
  my($class, $name, $value, $wrapper) = @_;

  $wrapper ||= do {
    require FFI::Echidna::FE::Clang::Wrapper;
    FFI::Echidna::FE::Clang::Wrapper->new;
  };

  bless {
    name    => $name,
    value   => $value,
    wrapper => $wrapper,
  }, $class;
}

sub name    { shift->{name}  }
sub value   { shift->{value} }
sub wrapper { shift->{wrapper} }

sub as_string
{
  my $self = shift;
  return "[Clang::Macro @{[ $self->name ]} -> @{[ $self->value ]}]";
}

sub compute_value
{
  my($self) = @_;
  $self->parse_to_constant // $self->compile_to_constant;
}

sub compile_to_constant
{
  my($self) = @_;
  my($type, $value) = $self->wrapper->compute_macro( name => $self->name );
  FFI::Echidna::Constant->new(
    name  => $self->name,
    type  => $type,
    value => $value,
  );
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
