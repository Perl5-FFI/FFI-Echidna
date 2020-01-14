use Test2::V0 -no_srand => 1;
use FFI::Echidna::FE::Clang::Macro;

subtest 'basic' => sub {

  my $macro = FFI::Echidna::FE::Clang::Macro->new('FOO' => 1);
  isa_ok $macro, 'FFI::Echidna::FE::Clang::Macro';

  note "macro.name  = @{[ $macro->name  ]}";
  note "macro.value = @{[ $macro->value ]}";

  is $macro->name, 'FOO';
  is $macro->value, 1;

};

subtest 'parse' => sub {

  my $const;
  my $macro;

  my $parse = sub {
    my($value) = @_;
    $macro = FFI::Echidna::FE::Clang::Macro->new( FOO => $value );
    $const = $macro->parse_to_constant;
    $const;
  };

  is
    $parse->('bogus eh?'),
    U(),
  ;

  is
    $parse->('-42'),
    object {
      call name => 'FOO';
      call type => 'integer';
      call value => '-42';
    }
  ;

  is
    $parse->('44'),
    object {
      call name => 'FOO';
      call type => 'integer';
      call value => '44';
    }
  ;

  is
    $parse->('(46)'),
    object {
      call name => 'FOO';
      call type => 'integer';
      call value => '46';
    }
  ;

  is
    $parse->('(((47)))'),
    object {
      call name => 'FOO';
      call type => 'integer';
      call value => '47';
    }
  ;

  is
    $parse->('0xAf'),
    object {
      call name  => 'FOO';
      call type  => 'integer';
      call value => '0xAf';
    }
  ;

  is
    $parse->('0777'),
    object {
      call name  => 'FOO';
      call type  => 'integer';
      call value => '0777';
    }
  ;

  is
    $parse->('15.75'),
    object {
      call name  => 'FOO';
      call type  => 'float';
      call value => '15.75';
    }
  ;

  is
    $parse->('1575E1'),
    object {
      call name  => 'FOO';
      call type  => 'float';
      call value => '1575E1';
    }
  ;

  is
    $parse->('1575e-2'),
    object {
      call name  => 'FOO';
      call type  => 'float';
      call value => '1575e-2';
    }
  ;

  is
    $parse->('-2.5e-3'),
    object {
      call name  => 'FOO';
      call type  => 'float';
      call value => '-2.5e-3';
    }
  ;

  is
    $parse->('25E-4'),
    object {
      call name  => 'FOO';
      call type  => 'float';
      call value => '25E-4';
    }
  ;

};

done_testing;
