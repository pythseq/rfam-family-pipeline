
# $Id: Seq_info.pm,v 1.3 2007-03-08 14:16:28 jt6 Exp $
#
# $Author: jt6 $

package PfamDB::Seq_info;

use strict;
use warnings;

# I think this table should join to everything that pfamseq joins to,
# because it's indexed with the same auto_pfamseq number... I could be
# very wrong about this though...
# jt6 20060810 WTSI

use base "DBIx::Class";

__PACKAGE__->load_components( qw/Core/ );

#Set up the table
__PACKAGE__->table( "seq_info" );

#Get the columns that we want to keep
__PACKAGE__->add_columns( qw/auto_pfamseq pfamseq_id pfamseq_acc description seq_description species pfamA_acc pfamA_id/);

#Set the the keys
__PACKAGE__->set_primary_key( "auto_pfamseq" );



#Now Set up the relationships

#Tables that pfamseq joins onto: pfamA_reg_full, pfamA_reg_seed, pfamB_reg,  context_pfam_regions, architecture, genome_pfamseq,  genome_seqs, pfamseq_architecture, pfam_annseq, pfamseq_disulphide, pfamseq_markup, pfamseq_ncbi, secondary_pfamseq_acc, seq_info, smart_regions, msd_data, other_reg


#Do all of the annotated regions

##pfamA_reg_full
__PACKAGE__->has_many("pfamA_reg_full",  => "PfamDB::PfamA_reg_full",
		      {"foreign.auto_pfamseq" => "self.auto_pfamseq"} );

##pfamA_reg_seed
__PACKAGE__->has_many("pfamA_reg_seed",  => "PfamDB::PfamA_reg_seed",
		      {"foreign.auto_pfamseq" => "self.auto_pfamseq"} );

##pfamB_reg_seed
__PACKAGE__->has_many("pfamB_reg",  => "PfamDB::PfamB_reg",
		      {"foreign.auto_pfamseq" => "self.auto_pfamseq"} );

##smart_regions
__PACKAGE__->has_many("smart_reg",  => "PfamDB::Smart_reg",
		      {"foreign.auto_pfamseq" => "self.auto_pfamseq"} );

##context_pfam_regions
__PACKAGE__->has_many("context",  => "PfamDB::Context_pfam_regions",
		      {"foreign.auto_pfamseq" => "self.auto_pfamseq"} );


##other_reg
__PACKAGE__->has_many("other_reg", => "PfamDB::Other_reg",
		      {"foreign.auto_pfamseq" => "self.auto_pfamseq"});

#Now Sequence features

##pfamseq_disulphide
__PACKAGE__->has_many("disulphide", => "PfamDB::Pfamseq_disulphide",
		      {"foreign.auto_pfamseq" => "self.auto_pfamseq"});

##pfamseq_markup
__PACKAGE__->has_many("markup", => "PfamDB::Pfamseq_markup",
		      {"foreign.auto_pfamseq" => "self.auto_pfamseq"});

#Now views

##architecture
__PACKAGE__->has_one("arch_eg", => "PfamDB::Architecture",
		     {"foreign.type_example" => "self.auto_pfamseq"},
		     {proxy => [qw/architecture type_example no_seqs/]});

#pfam_annseq
__PACKAGE__->has_one("annseq" => "PfamDB::Pfam_annseq",
		     {"foreign.auto_pfamseq" => "self.auto_pfamseq"},
		     {proxy => [qw/annseq_storable/]});
#Other
#msd_data
__PACKAGE__->might_have( "pdb_residue" => "PfamDB::Pdb_residue",
						 { "foreign.auto_pfamseq" => "self.auto_pfamseq" } );

#Genome Stuff - todo



#Things that should be removed once some rationale is applied - We should then just be able to add the column name, but the call should be the same;
##pfamseq_ncbi
__PACKAGE__->has_one("ncbi", => "PfamDB::Pfamseq_ncbi",
		     {"foreign.auto_pfamseq" => "self.auto_pfamseq"},
		     { proxy => [qw/ncbi_code/]});

##pfamseq_architecture
__PACKAGE__->has_one("arch" =>  "PfamDB::Pfamseq_architecture",
		     {"foreign.type_example" => "self.auto_pfamseq"},
		     { proxy => [qw/architecture/]});
##Storable
#'__PACKAGE__->has_one("pfamseqStorable" =>  "PfamDB::Pfam_annseq",
#		     {"foreign.auto_pfamseq" => "self.auto_pfamseq"},
#		     { proxy => [qw/annseq_storable/]});
