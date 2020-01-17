use Test2::V0 -no_srand => 1;
use FFI::Echidna::BE::Perl;
use FFI::Echidna::Class;
use FFI::Echidna::Constant;

my $perl;

subtest 'basic' => sub {

  $perl = FFI::Echidna::BE::Perl->new;
  isa_ok $perl, 'FFI::Echidna::BE::Perl';

};

subtest 'package_name' => sub {

  my $class = FFI::Echidna::Class->new( name => 'Foo::Bar' );

  is
    $perl->package_name($class),
    'Foo::Bar',
  ;

};

subtest 'minimum_platypus' => sub {

  my $class = FFI::Echidna::Class->new;

  is
    $perl->minimum_platypus($class),
    '1.00',
  ;


};

subtest 'const_name' => sub {

  my $const = FFI::Echidna::Constant->new(
    name  => 'FOO',
    type  => 'integer',
    value => '0xff',
  );

  is
    $perl->const_name($const),
    'FOO',
  ;

};

subtest 'const_value' => sub {

  my $const = FFI::Echidna::Constant->new(
    name  => 'FOO',
    type  => 'integer',
    value => '0xff',
  );

  is
    $perl->const_value($const),
    '0xff',
  ;

  $const = FFI::Echidna::Constant->new(
    name  => 'FOO',
    type  => 'float',
    value => '1.24',
  );

  is
    $perl->const_value($const),
    '1.24',
  ;

  $const = FFI::Echidna::Constant->new(
    name  => 'FOO',
    type  => 'string',
    value => "hello\tworld\n",
  );

  my $value = $perl->const_value($const);
  local $@ = '';
  $value = eval $value;
  is "$@", '';

  is $value, "hello\tworld\n";

};

subtest 'lib' => sub {

  subtest 'basic string' => sub {

    my $class = FFI::Echidna::Class->new(
      libs => 'foo',
    );

    my $value = $perl->libs($class);
    local $@ = '';
    $value = eval $value;
    is "$@", '';
    is $value, 'foo';

  };

  subtest 'basic string in array' => sub {

    my $class = FFI::Echidna::Class->new(
      libs => ['foo'],
    );

    my $value = $perl->libs($class);
    local $@ = '';
    $value = eval $value;
    is "$@", '';
    is $value, 'foo';

  };

  subtest 'array' => sub {

    my $class = FFI::Echidna::Class->new(
      libs => ['foo','bar','baz'],
    );

    my $value = $perl->libs($class);
    local $@ = '';
    $value = eval $value;
    is "$@", '';
    is $value, ['foo','bar','baz'];

  };

  subtest 'empty' => sub {

    my $class = FFI::Echidna::Class->new(
      libs => [],
    );

    my $value = $perl->libs($class);
    local $@ = '';
    $value = eval $value;
    is "$@", '';
    is $value, [];

  };

};

done_testing
