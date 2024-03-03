package GPH::Util::Php;

use strict;
use warnings FATAL => 'all';

use Cwd;
use Data::Dumper;

sub new {
    my ($proto) = @_;

    return bless {
        'types' => {},
    }, $proto;
};

sub types {
    my ($self, @files) = @_;
    my ($fh, $pattern, $constant);

    foreach my $file (@files) {
        chomp $file;
        next unless $file =~ '[/]{0,}([^/]+)\.php$';
        open($fh, '<', getcwd() . '/' . $file) or die "unable to open file $file : $!";

        $pattern = "[ ]{0,}([^ ]+) " . $1 . "(?:[ :]|\$){1,}";
        $constant = $1 . "::class";

        while(<$fh>) {
            chomp $_;
            next if $_ =~ /^[\* ]\*/; #ignore comments
            next if $_ =~ $constant;
            next unless $_ =~ $pattern;
            my $type = ($1 ne 'enum') ? $1 : $self->resolveEnum(<$fh>);

            $self->{'types'}->{$type} = [] unless exists($self->{'types'}->{$type});

            push(@{$self->{'types'}->{$type}}, $file);

            last();
        }

        close($fh);
    }

    return($self);
};

sub resolveEnum {
    my ($self, @lines) = @_;

    foreach my $line (@lines) {
        return 'method_enum' if $line =~ / function [^ ]{1,}[ ]{0,}\(/;
    }

    return 'enum';
};

sub reduce {
    my ($self, %args) = @_;

    (exists($args{paths}) and exists($args{excludes})) or die $!;

    $self->types(@{$args{paths}});

    my %exclude = map{$_ => 1} @{$args{excludes}};
    my @result;

    foreach my $key (keys %{$self->{types}}) {
        push(@result, @{$self->{types}->{$key}}) unless defined $exclude{$key};
    }

    return(@result);
};

1;

__END__

=head1 NAME

GPH::Util::Php - php related util methods

=head1 SYNOPSIS

    use GPH::Util::Php;

    my $stats = GPH::Util::Php->new();

    $stats->types(<STDIN>);

=head1 METHODS

=over 4

=item C<< -E<gt>new(%args) >>

the C<new> method returns a php object.

=item C<< -E<gt>types(@paths) >>

scans file content of given php files in C<@paths> and tries to determine their type (e.g. class, interface, trait, enum)

=item C<< -E<gt>resolveEnum(@lines) >>

scans C<<  @lines >> for the presence of a method and returns the 'method_enum' type if found, otherwise 'enum' is returned.

this for instance can be particularly useful when creating a filter for infection testing as no mutants can be generated
for a (backed) enum, but they can when the enum contains methods.

=item C<< -E<gt>reduce(%args) >>

the reduce method takes a hash of options, valid option keys include:

=over

=item paths B<(required)>

file paths to scan. must be relative to the path where the script is executed

=item excludes B<(required)>

class type(s) to exclude from the list

=back

calls the C<< -E<gt>types(@paths) >> method with given paths after which it returns an array of paths for files with
different types than the excluded types.

=back

=head1 AUTHOR

the GPH::Util::Php module was written by wicliff wolda <wicliff.wolda@gmail.com>

=head1 COPYRIGHT AND LICENSE

this library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
