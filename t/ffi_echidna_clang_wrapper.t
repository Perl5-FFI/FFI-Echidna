use Test2::V0 -no_srand => 1;
use FFI::Echidna::Clang::Wrapper;

subtest 'basic construction' => sub {

  my $wrapper = FFI::Echidna::Clang::Wrapper->new;
  isa_ok $wrapper, 'FFI::Echidna::Clang::Wrapper';
  isa_ok $wrapper->finder, 'FFI::Echidna::Clang::Finder';

  my $mock = mock 'FFI::Echidna::Clang::Finder' => (
    override => [
      new => sub { return; },
    ],
  );

  local $@ = '';
  eval { FFI::Echidna::Clang::Wrapper->new };
  like "$@", qr/clang not found/;

};

subtest 'version' => sub {

  my $wrapper = FFI::Echidna::Clang::Wrapper->new;
  isa_ok $wrapper, 'FFI::Echidna::Clang::Wrapper';

  my $version = $wrapper->version;
  like $version, qr/^[0-9]+\.[0-9]+\.[0-9]+$/;

  note "version = $version";

};

done_testing;
