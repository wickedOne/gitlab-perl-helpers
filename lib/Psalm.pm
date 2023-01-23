#------------------------------------------------------------------------------
# File:         Psalm.pm
#
# Description:  pslam related functions.
#               for now only generate psalm config file
#
# Revisions:    2023-01-21 - created
#------------------------------------------------------------------------------

package Psalm;

use strict;
use warnings;

use Data::Dumper;

my @ingnoredDefault = qw(vendor data app var);

#------------------------------------------------------------------------------
# Construct new class
#
# Returns: reference to Psalm object
sub new {
  my ($class, $level, $paths, $baseline, $ignoredFiles) = @_;
  
  my $self = {
    level => $level || 4,
    ignoredFiles => $ignoredFiles || \@ingnoredDefault,
    paths => $paths || ['src'],
    baseline => $baseline,
  };
  
  bless $self, $class;

  return $self;
}

#------------------------------------------------------------------------------
# Get config
#
# Returns: psalm.xml config file as string
sub GetConfig {
  my $self = shift;
  
  my $config = "<?xml version=\"1.0\"?>
<psalm
    errorLevel=\"$self->{level}\"
    resolveFromConfigFile=\"true\"
    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
    xmlns=\"https://getpsalm.org/schema/config\"
    xsi:schemaLocation=\"https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd\"\n";

  if (defined $self->{baseline}) {
    $config .= "    errorBaseline=\"$self->{baseline}\"\n";
  }
  
  $config .= q(    cacheDirectory="var/cache/psalm"
  >
      <issueHandlers>
          <TooManyArguments>
              <errorLevel type="suppress">
                  <referencedFunction name="Doctrine\DBAL\Query\QueryBuilder::select" />
                  <referencedFunction name="Doctrine\ORM\Query\Expr::andX" />
                  <referencedFunction name="Doctrine\ORM\Query\Expr::orX" />
                  <referencedFunction name="Doctrine\Common\Collections\ExpressionBuilder::andX" />
              </errorLevel>
          </TooManyArguments>
      </issueHandlers>
      <projectFiles>");
  
  foreach my $path (@{$self->{paths}}) {
    $config .= "\n        <directory name=\"$path\" />";
  }
  
  $config .= "\n        <ignoreFiles>";
  
  foreach my $path (@{$self->{ignoredFiles}}) {
    $config .= "\n            <directory name=\"/$path\" />";
  }
  
  $config .= "\n        </ignoreFiles>
      </projectFiles>
  </psalm>
  ";

  return ($config);
}

1;