use strict;
use warnings;
use Getopt::Long;
use IO::File;
use Harddisk;
use HFSVolume;
use Hexdump;
use Getopt::Long;
my $diskname="/dev/rdisk0s2";
my $volhdrname;
my $savehfsfules;
GetOptions(
    "disk=s"=>\$diskname,
    "volhdr=s"=>\$volhdrname,
);

my $hd= Harddisk->new($diskname);
my %params;
$params{volhdr}= read_file($volhdrname, binmode=>':raw') if $volhdrname;
my $vol= HFSVolume->new($hd, %params);

my $bitmap= $vol->calc_alloc_bitmap();
my $allocbm= Bitmap->new();
$allocbm->readfromhandle($vol->{volhdr}{allocationFile});
$bitmap->add($allocbm);

$vol->dump();

my $searchpattern= shift;
my $searchedblocks=0;
printf("searching 0x%x blocks\n", $bitmap->size());
# todo: use Bitmap->range_iterate(0) to iterate over unallocated blocks.
# todo: iterate should return ranges.
for (my $blocknr=0 ; $blocknr<$bitmap->size() ; $blocknr++) {
    if (!$bitmap->test($blocknr)) {
        my $data= $vol->readblock($blocknr);
        if (index($data,$searchpattern)>=0) {
            printf("found: %08lx\n", $blocknr);
        }
        $searchedblocks++;
    }
}
printf("searched 0x%x blocks\n", $searchedblocks);
