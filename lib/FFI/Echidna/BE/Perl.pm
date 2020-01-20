package FFI::Echidna::BE::Perl;

use strict;
use warnings;
use 5.020;
use experimental qw( postderef );
use Data::Dumper 2.173 ();

# ABSTRACT: Backend for generating Perl code
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class) = @_;
  bless {}, $class;
}

=head1 METHODS

=head2 package_name

=cut

sub package_name
{
  my($self, $class) = @_;
  $class->name;
}

=head2 minimum_platypus

=cut

sub minimum_platypus
{
  my($self, $class) = @_;
  return '1.00';
}

=head2 const_name

=cut

sub const_name
{
  my($self, $const) = @_;
  $const->name;
}

=head2 const_value

=cut

sub const_value
{
  my($self, $const) = @_;
  if($const->type eq 'string')
  {
    return Data::Dumper->new([$const->value])->Useqq(1)->Terse(1)->Dump;
  }
  elsif($const->type =~ /^(integer|float)$/)
  {
    return $const->value;
  }
  else
  {
    die "unknown type: @{[ $const->type ]}";
  }
}

=head2 libs

=cut

sub libs
{
  my($self, $class) = @_;

  my @libs = $class->libs->@*;

  if(@libs == 1)
  {
    return Data::Dumper->new([$libs[0]])->Useqq(1)->Terse(1)->Dump;
  }
  else
  {
    return Data::Dumper->new([\@libs])->Useqq(1)->Terse(1)->Dump;
  }
}

=head2 function_name

=cut

sub function_name
{
  my($self, $function) = @_;
  ...
}

=head2 function_args

=cut

sub function_args
{
  my($self, $function) = @_;
  ...
}

=head2 function_ret

=cut

sub function_ret
{
  my($self, $function) = @_;
  ...
}

1;
