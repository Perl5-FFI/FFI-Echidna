use Test2::V0 -no_srand => 1;
use FFI::Echidna::Constant;

subtest 'basic' => sub {

  my $const = FFI::Echidna::Constant->new(
    name  => 'FOO',
    type  => 'integer',
    value => '0xaf',
  );

  isa_ok $const, 'FFI::Echidna::Constant';

  is
    $const,
    object {
      call name => 'FOO';
      call original_name => 'FOO';
      call type => 'integer';
      call value => '0xaf';
      call location => U();
    }
  ;

  $const->name('BAR');

  is
    $const,
    object {
      call name => 'BAR';
      call original_name => 'FOO';
      call type => 'integer';
      call value => '0xaf';
      call location => U();
    }
  ;

  $const = FFI::Echidna::Constant->new(
    name     => 'FOO',
    type     => 'string',
    value    => 'hello world',
    location => ['foo/bar/baz.c', 22, 44],
  );

  is
    $const,
    object {
      call name     => 'FOO';
      call type     => 'string';
      call value    => 'hello world';
      call location => object {
        call path => object {
          call is_absolute => T();
          call basename => 'baz.c';
        };
        call line   => 22;
        call column => 44;
      };
    }
  ;

};

done_testing
