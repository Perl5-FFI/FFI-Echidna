use Test2::V0 -no_srand => 1;
use FFI::Echidna::FE::Clang::Macro;

subtest 'basic' => sub {

  my $macro = FFI::Echidna::FE::Clang::Macro->new('FOO' => 1);
  isa_ok $macro, 'FFI::Echidna::FE::Clang::Macro';

  note "macro.name  = @{[ $macro->name  ]}";
  note "macro.value = @{[ $macro->value ]}";

  is $macro->name, 'FOO';
  is $macro->value, 1;

};

done_testing;
