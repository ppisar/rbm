#!/usr/bin/perl -w
use strict;
use File::Slurp;
use Test::More tests => 27;
use lib 'lib/';

sub set_target {
    $RBM::config->{run}{target} = [@_];
}

sub set_distribution {
    $RBM::config->{run}{distribution} = $_[0];
}

sub set_step {
    $RBM::config->{step} = $_[0];
}

BEGIN { use_ok('RBM') };
chdir 'test';
RBM::load_config;
ok($RBM::config, 'load config');

my @tests = (
    {
        name => 'simple',
        config => [ 'a', 'option_a' ],
        expected => 'a',
    },
    {
        name => 'project',
        config => [ 'a', 'project_a' ],
        expected => 'a',
    },
    {
        name => 'target',
        target => ['target_a'],
        config => [ 'a', 'option_a' ],
        expected => 'target a',
    },
    {
        name => 'target project',
        target => ['target_b'],
        config => [ 'a', 'option_a' ],
        expected => 'b',
    },
    {
        name => 'triple target - 1',
        target => [ 'target_a', 'target_b', 'target_c' ],
        config => [ 'a', 'option_a' ],
        expected => 'b',
    },
    {
        name => 'triple target - 2',
        target => [ 'target_c', 'target_a', 'target_b' ],
        config => [ 'a', 'option_a' ],
        expected => 'c',
    },
    {
        name => 'target redirect - 1',
        target => [ 'target_d' ],
        config => [ 'a', 'option_a' ],
        expected => 'target a',
    },
    {
        name => 'target redirect - 2',
        target => [ 'target_e' ],
        config => [ 'a', 'option_a' ],
        expected => 'b',
    },
    {
        name => 'target redirect - 3',
        target => [ 'target_f' ],
        config => [ 'a', 'option_a' ],
        expected => 'c',
    },
    {
        name => 'template func c',
        config => [ 'a', 'tmpl_c1' ],
        expected => 'a',
    },
    {
        name => 'template func pc',
        config => [ 'a', 'tmpl_pc1' ],
        expected => 'project b',
    },
    {
        name => 'template func pc + target',
        target => [ 'target_a' ],
        config => [ 'a', 'tmpl_pc1' ],
        expected => 't a',
    },
    {
        name => 'proj target - 1',
        target => [ 'b:target_a' ],
        config => [ 'a', 'option_a' ],
        expected => 'a',
    },
    {
        name => 'proj target - 2',
        target => [ 'b:target_a' ],
        config => [ 'a', 'tmpl_pc1' ],
        expected => 't a',
    },
    {
        name => 'perl sub',
        config => [ 'a', 'option_d/a' ],
        expected => 'A a',
    },
    {
        name => 'step config',
        step => 'build',
        config => [ 'c', 'option_e' ],
        expected => 'build e',
    },
    {
        name => 'redirect step config',
        step => 'redirect',
        config => [ 'c', 'option_e' ],
        expected => 'build e',
    },
    {
        name => 'step + target config',
        step => 'build',
        target => [ 'version_2' ],
        config => [ 'c', 'option_e' ],
        expected => 'build e - v2',
    },
    {
        name => 'srpm step',
        step => 'srpm',
        config => [ 'c', 'option_rpm' ],
        expected => '1',
    },
    {
        name => 'deb-src step',
        step => 'deb-src',
        config => [ 'c', 'option_deb' ],
        expected => '1',
    },
    {
        name => 'build + steps config - 1',
        target => [ 'version_1' ],
        build => [ 'c', 'build' ],
        files => { 'out/c-1' => "1-build e\n" },
    },
    {
        name => 'build + steps and targets config',
        target => [ 'version_2' ],
        build => [ 'c', 'build' ],
        files => { 'out/c-2' => "2-build e - v2\n" },
    },
    {
        name => 'multi-projects build',
        target => [],
        build => [ 'r3', 'build', { pkg_type => 'build' } ],
        files => {
            'out/r1' => "1 - build\n",
            'out/r2' => "1 - build\n2 - build\n",
            'out/r3' => "1 - build\n2 - build\n3 - build\n",
        },
    },
    {
        name => 'mercurial repo',
        target => [],
        config => [ 'mozmill-automation', 't' ],
        expected => '432611daa42c7608d32b04c89ac26fbcea6a61663419aa88ead87116e212a004',
    },
    {
        name => 'mercurial repo build',
        target => [],
        build => [ 'mozmill-automation', 'build' ],
        files => {
            'out/mozmill-automation-bbad7215c713_sha256sum.txt' =>
            '0ef263a660c5021013620b07c5d2c8344a6f6ee579b8aa1edab15f92e36924e8  '
            . "mozmill-automation-bbad7215c713.tar\n",
        },
    },
);

foreach my $test (@tests) {
    set_target($test->{target} ? @{$test->{target}} : ());
    set_step($test->{step} ? $test->{step} : 'init');
    if ($test->{config}) {
        is(
            RBM::project_config(@{$test->{config}}),
            $test->{expected},
            $test->{name}
        );
    }
    if ($test->{build}) {
        unlink keys %{$test->{files}};
        RBM::build_run(@{$test->{build}});
        my $res = grep { read_file($_) ne $test->{files}{$_} } keys %{$test->{files}};
        ok(!$res, $test->{name});
    }
}
