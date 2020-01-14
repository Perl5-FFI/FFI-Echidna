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

sub as_string {
  my $self = shift;
  return "[Clang::Macro @{[ $self->name ]} -> @{[ $self->value ]}]"
}

1;
