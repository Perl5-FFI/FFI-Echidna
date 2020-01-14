package FFI::Echidna::FE::Clang::Finder;

use strict;
use warnings;
use 5.020;
use feature 'postderef';
use Config;
use JSON::MaybeXS qw( decode_json );
use Capture::Tiny qw( capture );
use File::Which qw( which );
use Path::Tiny qw( tempdir );
use File::chdir;
use Text::ParseWords qw( shellwords );

# ABSTRACT: Clang path finder
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
  my($class, $path) = @_;
  if(defined $path) {
    $path = which $path;
  } else {
    foreach my $maybe ($ENV{FFI_ECHIDNA_CLANG}, $ENV{CLANG}, 'clang', 'clang-9', 'clang-10', $ENV{CC}, $Config{cc})
    {
      next unless defined $maybe;
      my @maybe = shellwords($maybe);
      $path = which $maybe[0];

      if(defined $path)
      {
        my @cc = @maybe;
        $cc[0] = $path;
        my $self = bless { path => Path::Tiny->new($path), cc => \@cc }, $class;
        return $self if $self->good_enough;
      }
    }
  }
  # unusual in that the constructor returns undef (or empty list actually)
  # rather than die'ing.
  return;
}

sub path { shift->{path}   }
sub cc   { shift->{cc}->@* }

sub human_version
{
  my($self) = @_;

  $self->{human_version} ||= do {
    my($out, $err, $ret) = capture {
      system($self->cc, '--version');
      $?;
    };
    die "unable to determine human readable version" if $?;
    my($version, @lines) = split /\n/, $out;

    foreach my $line (@lines)
    {
      if($line =~ /^(.*?):\s+(.*?)$/)
      {
        my $key = $1;
        my $val = $2;
        $self->{kv}->{$key} = $val;
      }
    }

    $version;
  }
}

sub kv
{
  my($self) = @_;
  $self->human_version;
  $self->{kv};
}

sub good_enough
{
  my($self) = @_;

  my $dir = tempdir;
  local $CWD = $dir;

  my $c_file = Path::Tiny->new('foo.c');

  $c_file->spew("typedef int foo_t;\n" .
                "extern foo_t bar(foo_t one, const char *two);\n");

  my($out, $err, $ret) = capture {
    my @cmd = ($self->cc, '-Xclang', '-ast-dump=json', '-fsyntax-only', $c_file);
    #print "+@cmd\n";
    system @cmd;
    $?;
  };

  return 0 if $?;

  my $payload = eval { decode_json($out) };

  return 0 if $@;

  return 1;
}

sub diag
{
  my($self) = @_;

  my @list;

  push @list, [ 'path'    => $self->path          ];
  push @list, [ 'cc'      => join(' ', $self->cc) ] if $self->cc > 1;
  push @list, [ 'version' => $self->human_version ];

  foreach my $k (sort keys $self->kv->%*)
  {
    my $v = $self->kv->{$k};
    push @list, [ $k => $v ];
  }

  my $max = 0;
  foreach my $item (@list)
  {
    $max = length $item->[0] if length $item->[0] > $max;
  }

  @list = map { sprintf "%-${max}s : %s", $_->[0], $_->[1] } @list;

  unshift @list, '[clang]';

  @list;
}

1;
