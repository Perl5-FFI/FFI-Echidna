use Test2::V0 -no_srand => 1;
use FFI::Echidna::FE::Clang::AST;
use FFI::Echidna::FE::Clang::Wrapper;

FFI::Echidna::FE::Clang::Wrapper->default_logger(sub {
  note "FE::Clang::Wrapper: $_[0]";
});

sub ast
{
  FFI::Echidna::FE::Clang::AST->new(FFI::Echidna::FE::Clang::Wrapper->new( @_ )->ast);
}

subtest 'type' => sub {

  my $ast = ast(cflags => '-Icorpus/ffi_echidna_fe_clang', headers => 'type1.h' );
  isa_ok $ast, 'FFI::Echidna::FE::Clang::AST';

  note $_ for $ast->dump;


  subtest 'foreach' => sub {

    $ast->foreach(TypedefDecl => sub {
      note $_ for shift->dump(0);
    });

    ok 1;

  };

};

subtest 'function' => sub {

  my $ast = ast(cflags => '-Icorpus/ffi_echidna_fe_clang', headers => 'func1.h' );
  isa_ok $ast, 'FFI::Echidna::FE::Clang::AST';

  note $_ for $ast->dump;

};

subtest 'enum' => sub {

  my $ast = ast(cflags => '-Icorpus/ffi_echidna_fe_clang', headers => 'enum1.h' );
  isa_ok $ast, 'FFI::Echidna::FE::Clang::AST';

  note $_ for $ast->dump;

  note '';
  note '';
  note '';

  $ast->foreach(EnumDecl => sub {

    my $enum = shift;

    note $enum->name;

    foreach my $value ($enum->inner)
    {
      note "  ", $value->name;
    }

  });

};

done_testing;
