use Test2::V0 -no_srand => 1;
use FFI::Echidna::Location;

subtest 'basic' => sub {

  my $loc = FFI::Echidna::Location->new(
    'foo/bar/baz.c',
    44,
    22,
  );

  isa_ok $loc, 'FFI::Echidna::Location';
  isa_ok $loc->path, 'Path::Tiny';

  is
    $loc,
    object {
      call path => object {
        call is_absolute => 1;
        call basename => 'baz.c';
      };
      call line => 44;
      call column => 22;
    }
  ;

};

done_testing
