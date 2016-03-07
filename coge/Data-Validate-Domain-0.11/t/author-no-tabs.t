
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Data/Validate/Domain.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Data-Validate-Domain.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-no404s.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-tidyall.t'
);

notabs_ok($_) foreach @files;
done_testing;
