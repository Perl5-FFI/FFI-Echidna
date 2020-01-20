package mymm;

use strict;
use warnings;
use 5.020;
use ExtUtils::MakeMaker ();
require './lib/FFI/Echidna/FE/Clang/Finder.pm';

return if $ENV{CIPSTATIC} eq 'true';

my $clang = FFI::Echidna::FE::Clang::Finder->new;
unless(defined $clang)
{
  print "This distribution requires clang 9.0.0 or better\n";
  exit;
}

print "Found clang : @{[ $clang->path ]}\n";
print "version     : @{[ $clang->human_version ]}\n";

sub myWriteMakefile
{
  my %args = @_;
  $args{clean} = {FILES => "test.log"};
  ExtUtils::MakeMaker::WriteMakefile(%args);
}

1;
