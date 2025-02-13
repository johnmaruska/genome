#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use File::Path;
use File::Temp;
use Test::More;
use above 'Genome';
use Genome::SoftwareResult;
use Genome::Test::Factory::SoftwareResult::User;

Genome::Config::set_env('workflow_builder_backend', 'inline');

plan skip_all => 'version 2.6 not available right now.';

my $archos = `uname -a`;
if ($archos !~ /64/) {
    plan skip_all => "Must run from 64-bit machine";
}

my @chromosomes_to_test = (21, 22);
use_ok('Genome::Model::Tools::DetectVariants2::MethRatio');

my $refbuild_id = 106942997;
my $ref_seq_build = Genome::Model::Build::ImportedReferenceSequence->get($refbuild_id);
ok($ref_seq_build, 'human37 reference sequence build') or die;

my $testbam =  Genome::Config::get('test_inputs') . "/Genome-Model-Tools-DetectVariants2-MethRatio/test.bam";

my $tmpbase = File::Temp::tempdir('MethRatioXXXXX', CLEANUP => 1, TMPDIR => 1);
my $tmpdir = "$tmpbase/output";

my $result_users = Genome::Test::Factory::SoftwareResult::User->setup_user_hash(
    reference_sequence_build => $ref_seq_build,
);

my $methratio = Genome::Model::Tools::DetectVariants2::MethRatio->create(
    chromosome_list => \@chromosomes_to_test,
    aligned_reads_input=>$testbam, 
    reference_build_id => $refbuild_id,
    output_directory => $tmpdir, 
    aligned_reads_sample => "TEST",                            
    version => '2.6',
    result_users => $result_users,
);

ok($methratio, 'methratio command created');

ok($methratio->default_chromosomes_as_string =~ /^1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X,Y,MT/, 'chromosomes are sorted correctly') || die;

$methratio->dump_status_messages(1);
my $rv = $methratio->execute;
is($rv, 1, 'Testing for successful execution.  Expecting 1.  Got: '.$rv);

my $output_snv_file = $methratio->output_directory . "/snvs.hq";


ok(-s $output_snv_file,'Testing success: Expecting a snv output file exists');

# Look for the result
my $result = $methratio->_result;
ok($result, "Got a software result");

is ($result->chromosome_list, join(",",@chromosomes_to_test), "Chromosome list from the software result is as expected");

done_testing();
