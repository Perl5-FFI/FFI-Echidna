use Test2::V0 -no_srand => 1;
use FFI::Echidna::FE::Clang::Macro;
use FFI::Echidna::FE::Clang::Wrapper;

FFI::Echidna::FE::Clang::Wrapper->default_logger(do {
  open my $fh, '>>', 'test.log';
  END { close $fh };
  sub {
    my($line) = @_;
    print $fh "FE::Clang::Wrapper: $line\n";
  }
});

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

subtest 'compile' => sub {

  my $const;
  my $macro;

  my $wrapper = FFI::Echidna::FE::Clang::Wrapper->new(
    cflags => '-Icorpus/ffi_echidna_fe_clang',
    headers => ['macro1.h','macro2.h'],
  );

  my $cc = sub {
    my($name) = @_;
    $macro = FFI::Echidna::FE::Clang::Macro->new( $name => 22, $wrapper );
    $const = $macro->compile_to_constant;
    $const;
  };

  is
    $cc->("FOO"),
    object {
      call name  => 'FOO';
      call type  => 'integer';
      call value => 1;
    }
  ;

  is
    $cc->("BAR"),
    object {
      call name  => 'BAR';
      call type  => 'string';
      call value => 'hello';
    }
  ;

  is
    $cc->("BAZ"),
    object {
      call name  => 'BAZ';
      call type  => 'integer';
      call value => 42;
    }
  ;

  is
    $cc->("SOMETHING_ELSE"),
    object {
      call name  => 'SOMETHING_ELSE';
      call type  => 'integer';
      call value => 3;
    }
  ;

  is
    $cc->("FLOATER"),
    object {
      call name  => 'FLOATER';
      call type  => 'float';
      call value => 1.0;
    }
  ;
};

done_testing;
