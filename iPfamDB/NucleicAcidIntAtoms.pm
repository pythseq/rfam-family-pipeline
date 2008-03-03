package iPfamDB::NucleicAcidIntAtoms;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("nucleic_acid_int_atoms");
__PACKAGE__->add_columns(
  "nucleic_acid_acc",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
  "atom_number",
  { data_type => "INT", default_value => "", is_nullable => 0, size => 11 },
  "nucleic_acid_id",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
  "base",
  { data_type => "INT", default_value => "", is_nullable => 0, size => 11 },
  "base_name",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 5 },
  "atom",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 3 },
  "atom_acc",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("atom_acc");


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2008-02-26 14:01:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PDERhk1YkB9tSJ4YJZ21/g


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->add_unique_constraint(
    intAtomsConst => [ qw(nucleic_acid_acc atom_number) ],
);
1;
