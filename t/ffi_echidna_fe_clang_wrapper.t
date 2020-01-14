use Test2::V0 -no_srand => 1;
use FFI::Echidna::FE::Clang::Wrapper;

subtest 'basic construction' => sub {

  my $wrapper = FFI::Echidna::FE::Clang::Wrapper->new;
  isa_ok $wrapper, 'FFI::Echidna::FE::Clang::Wrapper';
  isa_ok $wrapper->finder, 'FFI::Echidna::FE::Clang::Finder';

  note "wrapper.path = @{[ $wrapper->path ]}";
  note "wrapper.cc   = @{[ $wrapper->cc ]}";

  my $mock = mock 'FFI::Echidna::FE::Clang::Finder' => (
    override => [
      new => sub { return; },
     ],
  );

  local $@ = '';
  eval { FFI::Echidna::FE::Clang::Wrapper->new };
  like "$@", qr/clang not found/;

};

subtest 'version' => sub {

  my $wrapper = FFI::Echidna::FE::Clang::Wrapper->new;
  isa_ok $wrapper, 'FFI::Echidna::FE::Clang::Wrapper';

  my $version = $wrapper->version;
  like $version, qr/^[0-9]+\.[0-9]+\.[0-9]+$/;

  note "version = $version";

};

subtest 'raw macros' => sub {

  my $wrapper = FFI::Echidna::FE::Clang::Wrapper->new(
    cflags => '-Icorpus/ffi_echidna_fe_clang_wrapper/macro',
    headers => ['macro1.h','macro2.h'],
  );

  my @macros = $wrapper->get_raw_macros;

  is
    \@macros,
    bag {
      item object {
        call name => 'FOO';
        call value => 1;
        call wrapper => object {
          call ['isa', 'FFI::Echidna::FE::Clang::Wrapper'] => T();
        };
      };
      item object {
        call name => 'BAR';
        call value => '"hello"';
      };
      item object {
        call name => 'BAZ';
        call value => 42;
      };
      item object {
        call name => 'SOMETHING_ELSE';
        call value => '1-2-4*5 & 44';
      };
      etc;
    }
  ;

  note $_ for @macros;

};

done_testing;
