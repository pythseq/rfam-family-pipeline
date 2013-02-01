package Bio::Rfam::Infernal;

#TODO: add pod documentation to all these functions

# Wrappers for Infernal executables called by rfsearch and rfmake.

use strict;
use warnings;
use Sys::Hostname;
use File::stat;

use Cwd;
use Data::Dumper;
use Mail::Mailer;
use File::Copy;
use vars qw( @ISA
             @EXPORT
);

@ISA    = qw( Exporter );


#cmBuild:
sub cmBuild {
    my ($cmbuildPath, $cmFile, $seedFile, $version, $name) = @_;
    my $nameCmd = '';
    $nameCmd = " -n $name " if (defined $name && length($name)>0);
    
    #build CM
    unlink $cmFile if -e $cmFile;
    open(CMB, "$cmbuildPath $nameCmd -F $cmFile $seedFile | ") or die "FATAL: failed to open pipe for cmbuild $nameCmd -F  $cmFile $seedFile\n[$!]";
    my $ok=0;
    while(<CMB>){
	if(/INFERNAL $version/){
	    $ok=1;
	}
    }
    close(CMB);
    die "FATAL: what version of Infernal are you running? It is not $version!" if not $ok;
    return 1;
}

#cmCalibrate: takes a CM file and runs cmcalibrate on the Sanger farm using MPI

#Systems MPI help documentation:
#http://scratchy.internal.sanger.ac.uk/wiki/index.php/How_to_run_MPI_jobs_on_the_farm

sub cmCalibrate {
    my $cmcalibratePath = shift; # path to cmcalibrate
    my $cm              = shift; #Handed a CM file generated by cmbuild
    my $lustre          = shift;#Farm dir
    my $pwd             = shift;   #Work dir
    my $debug = shift;
    my $bigmem = shift;
    my $cpus; 
    $cm = "CM" if not defined $cm; #This only works if working from a home directory... 
    die "cmfile \42$cm\42 either does not exist or is empty!" if !(-s $cm);
    
    #Want a runtime less than $preferedRunTime minutes: 
    $cpus = $maxCpus if $cpus>$maxCpus;
    if($cpus < 2) $cpus = 2;

    #TODO take original RfamSearch code and use it to predict memory and cpu requirements

    #Generate a MPI script:
    my $mpiScript = "#!/bin/bash
# An OPENMPI LSF script for running cmcalibrate
# Submit this script via bsub to use.
 
# Parse the LSF hostlist into a format openmpi understands and find the number of CPUs we are running on.

# Now run our executable 
$cmcalibratePath $lustre/$cm
";

    my $mpiScriptFile = $lustre . '/' . $cm . '.' . $$ . '_mpi_script.sh';#be cleverer here
    open(MS, "> $mpiScriptFile") or die "FATAL: failed to open file: $mpiScriptFile\n[$!]";
    print MS $mpiScript;
    close(MS);

    chmod 0775,  $mpiScriptFile or die "FATAL: failed to run [chmod 0775,  $mpiScriptFile]\n[$!]";
    
    my $mpiScriptOut =  $cm . '.' . $$ . '_mpi_script.out';
    my $bjobName = "cmcal" . $$;
    my $bsubOpts;
    if (defined $bigmem) {
	    	$bsubOpts = "-o $lustre/$mpiScriptOut -R \"span[ptile=4]\" -q production-rh6 -a mpi -M3500000 -R\"select[mem>3500] rusage[mem=3500]\"  -J\"$bjobName\" -n$cpus -R\'select[model==BL460C_G6]\'";
	} else {
		#$bsubOpts = "-o $lustre/$mpiScriptOut -q long  -J\"$bjobName\" -n$cpus -R\'select[model==HS21_E5450_8]\' -R \'select[mem>1000] rusage[mem=1000]\' -M 1000000";
		$bsubOpts = "-o $lustre/$mpiScriptOut -q production-rh6  -J\"$bjobName\" -n$cpus -R \'select[mem>1500] rusage[mem=1500]\' -M 1500000";
		} 
	print "Running: bsub $bsubOpts $mpiScriptFile\n";
    system("bsub $bsubOpts $mpiScriptFile > $pwd/$mpiScriptOut\.std") and die "FATAL: failed to run to run: bsub $bsubOpts $mpiScriptFile\n[$!]";
    $debug = 'cmcalibrate' if defined $debug;
    Bio::Rfam::Utils::wait_for_farm($bjobName, 'cmcalibrate', $cpus ); #wait an extra few mins then the job will be killed, assuming MPI+Farm badness.
    
    copy( "$lustre/$cm", "$pwd/$cm" ) or die "FATAL: failed to copy $lustre/$cm to $pwd/$cm\n[$!]";
    copy("$lustre/$mpiScriptOut", "$pwd/$mpiScriptOut") or die "FATAL: failed to copy $lustre/$mpiScriptOut to $pwd/$mpiScriptOut\n[$!]";

    open(MPIOUT, "< $pwd/$mpiScriptOut") or die "FATAL: failed to open $pwd/$mpiScriptOut for reading\n[$!]";
    
    my $calibrateTime=0;
    while(<MPIOUT>){
	if(/\#\s+CPU\s+time\:\s+(\S+)u\s+(\S+)s/){
	    $calibrateTime=$1+$2;
	    last;
	}
    }
    close(MPIOUT);
    
    return $calibrateTime;
}

################################

#cmAlign: takes a CM and sequence file and runs cmalign, either locally or on the farm using MPI

#Systems MPI help documentation:
#http://scratchy.internal.sanger.ac.uk/wiki/index.php/How_to_run_MPI_jobs_on_the_farm

# For MPI to work, you need to make sure Infernal has been compiled correctly, with --enable-mpi flag to configure.
# See Infernal user's guide. It should be compiled correctly, or else rfsearch wouldn't work (MPI cmcalibrate is used there).
# Also, ssh keys need to be correct. Remove all ^"bc-*" entries from your ~/.ssh/known_hosts file.
# Optionally add "StrictHostKeyChecking no" to your ~/.ssh/config

sub cmAlign {
    my $cmalignPath = shift; #Path to cmalign
    my $cmfile      = shift; #Handed a CM file
    my $seqfile     = shift; #sequence file with seqs to align
    my $alnfile     = shift; #alignment output file 
    my $outfile     = shift; #cmalign output file 
    my $opts        = shift; #string of cmalign options
    my $nseq        = shift; #number of sequences in $seqfile
    my $tot_len     = shift; #total number of nucleotides in $seqfile
    my $always_farm = shift; # 1 to always use farm, 0 to only use farm if > 4 CPUs needed
    my $never_farm  = shift; # 0 to never  use farm, 1 to only use farm if > 4 CPUs needed
    my $dirty       = shift; # 1 to leave files on farm, else remove them 

    my @unlinkA = ();

    die "cmfile \42$cmfile\42 either does not exist or is empty!" if !(-s $cmfile);

    ####################################################################
    # Predict running time and memory requirement of cmalign
    # and use them to determine number of CPUs for MPI cmcalibrate call.
    ####################################################################
    # Get a rough estimate of running time on 1 CPU based on $tot_len (passed in)
    my $sec_per_Kb = 4;
    my $estimatedCpuSeconds = ($tot_len / 1000.) * $sec_per_Kb;

    # Determine number of CPUs to use: target running time is 1 minute.
    my $targetSeconds = 60;
    my $cpus = int($estimatedCpuSeconds / $targetSeconds) + 1;
    my $farm_max_ncpu  = 27; # (1028 * 27) = 27,756 (max memory usage is 28 Gb for any 1 job, cmalign requires up to 1028 Mb per CPU...)
    my $farm_min_ncpu  = 4;
    my $local_max_ncpu = 4;
    my $local_min_ncpu = 2;

    my $use_farm;
    if   ($always_farm) { $use_farm = 1; }
    elsif($never_farm)  { $use_farm = 0; }
    elsif($cpus > 4)    { $use_farm = 1; }
    else                { $use_farm = 0; }
	
    if($use_farm) { 
	if($cpus > $farm_max_ncpu) { $cpus = $farm_max_ncpu; }
	if($cpus < $farm_min_ncpu) { $cpus = $farm_min_ncpu; }
    }
    else { 
	if($cpus > $local_max_ncpu) { $cpus = $local_max_ncpu; }
	if($cpus < $local_min_ncpu) { $cpus = $local_min_ncpu; }
    }

    my $estimatedWallSeconds = $estimatedCpuSeconds / $cpus;

    # Memory requirement is easy, cmalign caps DP matrix size at 1024 Mb
    my $requiredMb = $cpus * 1024.0;

    my $hrs = int($estimatedWallSeconds/3600);
    my $min = int(($estimatedWallSeconds - ($hrs * 3600)) / 60);
    my $sec = int($estimatedWallSeconds - ($hrs * 3600 + $min * 60));
    
    my $rounded_requiredMb = 500;
    # pick smallest 500 Mb multiple that satisfies required memory estimate
    while($rounded_requiredMb < $requiredMb) { 
	$rounded_requiredMb += 500; 
    }
    $requiredMb = $rounded_requiredMb;
    my $requiredKb = $requiredMb * 1000;

    printf("Aligning %7d sequences %s on %d cpus; predicted time (h:m:s): %02d:%02d:%02d %s", 
	   $nseq, 
	   ($use_farm) ? "on farm" : "locally",
	   $cpus, $hrs, $min, $sec+0.5, 
	   ($use_farm) ? "\n" : " ... ");

    if(! $use_farm) { 
	# run locally
	# NOWTODO update with config infernal path, probably need to change cmAlign() subroutine args
	my $command = "$cmalignPath --cpu $cpus $opts -o $alnfile $cmfile $seqfile > $outfile";
	system("$command");
	if($?) { die "FAILED: $command"; }
	printf("done.\n");
	open(OUT, $outfile);
    }
    else { 
	# run on farm with MPI 
	# create directory on lustre to use, copy CM and seqfile there:
	my $user =  getlogin() || getpwuid($<);
	my $pwd = getcwd;
	die "FATAL: failed to run [getlogin or getpwuid($<)]!\n[$!]" if not defined $user or length($user)==0;
	my $lustre = "$Rfam::scratch_farm/$user/$$"; #path for dumping data to on the farm
	mkdir("$lustre") or die "FATAL: failed to mkdir [$lustre]\n[$!]";

	# don't worry about calling 'lfs setstripe' here like we do in rfsearch.pl
	# because we won't be accessing a few very large files only (see: http://scratchy.internal.sanger.ac.uk/wiki/index.php/Farm_II_User_notes#Striping_options)

	my $lustre_cmfile  = "$lustre/CM";
	my $lustre_seqfile = "$lustre/$seqfile";
	my $lustre_alnfile = "$lustre/$alnfile";
	my $lustre_outfile = "$lustre/$outfile";
	copy("$cmfile",  "$lustre_cmfile") or die "FATAL: failed to copy [$cmfile] to [$lustre_cmfile]\n[$!]";
	copy("$seqfile", "$lustre_seqfile") or die "FATAL: failed to copy [$seqfile] to [$lustre_seqfile]\n[$!]";
	push(@unlinkA, $lustre_cmfile);
	push(@unlinkA, $lustre_seqfile);

	my $alignCommand = "mpirun --mca mpi_paffinity_alone 1 --hostfile /tmp/hostfile.\$LSB_JOBID --np \$CPUS $cmalignPath --mpi $opts -o $lustre_alnfile $lustre_cmfile $lustre_seqfile > $lustre_outfile";
	
	#Generate a MPI script:
	my $mpiScript = "#!/bin/bash
# An OPENMPI LSF script for running cmalign
# Submit this script via bsub to use.
 
# Parse the LSF hostlist into a format openmpi understands and find the number of CPUs we are running on.
echo \$LSB_MCPU_HOSTS | awk '{for(i=1;i <=NF;i=i+2) print \$i \" slots=\" \$(i+1); }' >> /tmp/hostfile.\$LSB_JOBID
CPUS=`echo \$LSB_MCPU_HOSTS | awk '{for(i=2;i <=NF;i=i+2) { tot+=\$i; } print tot }'` 

# Now run our executable 
$alignCommand
";
	my $mpiScriptFile = $lustre . '/' . $$ . '_cmalign_mpi_script.sh'; #be cleverer here
	open(MS, "> $mpiScriptFile") or die "FATAL: failed to open file: $mpiScriptFile\n[$!]";
	print MS $mpiScript;
	close(MS);
	
	chmod 0775,  $mpiScriptFile or die "FATAL: failed to run [chmod 0775,  $mpiScriptFile]\n[$!]";
	
	my $mpiScriptOut =  $$ . '_cmalign_mpi_script.out';
	my $bjobName = "cmaln" . $$ . hostname;
	my $bsubOpts = "-o $lustre/$mpiScriptOut -q mpi  -J\"$bjobName\" -n$cpus -a openmpi -R \'select[mem>$requiredMb] rusage[mem=$requiredMb]\' -M $requiredKb";
	
	print "Running: bsub $bsubOpts $mpiScriptFile\n";
	system("bsub $bsubOpts $mpiScriptFile > $lustre/$mpiScriptOut\.std") and die "FATAL: failed to run to run: bsub $bsubOpts $mpiScriptFile\n[$!]";
	Bio::Rfam::Utils::wait_for_farm($bjobName, 'cmalign', $cpus, 100*$estimatedWallSeconds+120, undef ); #100*$estimatedWallSeconds() our timing estimates may be way off because job may be PENDING for a long time
	push(@unlinkA, $lustre_alnfile);
	push(@unlinkA, $lustre_outfile);
	
	#copy("$lustre/$mpiScriptOut", "$pwd/$mpiScriptOut") or die "FATAL: failed to copy $lustre/$mpiScriptOut to $pwd/$mpiScriptOut\n[$!]";
	
	open(OUT, "< $lustre/$mpiScriptOut") or die "FATAL: failed to open $lustre/$mpiScriptOut for reading\n[$!]";

	copy("$lustre_alnfile",  "$alnfile") or die "FATAL: failed to copy [$lustre_alnfile] to [$alnfile]\n[$!]";
	copy("$lustre_outfile",  "$outfile") or die "FATAL: failed to copy [$lustre_outfile] to [$outfile]\n[$!]";
    }	
    my $alignTime=0;
    while(<OUT>){
	if(/\#\s+CPU\s+time\:\s+(\S+)u\s+(\S+)s/){
	    $alignTime=$1+$2;
	    last;
	}
    }
    close(OUT);

    # clean up
    if(! $dirty) { 
	foreach my $file (@unlinkA) { 
	    unlink $file;
	}
    }

    $alignTime *= $cpus;
    return $alignTime;
}

######################################################################

=head1 AUTHOR

Sarah Burge, swb@ebi.ac.uk

=head1 COPYRIGHT

Copyright (c) 2013: European Bioinformatics Institute

Authors: Sarah Burge swb@ebi.ac.uk

This is based on code taken from the Rfam modules at the Sanger institute.

This is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.

=cut

1;



