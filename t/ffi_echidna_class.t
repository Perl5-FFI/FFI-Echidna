use Test2::V0 -no_srand => 1;
use FFI::Echidna::Class;

subtest 'basic' => sub {

  my $class = FFI::Echidna::Class->new;
  isa_ok $class, 'FFI::Echidna::Class';

  is
    $class,
    object {
      call name      => 'My::Class::FFI';
      call libs      => ['foo'];
      call constants => [];
      call functions => [];
    }
  ;

  $class = FFI::Echidna::Class->new( name => 'Foo::Bar', libs => 'bar' );
  isa_ok $class, 'FFI::Echidna::Class';

  is
    $class,
    object {
      call name      => 'Foo::Bar';
      call libs      => ['bar'];
      call constants => [];
      call functions => [];
    }
  ;

  $class = FFI::Echidna::Class->new( name => 'Foo::Bar', libs => ['foo','bar','baz'] );
  isa_ok $class, 'FFI::Echidna::Class';

  is
    $class,
    object {
      call name      => 'Foo::Bar';
      call libs      => ['foo','bar','baz'];
      call constants => [];
      call functions => [];
    }
  ;

};

done_testing
