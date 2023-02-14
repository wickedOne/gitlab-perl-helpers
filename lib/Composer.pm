#------------------------------------------------------------------------------
# File:         Composer.pm
#
# Description:  composer related functions.
#               for now only related to the composer classmap file
#
# Revisions:    2023-01-20 - created
#------------------------------------------------------------------------------
package Composer;

use strict;
use warnings FATAL => 'all';

use constant CLASSMAP_FILE => './vendor/composer/autoload_classmap.php';

#------------------------------------------------------------------------------
# Static properties
# classmap contains hash of all relevant classes and their paths
my %classmap = ();

#------------------------------------------------------------------------------
# Construct new class
#
# Returns: reference to Composer object
sub new {
    my ($class, $path) = @_;
    my $self = {};

    bless $self, $class;

    $self->{classmap} = $self->ParseClassMap($path);

    return $self;
}

#------------------------------------------------------------------------------
# Get classmap
#
# Returns: reference to classmap hash
sub GetClassMap {
    my $self = shift;

    return \$self->{classmap};
}

#------------------------------------------------------------------------------
# Match.
# check whether class name lives in code owners paths
#
# Returns: bool
sub Match {
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
sub ParseClassMap {
    my ($self, $path) = @_;
    my %classmap = ();

    open(FH, $path) or die "can't open classmap file $!";

    while (<FH>) {
        chomp $_;
        next unless /\$baseDir\s\./;

        my ($class, $path) = split / => \$baseDir \. /;
        $classmap{strip($class)} = strip($path);
    }

    close(FH);

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