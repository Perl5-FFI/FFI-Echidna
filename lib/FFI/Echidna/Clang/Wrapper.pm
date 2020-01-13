package FFI::Echidna::Clang::Wrapper;

use strict;
use warnings;
use 5.020;
use FFI::Echidna::Clang::Finder;
use Capture::Tiny qw( capture_merged );
use File::chdir;
use Path::Tiny ();

# ABSTRACT: Clang wrapper
# VERSION

=head1 DESCRIPTION

This module is used internally by L<FFI::Echidna::Clang>.

=head1 SEE ALSO

=over 4

=item L<FFI::Echidna>

=item L<FFI::Echidna::Clang>

=back

=cut

sub new
{
  my($class, $path) = @_;

  my $finder = FFI::Echidna::Clang::Finder->new($path);
  die "clang not found" unless defined $finder;
  $path = $finder->path;

  bless {
    finder => $finder,
    path   => $path,
  }, $class;
}

sub finder { shift->{finder} }
sub path   { shift->{path}   }

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
      my @cmd = ($self->path, -o => 'clang_version', $c_file);
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

1;
