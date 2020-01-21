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

};

subtest 'indirect' => sub {

  tm q{
    typedef char x1;
    typedef x1 x2;
    typedef x2 x3;
    typedef x3 *x3_ptr;
    typedef x3 x3_a[];
    typedef x3 x3_a3[3];
  };

  is
    $tm->get('x1'),
    object {
      call name  => 'x1';
      call lang  => 'c';
      call shape => 'scalar';
      call type  => 'char';
      call count      => U();
      call_list alias => [];
    },
  ;

  is
    $tm->get('x3'),
    object {
      call name  => 'x3';
      call lang  => 'c';
      call shape => 'scalar';
      call type  => 'char';
      call count      => U();
      call_list alias => ['x2','x1'];
    },
  ;

  is
    $tm->get('x3_ptr'),
    object {
      call name       => 'x3_ptr';
      call lang       => 'c';
      call shape      => 'pointer';
      call type       => 'char';
      call count      => U();
      call_list alias => ['x3*','x2*','x1*'];
    },
  ;

  is
    $tm->get('x3_a3'),
    object {
      call name       => 'x3_a3';
      call lang       => 'c';
      call shape      => 'array';
      call type       => 'char';
      call count      => 3;
      call_list alias => ['x3[3]','x2[3]','x1[3]'];
    },
  ;

  is
    $tm->get('x3_a'),
    object {
      call name       => 'x3_a';
      call lang       => 'c';
      call shape      => 'array';
      call type       => 'char';
      call count      => U();
      call_list alias => ['x3[]','x2[]','x1[]'];
    },
  ;

  use YAML ();
  note YAML::Dump($tm);

};

done_testing;
