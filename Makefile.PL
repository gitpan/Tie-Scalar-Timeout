require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Tie::Scalar::Timeout',
  VERSION_FROM => 'lib/Tie/Scalar/Timeout.pm',
  dist         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

