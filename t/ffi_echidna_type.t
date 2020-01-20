use Test2::V0 -no_srand => 1;
use FFI::Echidna::Type;

subtest 'basic' => sub {

  my $type = FFI::Echidna::Type->new( name => 'foo', type => 'int' );
  isa_ok $type, 'FFI::Echidna::Type';

  is
    $type,
    object {
      call name       => 'foo';
      call lang       => 'c';
      call type       => 'int';
      call shape      => 'scalar';
      call count      => U();
      call_list alias => [];
    }
  ;

};

done_testing
