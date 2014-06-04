use utf8;
package RfamLive::Result::ClanMembership;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

RfamLive::Result::ClanMembership

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<clan_membership>

=cut

__PACKAGE__->table("clan_membership");

=head1 ACCESSORS

=head2 clan_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 7

=head2 rfam_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 7

=cut

__PACKAGE__->add_columns(
  "clan_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 7 },
  "rfam_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 7 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<UniqueFamilyIdx>

=over 4

=item * L</rfam_acc>

=back

=cut

__PACKAGE__->add_unique_constraint("UniqueFamilyIdx", ["rfam_acc"]);

=head1 RELATIONS

=head2 clan_acc

Type: belongs_to

Related object: L<RfamLive::Result::Clan>

=cut

__PACKAGE__->belongs_to(
  "clan_acc",
  "RfamLive::Result::Clan",
  { clan_acc => "clan_acc" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 rfam_acc

Type: belongs_to

Related object: L<RfamLive::Result::Family>

=cut

__PACKAGE__->belongs_to(
  "rfam_acc",
  "RfamLive::Result::Family",
  { rfam_acc => "rfam_acc" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-23 13:50:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cFj5KEfT0UqGFicSF+w4gg

__PACKAGE__->set_primary_key('rfam_acc','clan_acc');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
