package FFI::Echidna::FE::Clang::TypeMap;

use strict;
use warnings;
use 5.020;
use Carp qw( croak );
use FFI::Echidna::Type;

# ABSTRACT: Clang type map representation
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
  my($class, %args) = @_;

  my $ast = $args{ast};
  croak "ast is required" unless defined $ast;

  my $self = bless {
  }, $class;

  $ast->foreach( TypedefDecl => sub {
    my $td = shift;

    # probably do not need these..
    return if $td->name =~ /^(__NSConstantString|__builtin_ms_va_list|__va_list_tag|__builtin_va_list)$/;

    my($inner) = $td->inner;
    if(defined $inner && $inner->kind eq 'BuiltinType')
    {

      my $type = $td->type->qual_type;
      my $lang = 'c';

      if( $type eq '__int128')
      {
        $type = 'sint128';
        $lang = 'asm';
      }
      elsif( $type eq 'unsigned __int128')
      {
        $type = 'uint128';
        $lang = 'asm';
      }

      $self->add( name => $td->name, type => $type );
    }
    else
    {
      if($args{unhandled})
      {
        $args{unhandled}->($td);
      }
    }
  });

  $self;
}

sub add
{
  my $self = shift;
  my $type = FFI::Echidna::Type->new(@_);
  my $name = $type->name;
  $self->{$name} = $type;
}

sub get
{
  my($self, $name) = @_;
  $self->{$name};
}

1;
