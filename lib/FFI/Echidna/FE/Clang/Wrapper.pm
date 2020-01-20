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
  }, $class;
}

sub finder       { shift->{finder}      }
sub path         { shift->{path}        }
sub cc           { shift->{cc}->@*      }
sub cflags       { shift->{cflags}->@*  }
sub libs         { shift->{libs}->@*    }
sub headers      { shift->{headers}->@* }
sub macro_filter { shift->{macro_filter} }

sub version
{
  my($self) = @_;

  $self->{version} ||= do {
    my $dir = Path::Tiny->tempdir;
    local $CWD = $dir;
    my $c_file = Path::Tiny->new('version.c');
    $c_file->spew(join "\n", '#include <stdio.h>',
                             'int main() {',
                             '  printf("v=|%d.%d.%d|\n", __clang_major__, __clang_minor__, __clang_patchlevel__);',
                             '}');
    my($out, $ret) = capture_merged {
      print "[$c_file]\n";
      print $c_file->slurp, "\n";
      my @cmd = ($self->cc, $self->cflags, -o => 'clang_version', $c_file);
      print "+@cmd\n";
      system @cmd;
      $?;
    };

    if($ret)
    {
      print STDERR $out;
      die "compile failed while trying to determine clang version";
    }

    ($out, $ret) = capture_merged {
      print "[$c_file]\n";
      print $c_file->slurp, "\n";
      my @cmd = ('./clang_version', '-foo');
      print "+@cmd\n";
      system @cmd;
      $?;
    };

    if($ret)
    {
      print STDERR $out;
      die "execute failed while trying to determine clang version";
    }

    if($out =~ /v=\|([0-9]+\.[0-9]+\.[0-9]+)\|/)
    {
      return "$1";
    }
    else
    {
      print STDERR $out;
      die "parse failed while trying to determine clang version";
    }
  };
}

sub get_raw_macros
{
  my($self, %args) = @_;

  my $dir = Path::Tiny->tempdir;

  my $c_file = $dir->child('header.c');
  $c_file->spew(join "\n",
                map { "#include <$_>" }
                $self->headers
  );

  my($out, $err, $ret) = capture {
      print "[$c_file]\n";
      print $c_file->slurp, "\n";
      my @cmd = ($self->cc, $self->cflags, '-dM', '-E', $c_file);
      print "+@cmd\n";
      system @cmd;
      $?;
  };

  if($ret)
  {
    print STDERR $out;
    print STDERR $err;
    die "CPP failed extracting macros";
  }

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

sub compute_macro
{
  my($self, %args) = @_;

  require FFI::Build;
  require FFI::Platypus;

  my $dir = Path::Tiny->tempdir;

  my($c_type, $p_type, $e_type) = do {

    my $c_file = $dir->child('macro_type.c');
    $c_file->spew(
      Mojo::Template->new(vars => 1)->render(
        get_data_section('template/macro_type.c'),
        { name => $args{name}, headers => [ $self->headers ] },
      ),
    );

    my $build = FFI::Build->new(
      "type",
      dir     => "$dir",
      source  => "$c_file",
      verbose => 0,
      cflags  => [ $self->cflags ],
      libs    => [ $self->libs ],
    );

    my $lib = $build->build;

    my $ffi = FFI::Platypus->new( api => 1, lib => $lib->path );

    my $c_type = $ffi->function( get_macro_type_c        => [] => 'string' )->call;
    my $p_type = $ffi->function( get_macro_type_platypus => [] => 'string' )->call;
    my $e_type = $ffi->function( get_macro_type_echidna  => [] => 'string' )->call;

    ($c_type, $p_type, $e_type);
  };

  my $c_file = $dir->child('macro_value.c');
  $c_file->spew(
    Mojo::Template->new(vars => 1)->render(
      get_data_section('template/macro_value.c'),
      { name => $args{name}, type => $c_type, headers => [ $self->headers ] },
    ),
  );

  my $build = FFI::Build->new(
    "value",
    dir     => "$dir",
    source  => "$c_file",
    verbose => 0,
    cflags  => [ $self->cflags ],
    libs    => [ $self->libs ],
  );

  my $lib = $build->build;

  my $ffi = FFI::Platypus->new( api => 1, lib => $lib->path );

  my $value = $ffi->function( get_macro_value => [] => $p_type )->call;

  ($e_type, $value);
}

1;

__DATA__

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
