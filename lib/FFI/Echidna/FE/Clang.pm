package FFI::Echidna::FE::Clang;

use strict;
use warnings;

# ABSTRACT: Clang front-end plugin for Echidna
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

This module serves as a Clang plugin for Echidna.

=head1 PREREQS

This plugin requires a fairly recent (as of this writing) version of clang
to generate a AST in JSON format.

=head2 Debian / Ubuntu

On Debian 11 Bullseye (testing as of this writing) and Ubuntu 19.10 Eoan
Ermine you can install the C<clang-9> package.

 $ sudo apt-get update && sudo apt-get install clang-9

Older versions of Debian definitely do not have a C<clang-9> package and
most older versions of Ubuntu probably do not either.  You can either build
clang from source or download a pre-compiled binary here:

http://releases.llvm.org/download.html

=head2 Mac OS X

The Xcode / clang version number on OS X apparently does not correspond with the
upstream llvm / clang version numbers.  From what I understand, as of this writing,
the latest (real) llvm / clang version that Apple ships is 8.0.0, which doesn't
support AST in JSON format.  You can, however download pre-compiled binaries here:

http://releases.llvm.org/download.html

=head2 RedHat

I have no idea.  Please feel free to PR this POD to update as appropriate.

=cut

1;
