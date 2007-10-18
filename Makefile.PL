use inc::Module::Install;
name 'Tie-Scalar-Timeout';
all_from 'lib/Tie/Scalar/Timeout.pm';
perl_version '5.006';

requires 'Time::Local';

build_requires 'Test::More' => '0.70';

use_standard_tests;
auto_include;
WriteAll;
