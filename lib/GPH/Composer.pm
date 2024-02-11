#------------------------------------------------------------------------------
# File:         GPH::Composer.pm
#
# Description:  composer related functions.
#               for now only related to the composer classmap file
#
# Revisions:    2023-01-20 - created
#               2024-02-10 - namespaced module, bugfixes and unit tests
#------------------------------------------------------------------------------
package GPH::Composer;

use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Construct new class
#
# Returns: reference to GPH::Composer object
sub new {
    my ($class, $path) = @_;
    my $self = {};

    bless $self, $class;

    $self->{classmap} = $self->parseClassMap($path);

    return $self;
}

#------------------------------------------------------------------------------
# Get classmap
#
# Returns: reference to classmap hash
sub getClassMap {
    my $self = shift;

    return \$self->{classmap};
}

#------------------------------------------------------------------------------
# Match.
# check whether class name lives in code owners paths
#
# Returns: bool
sub match {
    my ($self, $class, @paths) = @_;

    if (not defined $self->{classmap}->{$class}) {
        return 0;
    }

    foreach (@paths) {
        return 1 if $self->{classmap}->{$class} =~ /^[\/]?$_.*$/;
    }

    return 0;
}

#------------------------------------------------------------------------------
# Parse composer classmap with relevant paths (vendor dir is ignored)
#
# Returns: hash reference with ${classname} => $path 
sub parseClassMap {
    my ($self, $path) = @_;
    my %classmap = ();

    open(my $fh, '<', $path) or die "can't open classmap file $!";

    my @lines = <$fh>;

    close($fh);

    for my $line (@lines) {
        next unless $line =~ /\$baseDir\s\./;

        my ($class, $code_path) = split(/ => \$baseDir \. /, $line);
        $classmap{strip($class)} = strip($code_path);
    }

    close($fh);

    return (\%classmap);
}

#------------------------------------------------------------------------------
# cleanup leading & trailing spaces, escaped backslashes and quotes
#
# Returns: string
sub strip {
    my ($line) = @_;

    $line =~ s/^\s+|\s+$//g;
    $line =~ s/[',]//g;
    $line =~ s/\\\\/\\/g;

    return $line;
}

1;