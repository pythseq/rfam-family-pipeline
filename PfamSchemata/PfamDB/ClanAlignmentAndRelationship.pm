use utf8;
package PfamDB::ClanAlignmentAndRelationship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PfamDB::ClanAlignmentAndRelationship

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<clan_alignment_and_relationship>

=cut

__PACKAGE__->table("clan_alignment_and_relationship");

=head1 ACCESSORS

=head2 clan_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 6

=head2 alignment

  data_type: 'longblob'
  is_nullable: 1

=head2 relationship

  data_type: 'longblob'
  is_nullable: 1

=head2 image_map

  data_type: 'blob'
  is_nullable: 1

=head2 stockholm

  data_type: 'longblob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "clan_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 6 },
  "alignment",
  { data_type => "longblob", is_nullable => 1 },
  "relationship",
  { data_type => "longblob", is_nullable => 1 },
  "image_map",
  { data_type => "blob", is_nullable => 1 },
  "stockholm",
  { data_type => "longblob", is_nullable => 1 },
);

=head1 RELATIONS

=head2 clan_acc

Type: belongs_to

Related object: L<PfamDB::Clan>

=cut

__PACKAGE__->belongs_to("clan_acc", "PfamDB::Clan", { clan_acc => "clan_acc" });


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-22 10:42:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nu3S+EBeSesqCeqjDL19BQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
