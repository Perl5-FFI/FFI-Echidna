package mymm;

use strict;
use warnings;
use 5.020;
require './lib/FFI/Echidna/Clang/Finder.pm';

my $clang = FFI::Echidna::Clang::Finder->new;
unless(defined $clang)
{
  print "This distribution requires clang 9.0.0 or better\n";
  exit;
}

print "Found clang : @{[ $clang->path ]}\n";
print "version     : @{[ $clang->human_version ]}\n";

1;
