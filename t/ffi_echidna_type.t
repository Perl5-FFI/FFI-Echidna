use Test2::V0 -no_srand => 1;
use FFI::Echidna::Type;
use YAML ();

subtest 'basic' => sub {

  my $type1 = FFI::Echidna::Type->new( name => 'foo', type => 'int' );
  isa_ok $type1, 'FFI::Echidna::Type';

  is
    $type1,
    object {
      call name       => 'foo';
      call lang       => 'c';
      call type       => 'int';
      call shape      => 'scalar';
      call count      => U();
      call_list alias => [];
    }
  or note YAML::Dump($type1);

  my $type2 = $type1->to_alias('bar');

  is
    $type2,
    object {
      call name       => 'bar';
      call lang       => 'c';
      call type       => 'int';
      call shape      => 'scalar';
      call count      => U();
      call_list alias => ['foo'];
    }
  or note YAML::Dump($type2);

  my $type3 = $type2->to_alias('baz');

  is
    $type3,
    object {
      call name       => 'baz';
      call lang       => 'c';
      call type       => 'int';
      call shape      => 'scalar';
      call count      => U();
      call_list alias => ['bar','foo'];
    }
  or note YAML::Dump($type3);

};

done_testing
