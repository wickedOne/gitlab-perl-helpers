package GPH::Composer;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($class, %args) = @_;

    exists($args{classmap}) or die "$!";

    my $self = {};

    bless $self, $class;

    $self->parseClassMap($args{classmap});

    return $self;
}

sub getClassMap {
    my $self = shift;

    return \$self->{classmap};
}

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

sub parseClassMap {
    my ($self, $path) = @_;
    my %classmap = ();

    open(my $fh, '<', $path) or die "can't open classmap file $!";

    my @lines = <$fh>;

    close($fh);

    for my $line (@lines) {
        next unless $line =~ /\$baseDir\s\./;

        my ($class, $code_path) = split(/ => \$baseDir \. /, $line);
        $self->{classmap}{strip($class)} = strip($code_path);
    }
}

sub strip {
    my ($line) = @_;

    $line =~ s/^\s+|\s+$//g;
    $line =~ s/[',]//g;
    $line =~ s/\\\\/\\/g;

    return $line;
}

1;

__END__

=head1 NAME

GPH::Composer - parses and matches paths with a L<Composer|https://getcomposer.org/> classmap

=head1 SYNOPSIS

    use GPH::Composer;

    my $composer = GPH::PHPMD->new((
        classmap => './vendor/composer/autoload_classmap.php',
    ));

    print $composer->match('App\Service\Provider\FooProvider.php', ['/src/Service/Provider/']);

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method creates a new GPH::Composer instance. it takes a hash of options, valid option keys include:

=over

=item classmap B<(required)>

path to classmap file

=back

=item C<< -E<gt>match($class, @paths) >>

matches a FQCN to the classmap limited by a collection of paths. returns C<1> on hit C<0> on miss.

=item C<< -E<gt>getClassMap() >>

returns reference to the parsed classmap hash.

=item C<< -E<gt>parseClassMap() >> B<(internal)>

parses the classmap file with relevant paths (vendor dir is ignored) and stores it in a hash map.

=item C<< -E<gt>strip($line) >> B<(internal)>

cleanup leading & trailing spaces, escaped backslashes and quotes.

=back

=head1 AUTHOR

the GPH::Composer module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut