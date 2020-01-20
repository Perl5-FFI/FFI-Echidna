package FFI::Echidna::FE::Clang::Wrapper;

use strict;
use warnings;
use 5.020;
use feature 'postderef';
use FFI::Echidna::FE::Clang::Finder;
use Capture::Tiny qw( capture_merged capture );
use File::chdir;
use Path::Tiny ();
use Text::ParseWords qw( shellwords );
use Data::Section::Simple qw( get_data_section );
use Data::Dumper 2.173 ();
use Mojo::Template;

# ABSTRACT: Clang wrapper
# VERSION

=head1 DESCRIPTION

This module is used internally by L<FFI::Echidna::FE::Clang>.

=head1 SEE ALSO

=over 4

=item L<FFI::Echidna>

=item L<FFI::Echidna::FE::Clang>

=back

=cut

sub new
{
  my($class, %args) = @_;

  my $finder = $args{finder} // FFI::Echidna::FE::Clang::Finder->new($args{path});
  die "clang not found" unless defined $finder;
  my $path = $finder->path;

  my @cflags = ();
  if(!defined $args{cflags})
  {
    # do nothing
  }
  elsif(ref $args{cflags} eq 'ARRAY')
  {
    @cflags = $args{cflags}->@*;
  }
  elsif(ref $args{cflags} eq '')
  {
    @cflags = (shellwords $args{cflags});
  }

  my @libs = ();
  if(!defined $args{libs})
  {
    # do nothing
  }
  elsif(ref $args{libs} eq 'ARRAY')
  {
    @libs = $args{libs}->@*;
  }
  elsif(ref $args{libs} eq '')
  {
    @libs = (shellwords $args{libs});
  }

  my @headers;
  if(!defined $args{headers})
  {
    # do nothing
  }
  elsif(ref $args{headers} eq 'ARRAY')
  {
    @headers = $args{headers}->@*;
  }
  else
  {
    @headers = ($args{headers});
  }

  my $macro_filter = $args{macro_filter} // sub { $_[0] !~ /^_/ && $_[0] !~ /\(/ };

  bless {
    finder       => $finder,
    cc           => [$finder->cc],
    path         => $path,
    cflags       => \@cflags,
    libs         => \@libs,
    headers      => \@headers,
    macro_filter => $macro_filter,
    logger       => __PACKAGE__->default_logger,
  }, $class;
}

sub default_logger
{
  my($class, $new) = @_;
  state $default;
  if($new)
  {
    $default = $new;
  }
  else
  {
    $default //= sub { say STDERR "FFI::Echidna::FE::Clang::Wrapper: $_[0]" };
  }
  $default;
}

sub finder       { shift->{finder}       }
sub path         { shift->{path}         }
sub cc           { shift->{cc}->@*       }
sub cflags       { shift->{cflags}->@*   }
sub libs         { shift->{libs}->@*     }
sub headers      { shift->{headers}->@*  }
sub macro_filter { shift->{macro_filter} }
sub logger       { shift->{logger}       }

sub log
{
  my($self, $data) = @_;
  chomp $data;
  $self->logger->($_) for split /\n/, $data;
}

sub version
{
  my($self) = @_;

  $self->{version} ||= do {
    my $dir = Path::Tiny->tempdir;
    local $CWD = $dir;
    my $c_file = Path::Tiny->new('version.c');
    $c_file->spew($self->source('version.c'));
    my($out, $ret) = do {
      my @cmd = ($self->cc, $self->cflags, -o => 'clang_version', $c_file);
      $self->log("+@cmd");
      capture_merged {
        system @cmd;
        $?;
      };
    };

    $self->log("[out/err]\n$out") if $out ne '';

    if($ret)
    {
      die "compile failed while trying to determine clang version";
    }

    ($out, $ret) = do {
      my @cmd = ('./clang_version', '-foo');
      $self->log("+@cmd");
      capture_merged {
        system @cmd;
        $?;
      };
    };

    $self->log("[out/err]\n$out") if $out ne '';

    if($ret)
    {
      die "execute failed while trying to determine clang version";
    }

    if($out =~ /v=\|([0-9]+\.[0-9]+\.[0-9]+)\|/)
    {
      return "$1";
    }
    else
    {
      die "parse failed while trying to determine clang version";
    }
  };
}

sub get_raw_macros
{
  my($self, %args) = @_;

  my $dir = Path::Tiny->tempdir;

  my $c_file = $dir->child('header.c');
  $c_file->spew($self->source_template('headers.c'));

  my($out, $err, $ret) = do {
    my @cmd = ($self->cc, $self->cflags, '-dM', '-E', $c_file);
    $self->log("+@cmd");
    capture {
      system @cmd;
      $?;
    };
  };

  $self->log("[out]\n$out") if $out ne '';
  $self->log("[err]\n$err") if $err ne '';

  die "CPP failed extracting macros" if $ret;

  my @macros;
  require FFI::Echidna::FE::Clang::Macro;

  foreach my $line (split /\n/, $out)
  {
    if($line =~ /^#define\s+(.*?)\s+(.*?)$/)
    {
      my($name, $value) = ($1, $2);
      next unless $self->macro_filter->($name);
      push @macros, FFI::Echidna::FE::Clang::Macro->new($name => $value, $self);
    }
  }

  @macros;
}

sub source
{
  my($self, $name) = @_;
  my $source = get_data_section("src/$name");
  die "unknown source $name" unless defined $source;
  $self->log("[src/$name]\n$source");
  $source;
}

sub source_template
{
  my($self, $name, %stash) = @_;
  my $template = get_data_section("template/$name");
  die "unknown template $name" unless defined $template;
  my $mt = Mojo::Template->new(vars => 1);
  $stash{headers} //= [ $self->headers ];
  $self->log("[template/$name @{[ Data::Dumper->new([\%stash])->Useqq(1)->Terse(1)->Indent(0)->Dump ]}]");
  my $source = $mt->render($template, \%stash);
  $self->log("$source");
  $mt->render($template, \%stash);
}

sub compute_macro
{
  my($self, %args) = @_;

  require FFI::Build;
  require FFI::Platypus;

  my $dir = Path::Tiny->tempdir;

  my($c_type, $p_type, $e_type) = do {

    my $c_file = $dir->child('macro_type.c');
    $c_file->spew(
      $self->source_template('macro_type.c', name => $args{name}),
    );

    # TODO: it would be nice to be able to get both the type and
    # the value from just one .so file but I haven't figured out
    # how to do that yet.
    my $build = FFI::Build->new(
      "type",
      dir     => "$dir",
      source  => "$c_file",
      verbose => 2,
      cflags  => [ $self->cflags ],
      libs    => [ $self->libs ],
    );

  my($out, $lib, $err) = capture_merged {
    my $lib = eval { $build->build };
    ($lib, "$@");
  };

    $self->log($out);
    if($err) {
      $self->log($err);
      die "Error computing macro $args{name}";
    }

    my $ffi = FFI::Platypus->new( api => 1, lib => $lib->path );

    my $c_type = $ffi->function( get_macro_type_c        => [] => 'string' )->call;
    $self->log("c type = $c_type");
    my $p_type = $ffi->function( get_macro_type_platypus => [] => 'string' )->call;
    $self->log("platypus type = $p_type");
    my $e_type = $ffi->function( get_macro_type_echidna  => [] => 'string' )->call;
    $self->log("echidna type = $e_type");

    ($c_type, $p_type, $e_type);
  };

  my $c_file = $dir->child('macro_value.c');
  $c_file->spew(
      $self->source_template('macro_value.c', name => $args{name}, type => $c_type),
  );

  my $build = FFI::Build->new(
    "value",
    dir     => "$dir",
    source  => "$c_file",
    verbose => 0,
    cflags  => [ $self->cflags ],
    libs    => [ $self->libs ],
  );

  my($out, $lib, $err) = capture_merged {
    my $lib = eval { $build->build };
    ($lib, "$@");
  };

  $self->log($out);
  if($err) {
    $self->log($err);
    die "Error computing macro $args{name}";
  }

  my $ffi = FFI::Platypus->new( api => 1, lib => $lib->path );

  my $value = $ffi->function( get_macro_value => [] => $p_type )->call;
  $self->log("value = $value");

  ($e_type, $value);
}

1;

__DATA__


@@ src/version.c
#include <stdio.h>',
int
main()
{
  printf("v=|%d.%d.%d|\n",
    __clang_major__,
    __clang_minor__,
    __clang_patchlevel__
  );
}


@@ template/headers.c
% foreach my $header (@$headers) {
#include <<%= $header %>>
% }


@@ template/macro_value.c
% foreach my $header (@$headers) {
#include <<%= $header %>>
% }

<%= $type %>
get_macro_value()
{
  return <%= $name %>;
}


@@ template/macro_type.c
% foreach my $header (@$headers) {
#include <<%= $header %>>
% }

const char *
get_macro_type_c()
{
  return _Generic(<%= $name %>,
    const char *: "const char *",
    char *: "char *",
    signed char: "signed char",
    char: "char",
    unsigned char: "unsigned char",
    short: "short",
    unsigned short: "unsigned short",
    int: "int",
    unsigned int: "unsigned int",
    long: "long",
    unsigned long: "unsigned long",
    float: "float",
    double: "double"
  );
}

const char *
get_macro_type_echidna()
{
  return _Generic(<%= $name %>,
    const char *: "string",
    char *: "string",
    signed char: "integer",
    char: "integer",
    unsigned char: "integer",
    short: "integer",
    unsigned short: "integer",
    int: "integer",
    unsigned int: "integer",
    long: "integer",
    unsigned long: "ineger",
    float: "float",
    double: "float"
  );
}

const char *
get_macro_type_platypus()
{
  return _Generic(<%= $name %>,
    const char *: "string",
    char *: "string",
    signed char: "sint8",
    char: "char",
    unsigned char: "uint8",
    short: "short",
    unsigned short: "ushort",
    int: "int",
    unsigned int: "uint",
    long: "long",
    unsigned long: "ulong",
    float: "float",
    double: "double"
  );
}
