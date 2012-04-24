package Dist::Zilla::PluginBundle::Author::HTGT;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

# skip these dependencies
has skip_deps => (
    is  => 'ro',
    isa => 'Maybe[Str]',
    lazy => 1,
    default => sub { $_[0]->payload->{skip_deps} || '' },
);

# skip these files
has skip_files => (
    is  => 'ro',
    isa => 'Maybe[Str]',
    lazy => 1,
    default => sub { $_[0]->payload->{skip_files} || '' },
);

sub configure {
    my $self = shift;

    $self->add_bundle(
        '@Filter' => {
            '-bundle' => '@Basic',
            '-remove' => [ 'UpleadToCPAN' ],
        }
    );

    $self->add_plugins(
        [
            'AutoPrereqs' => {
                length $self->skip_deps ? ( 'skip' => [ $self->skip_deps ] ) : ()
            }
        ],
        'Test::Compile',
        'NoSmartCommentsTests',
        'PackageNamesTests',
        'PkgVersion',
        'NextRelease',
        'FakeRelease',
        [
            'PruneFiles' => {
                'filenames' => 'dist.ini',
                length $self->skip_files ? ( 'match' => [ $self->skip_files ] ) : ()
            }
        ],
        'Git::NextVersion',
        [
            'Git::CommitBuild' => {
                branch          => '',                
                release_branch  => 'releases',
                release_message => ( $self->_get_changes || 'Build results of %h on %b' )
            }
        ],
        # CommitBuild -must- come before these
        'Git::Check',
        'Git::Commit',
        [
            'Git::Tag' => {
                branch => 'releases'
            }
        ],
        'Git::Push',
    );

}

# stolen from Dist::Zilla::Plugin::Git::Commit
sub _get_changes {
    my $self = shift;

    # parse changelog to find commit message
    my $changelog = Dist::Zilla::File::OnDisk->new( { name => 'Changes' } );
    my $newver    = '{{\$NEXT}}';
    my @content   =
        grep { /^$newver(?:\s+|$)/ ... /^\S/ } # from newver to un-indented
        split /\n/, $changelog->content;
    shift @content; # drop the version line
    # drop unindented last line and trailing blank lines
    pop @content while ( @content && $content[-1] =~ /^(?:\S|\s*$)/ );

    # return commit message
    return join("\n", @content, ''); # add a final \n
} # end _get_changes

__PACKAGE__->meta->make_immutable;
no Moose;
1;


=pod

=head1 DESCRIPTION

This is the plugin bundle that HTGT uses. It is equivalent to:

 [@Filter]
 -bundle = @Basic
 -remove = Readme

 [AutoPrereqs]

 [Test::Compile]

 [NoSmartCommentsTests]

 [PackageNamesTests]

 [PkgVersion]

 [NextRelease]

 [FakeRelease]

 [PruneFiles]
 filename = dist.ini

 [Git::NextVersion]

 [Git::CommitBuild]
 branch          =
 release_branch  = releases
 release_message = <changelog section content>

 [Git::Check]

 [Git::Commit]

 [Git::Tag]

 [Git::Push]

=head1 CONFIGURATION

If you provide a value to the C<skip_deps> option then it will be passed to
the C<AutoPrereqs> Plugin as the C<skip> attribute.

If you provide a value to the C<skip_files> option then it will be passed to
the C<PruneFiles> Plugin as the C<match> attribute.

=head1 TIPS

Do not include a C<NAME>, C<VERSION>, C<AUTHOR> or C<LICENSE> POD section in
your code, they will be provided automatically.

The bundle is desgined for projects which are hosted on C<github>.
More so, the project should have a C<master> branch where you do code
development, and a separete 'releases' branch which is where the
I<built> code is committed.

=head1 AUTHOR

Ray Miller <raym@cpan.org>, based on code and ideas from Dist::Zilla::PluginBundle::Author::OLIVER.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ray Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

