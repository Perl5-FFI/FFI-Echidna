use Test2::V0 -no_srand => 1;
use FFI::Echidna::FE::Clang::Finder;

subtest 'basic' => sub {

  my $finder = FFI::Echidna::FE::Clang::Finder->new;
  isa_ok $finder, 'FFI::Echidna::FE::Clang::Finder';

  note "finder.path = @{[ $finder->path ]}";
  note "finder.cc   = @{[ $finder->cc   ]}";

};

done_testing;
