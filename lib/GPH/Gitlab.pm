package GPH::Gitlab;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($class, %args) = @_;

    (exists($args{owner}) and exists($args{codeowners})) or die "$!";

    my $self = {
        owner      => $args{owner},
        file       => $args{codeowners},
        codeowners => undef,
        blacklist  => undef,
    };

    bless $self, $class;

    return $self->parseCodeowners(%args);
}

sub parseCodeowners {
    my ($self, %args) = @_;
    my ($fh, %excludes, $default_owners);

    open $fh, '<', $args{codeowners} or die "unable to open codeowners file: $!";
    my @lines = <$fh>;
    close($fh);

    # build excludes hash for quick lookup
    if (exists($args{excludes})) {
        foreach my $item (@{$args{excludes}}) {
            $excludes{$item} = 1;
        }
    }

    foreach (@lines) {
        next if $_ =~ /^#.*/ or $_ =~ /^[\s]?$/;
        my $line = $self->sanitise($_);

        if ($line =~ /\]/) {
            $default_owners = ($line =~ /^[\^]?\[[^\]]+\](?:[\[0-9\]]{0,}) (.*)$/) ? $1 : undef;

            next;
        }

        my ($class_path, $owners) = split(/\s/, $line, 2);

        next if exists $excludes{$class_path};

        $owners = $owners || $default_owners;

        next unless defined $owners;

        foreach my $owner (split(/\s/, $owners)) {
            next unless $owner =~ /@/;
            if (not exists $self->{codeowners}{$owner}) {
                $self->{codeowners}{$owner} = [];
                $self->{blacklist}{$owner} = [];
            }

            push(@{$self->{codeowners}{$owner}}, $class_path);

            $self->blacklist($class_path);
        }
    }

    return ($self);
}

sub blacklist {
    my ($self, $class_path) = @_;

    foreach my $owner (keys %{$self->{codeowners}}) {
        foreach my $path (@{$self->{codeowners}{$owner}}) {
            if ($class_path =~ $path and $class_path ne $path) {
                push(@{$self->{blacklist}{$owner}}, $class_path);
            }
        }
    }

    return ($self);
}

sub sanitise {
    my ($self, $line) = @_;

    my $pat = quotemeta('/**/* ');
    $line =~ s|$pat|/ |;

    return ($line);
}

sub getPaths {
    my $self = shift;

    return $self->{codeowners}->{$self->{owner}} || [];
}

sub getBlacklistPaths {
    my $self = shift;

    return $self->{blacklist}->{$self->{owner}} || [];
}

sub getCommaSeparatedPathList {
    my $self = shift;

    return join(",", @{$self->getPaths()});
}

sub intersectCommaSeparatedPathList {
    my ($self, @paths) = @_;

    return join(",", $self->intersect(@paths));
}

sub intersect {
    my ($self, @paths) = @_;
    my @diff;

    foreach my $path (@paths) {
        chomp $path;

        next unless $self->match($path);
        next if $self->matchBlacklist($path);

        push(@diff, $path);
    }

    return @diff;
}

sub match {
    my ($self, $path) = @_;

    foreach my $owner (@{$self->getPaths()}) {
        return 1 if $path =~ $owner;
    }

    return 0;
}

sub matchBlacklist {
    my ($self, $path) = @_;

    foreach my $owner (@{$self->getBlacklistPaths()}) {
        return 1 if $path =~ $owner;
    }

    return 0;
}

1;

__END__

=head1 NAME

GPH::Gitlab - parse and process L<Gitlab|https://about.gitlab.com/> CODEOWNER file

=head1 SYNOPSIS

    use GPH::Gitlab;

    my $gitlab = GPH::Gitlab->new((
        owner      => '@teams/alpha',
        codeowners => './CODEOWNERS,
    ));

    my $paths $phpmd->getPaths();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Gitlab instance. it takes a hash of options, valid option keys include:

=over

=item owner B<(required)>

code owner name

=item codeowners B<(required)>

path to CODEOWNER file

=item excluded

list of paths defined in the CODEOWNER file for given owner, but to ignore

=back

=item C<< -E<gt>getPaths() >>

returns array of paths for given codeowner

=item C<< -E<gt>getBlacklistPaths() >>

returns array of paths which are blacklisted for given codeowner (based on gitlab's "more specific code owner" principle)

=item C<< -E<gt>match($path) >>

match C<$path> with paths defined for given codeowner. returns C<1> on hit, C<0> on miss

=item C<< -E<gt>matchBlacklist($path) >>

match C<$path> with blacklisted paths defined for given codeowner. returns C<1> on hit, C<0> on miss

=item C<< -E<gt>getCommaSeparatedPathList() >>

returns string of comma separated paths, typically used in C<--filter> options of quality tools

=item C<< -E<gt>intersect(@paths) >>

returns intersected array of given C<@paths> and paths defined for given code owner while not defined as blacklisted

=item C<< -E<gt>intersectCommaSeparatedPathList(@paths) >>

returns comma separated string of intersected C<@paths>

=item C<< -E<gt>sanitise($line) >> B<(internal)>

replace /**/* with a trailing forward slash

=item C<< -E<gt>blacklist($class_path) >> B<(internal)>

adds C<$class_path> to blacklists if applicable

=item C<< -E<gt>parseCodeowners(%args) >> B<(internal)>

parse CODEOWNERS file. it takes a hash of options, valid option keys include:

=over

=item codeowners B<(required)>

path to CODEOWNER file

=back

=back

=head1 CAVEATS

currently not all syntax from gitlab's CODEOWNERS file is supported. unsupported at the moment are:

=over 1

=item *

relative & globstar paths (.md )

=item *

wildcard default owner (* @default)

=item *

escaped pound signs (\#)

=item *

single nested paths ('/*')

=item *

paths with spaces

=back

=head1 AUTHOR

the GPH::PHPMD module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut