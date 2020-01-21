use Test2::V0 -no_srand => 1;
use FFI::Echidna::FE::Clang::TypeMap;
use FFI::Echidna::FE::Clang::AST;
use FFI::Echidna::FE::Clang::Wrapper;
use Path::Tiny ();

FFI::Echidna::FE::Clang::Wrapper->default_logger(sub {
  note "FE::Clang::Wrapper: $_[0]";
});

my $tm;

sub tm ($)
{
  my $dir = Path::Tiny->tempdir;
  my $h = $dir->child('foo.h');
  $h->spew(shift);
  my $wrapper = FFI::Echidna::FE::Clang::Wrapper->new( cflags => "-I$dir", headers => 'foo.h' );
  my $ast = FFI::Echidna::FE::Clang::AST->new( $wrapper->ast );
  $tm = FFI::Echidna::FE::Clang::TypeMap->new( ast => $ast, unhandled => sub {
    my $td = shift;
    note "unhandled typedef: $_" for $td->dump;
  } );
}


subtest 'basic' => sub {

  tm q{
    typedef int    foo;
    typedef float  bar;
    typedef double baz;
  };

  isa_ok $tm, 'FFI::Echidna::FE::Clang::TypeMap';

  is
    $tm->get('foo'),
    object {
      call name => 'foo';
      call lang => 'c';
      call shape => 'scalar';
      call type => 'int';
    },
  ;

  is
    $tm->get('bar'),
    object {
      call name => 'bar';
      call lang => 'c';
      call shape => 'scalar';
      call type => 'float';
    },
  ;

  is
    $tm->get('baz'),
    object {
      call name => 'baz';
      call lang => 'c';
      call shape => 'scalar';
      call type => 'double';
    },
  ;

  use YAML ();
  note YAML::Dump($tm);

};

done_testing;
