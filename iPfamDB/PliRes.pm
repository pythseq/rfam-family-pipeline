package iPfamDB::PliRes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("pli_res");
__PACKAGE__->add_columns(
  "pli",
  { data_type => "INT", default_value => "", is_nullable => 0, size => 10 },
  "protein_acc",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "internal_ligand_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 20 },
  "residue_a",
  { data_type => "INT", default_value => "", is_nullable => 0, size => 10 },
  "residue_b",
  { data_type => "INT", default_value => "", is_nullable => 0, size => 10 },
  "bond",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 50 },
);
__PACKAGE__->belongs_to(
  "protein_acc",
  "iPfamDB::Protein",
  { accession => "protein_acc" },
);
__PACKAGE__->belongs_to(
  "internal_ligand_id",
  "iPfamDB::Ligands",
  { internal_ligand_id => "internal_ligand_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-16 12:00:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EpPWUqx90YCZiTj9L8F6NQ


# You can replace this text with custom content, and it will be preserved on regeneration

=head1 AUTHOR

Prasad Gunasekaran, C<pg6@sanger.ac.uk>

John Tate, C<jt6@sanger.ac.uk>

Rob Finn, C<rdf@sanger.ac.uk>

=head1 COPYRIGHT

Copyright (c) 2007: Genome Research Ltd.

Authors: Rob Finn (rdf@sanger.ac.uk), John Tate (jt6@sanger.ac.uk)

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
