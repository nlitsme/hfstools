use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";

use Getopt::Long;
use IO::File;
use Harddisk;
use HFSVolume;
use Hexdump;
use Getopt::Long;
my $diskname="/dev/rdisk0s2";
my $offset=0;
my $volhdrname;
my $savehfsfules;
GetOptions(
    "disk=s"=>\$diskname,
    "o=s"=>sub { $offset=eval($_[1]); },
    "volhdr=s"=>\$volhdrname,
    "savehfs"=>\$savehfsfules,
);

my $hd= Harddisk->new($diskname);
my %params;
$params{volhdr}= read_file($volhdrname, binmode=>':raw') if $volhdrname;
$params{startsector}= $offset/0x200;
my $vol= HFSVolume->new($hd, %params);

if ($savehfsfules) {
    $vol->{volhdr}{allocationFile}->save("alloc.bitmap");
    $vol->{volhdr}{extentsFile}->save("ext.btree");
    $vol->{volhdr}{catalogFile}->save("cat.btree");
}
my $bitmap= $vol->calc_alloc_bitmap();
#my $allocbm= Bitmap->new();
#$allocbm->readfromhandle($vol->{volhdr}{allocationFile});
#$bitmap->add($allocbm);

$vol->dump();

if (@ARGV) {
    $bitmap->save(shift);
}
else {
    printf("\nreferenced blocks:\n");
    $bitmap->dump();
    printf("\n");
}

