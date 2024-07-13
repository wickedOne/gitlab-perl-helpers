package GPH::PHPUnit::Teardown;

use strict;
use warnings FATAL => 'all';

use GPH::PHPUnit::Teared;

sub new {
    my ($proto, %args) = @_;

    exists($args{files}) or die "file must be defined: $!";

    my $self = bless {
        files  => $args{files},
        debug  => $args{debug} // 0,
        strict => $args{strict} // 0,
        teared => {},
    }, $proto;

    return ($self);
}

sub parse {
    my ($self) = @_;
    my ($fh);

    foreach my $file (@{$self->{files}}) {
        next unless $file =~ /Test|TestCase$/;

        open($fh, '<', $file) or die "$!";

        print "processing file: $file\n" unless $self->{debug} == 0;

        my $teardown = 0;
        my %properties = ();
        my %teared = ();
        my $in_teardown = 0;
        my $seen_test = 0;

        while (<$fh>) {
            chomp $_;

            # ignore comments and blank lines
            next if $_ =~ /^[\s]{0,}[\/]{0,1}[\*]{1,2}/ or $_ eq '' or $_ =~ /^[\s]*\/\//;

            # collect properties. strict mode uses all properties while in non strict mode non initialized & empty properties are used
            my $pattern = $self->{strict} == 0
                ? '^[\s]*(?:private|public|protected)\s(?:static ){0,}([^\s]{0,})\s*\$([^\s;]+(?=;|\s=\s(?:\[\]|null)))'
                : '^[\s]*(?:private|public|protected)\s(?:static ){0,}([^\s]{0,})\s*\$([^\s;]+)';

            if ($seen_test == 0 && $_ =~ /$pattern/) {
                $properties{$2} = $1;
                print "  property: $2 type: $1\n" unless $self->{debug} == 0;

                next;
            }

            # assuming class properties are not defined all over the place
            if ($_ =~ 'public function test') {
                $seen_test = 1;
            }

            # check teardown methods
            if ($_ =~ '([\s]+)(?:protected |public )function tearDown\(\): void'
                or $_ =~ '([\s]+)(?:protected |public )static function tearDownAfterClass\(\): void'
            ) {
                $teardown = 1;
                $in_teardown = 1;
                my $spaces = $1;

                print "  has teardown\n" unless $self->{debug} == 0;

                while ($in_teardown == 1) {
                    my $line = <$fh>;
                    chomp $line;

                    my @matches = $line =~ /\$this->(\w+(?=(?:[ ,\)]|$)))/g;
                    my @statics = $line =~ /self::\$(\w+(?=(?:[ ,]|$)))/g;

                    foreach my $match (@matches, @statics) {
                        print "  property: $match was found in teardown\n" unless $self->{debug} == 0;
                        $teared{$match} = 1;
                    }

                    if ($line =~ /$spaces}$/) {
                        $in_teardown = 0;
                        last;
                    }
                }
            }
        }

        close($fh);

        $self->{teared}{$file} = GPH::PHPUnit::Teared->new((
            file       => $file,
            teardown   => $teardown,
            properties => \%properties,
            teared     => \%teared,
        ));
    }

    return ($self);
};

sub validate {
    my ($self) = @_;
    my $exit = 0;

    foreach my $teared (sort keys %{$self->{teared}}) {
        if ($self->{teared}{$teared}->isValid() != 1 && $exit == 0) {
            $exit = 1;
        }
    }

    return ($exit);
};

1;

__END__

=head1 NAME

GPH::PHPUnit::Teardown - module to validate correct teardown behaviour of PHPUnit test classes.

see https://docs.phpunit.de/en/10.5/fixtures.html#more-setup-than-teardown for further information

=head1 SYNOPSIS

    use GPH::PHPUnit::Teardown;

    my $teardown = GPH::PHPUnit::Teardown->new((files => ['foo.php', 'bar.php'], debug => 1);
    $teardown->parse();

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method returns a GPH::PHPUnit::Teardown object. it takes a hash of options, valid option keys include:

=over

=item files B<(required)>

an array of file paths of files which you'd like to analyse.

=item debug

boolean whether or not to debug the parsing process.

=item strict

boolean whether or not to parse in strict mode (i.e. use all class properties regardless of initialisation state).

=back

=item C<< -E<gt>parse() >>

parse the files defined in C<< $self->{files} >>

=item C<< -E<gt>validate() >>

validate the parsed files. returns exit code 0 when all files are valid, 1 if one or more files are invalid

=back

=head1 AUTHOR

the GPH::PHPUnit::Teardown module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
