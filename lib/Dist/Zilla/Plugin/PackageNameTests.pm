package Dist::Zilla::Plugin::PackageNameTests;
{
  $Dist::Zilla::Plugin::PackageNameTests::VERSION = '0.003';
}

use strict;
use warnings;

# ABSTRACT: tests to check that the package name matches the file name of your modules

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with    'Dist::Zilla::Role::FileMunger';


# -- attributes

# skiplist - a regex
has skip => ( is=>'ro', predicate=>'has_skip' );


# -- public methods

# called by the filemunger role
sub munge_file {
    my ($self, $file) = @_;

    return unless $file->name eq 't/00-package-names.t';

    my $replacement = ( $self->has_skip && $self->skip )
        ? sprintf( 'return if $found =~ /%s/;', $self->skip )
        : '# nothing to skip';

    # replace the string in the file
    my $content = $file->content;
    $content =~ s/PACKAGENAMETESTS_SKIP/$replacement/;
    $file->content( $content );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 NAME

Dist::Zilla::Plugin::PackageNameTests - tests to check that the package name matches the file name of your modules

=begin Pod::Coverage

munge_file

=end Pod::Coverage

=head1 SYNOPSIS

In your dist.ini:

    [PackageNameTests]
    skip = Test$

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following files:

=over 4

=item * t/00-package-names.t - a standard test to check the package declaration

This test will find all modules in your dist, and check that the package name
is consistent with the file name, e.g. a module found in C<lib/My/Module.pm> should
contain a declaration C<package My::Module>.

=back 

This plugin accepts the following options:

=over 4

=item * skip: a regex to skip the package test for modules matching it. The
match is done against the module name (C<Foo::Bar>), not the file path
(F<lib/Foo/Bar.pm>).

=back 

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__DATA__
___[ t/00-package-names.t ]___
#!perl

use strict;
use warnings;

use Test::Most 'bail';
use File::Find;

sub expected_package_name($) {
  my $file = shift;
  $file =~ s{^.*lib/}{};
  $file =~ s{\.pm$}{};
  $file =~ s/\//::/g;
  return $file;
}

sub found_package_name($) {
  my $file = shift;

  # we assume first package name found is actual
  open my $fh, '<', $file or die "Could not open $file for reading: $!";
  my $package;
  while ( my $line = <$fh> ) {
    next unless $line =~ /^\s*package\s+((?:\w+)(::\w+)*)/;
    return $1;
  }
}

my @files;
find(
  sub {
    my $found = $File::Find::name;
    return unless $found =~ /\.pm\z/ and -f $found;
    PACKAGENAMETESTS_SKIP
    push @files, [ $found, found_package_name $found, expected_package_name $found ];
  },
  'lib',
);

plan tests => scalar( @files ) || 1;

if ( @files ) {
    for my $file ( @files ) {
        my ( $file, $have, $want ) = @$file;
        is $have, $want, "Package name correct for $file";
    }
}
else {
    ok 1, 'no modules to test';
}
