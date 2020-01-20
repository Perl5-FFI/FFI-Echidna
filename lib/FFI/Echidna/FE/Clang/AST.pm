package FFI::Echidna::FE::Clang::AST;

use strict;
use warnings;
use 5.020;
use Path::Tiny ();
use PerlX::Maybe;
use JSON::MaybeXS qw( encode_json );
use FFI::Echidna::Location;

# ABSTRACT: Clang AST representation
# VERSION

sub new
{
  my($class, $payload, $previous_location) = @_;

  my $location = do {
    my($path, $line, $column);

    if($previous_location)
    {
      $path   = $previous_location->path;
      $line   = $previous_location->line;
      $column = $previous_location->column;
    }

    my $loc = delete $payload->{loc};

    if($loc)
    {
      $path   = $loc->{file} if defined $loc->{file};
      $line   = $loc->{line} if $loc->{line};
      $column = $loc->{col}  if $loc->{col};
    }

    $path && $loc ? FFI::Echidna::Location->new($path, $line, $column) : undef;
  };

  my @fields = (
    map { maybe $_ => delete $payload->{$_} } qw( id name kind size ),
  );

  my @inner;

  $previous_location = $location;
  foreach my $raw (@{ delete $payload->{inner} // [] })
  {
    my $inner = $class->new($raw, $previous_location);
    $previous_location = $inner->location;
    push @inner, $inner;
  }

  push @fields, inner => \@inner if @inner > 0;
  push @fields, maybe location            => $location,
                maybe is_implicit         => delete $payload->{isImplicit}         ? 1 : 0,
                maybe is_referenced       => delete $payload->{isReferenced}       ? 1 : 0,
                maybe complete_definition => delete $payload->{completeDefinition} ? 1 : 0,
                maybe tag_used            => delete $payload->{tagUsed},
  ;

  foreach my $key (qw( decl ownedTagDecl ))
  {
    my $value = delete $payload->{$key};
    if(defined $value)
    {
      my $name = $key =~ s/([A-Z])/ '_' . lc($1) /reg;
      push @fields, $name => $class->new($value);
    }
  }

  if(defined $payload->{type})
  {
    push @fields, type => FFI::Echidna::FE::Clang::AST::Type->new($payload);
  }

  # don't care.
  delete $payload->{range};

  push @fields, raw => $payload if %$payload;

  bless {
    @fields,
  }, $class;
}

sub id                  { shift->{id}                  }
sub name                { shift->{name}                }
sub kind                { shift->{kind}                }
sub inner               { @{ shift->{inner} // [] }    }
sub size                { shift->{size}                }
sub is_implicit         { shift->{is_implicit}         }
sub is_referenced       { shift->{is_implicit}         }
sub location            { shift->{location}            }
sub complete_definition { shift->{complete_definition} }
sub decl                { shift->{decl}                }
sub owned_tag_decl      { shift->{owned_tag_decl}      }
sub type                { shift->{type}                }
sub tag_used            { shift->{tag_used}            }

sub dump
{
  my($self) = @_;

  my @dump;

  push @dump, do {
    my $first = "[@{[ $self->kind ]}]";
    $first .= ' ( @ ' . $self->location . ' )' if $self->location;
    $first;
  };

  foreach my $key (qw( id type name size is_implicit is_referenced tag_used ))
  {
    my $value = $self->$key;
    if(defined $value)
    {
      push @dump, join(': ', $key, $value);
    }
  }

  if(defined $self->{raw})
  {
    push @dump, 'raw: ' . encode_json($self->{raw});
  }

  foreach my $key (qw( decl owned_tag_decl ))
  {
    my $other = $self->$key;
    next unless defined $other;
    push @dump, '';
    push @dump, "$key:";
    push @dump, $other->dump;
  }

  foreach my $inner ($self->inner)
  {
    push @dump, '';
    push @dump, 'inner:';
    push @dump, $inner->dump;
  }

  map { (' ' x 4) . $_ } @dump;

}

package FFI::Echidna::FE::Clang::AST::Type;

use strict;
use warnings;
use 5.020;
use PerlX::Maybe;
use overload
  '""' => sub { shift->as_string };

sub new
{
  my($class, $payload) = @_;

  my @fields;
  push @fields, maybe qual_type           => delete $payload->{type}->{qualType};
  push @fields, maybe desugared_qual_type => delete $payload->{type}->{desugaredQualType};

  delete $payload->{type} unless %{ $payload->{type} };

  bless { @fields }, $class;
}

sub qual_type           { shift->{qual_type}           }
sub desugared_qual_type { shift->{desugared_qual_type} }

sub as_string
{
  my($self) = @_;
  my $str = $self->qual_type;
  $str .= ' (' . $self->desugared_qual_type . ')' if defined $self->desugared_qual_type;
  $str;
}

1;
