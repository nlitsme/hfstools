#!perl -w
use strict;
use Harddisk;
use HFSVolume;

sub testrealdisk {
    my $hd= Harddisk->new("/dev/rdisk0s2");
    my $vol= HFSVolume->fromdisk($hd);
}

sub testfiles {
    my $hd= Harddisk->new("/dev/rdisk0s2");
    my $catalogFile= IO::File->new("cat.btree", "r") or die "cat.btree:$!\n";
    binmode $catalogFile;
    my $extentsFile= IO::File->new("extents.btree", "r") or die "extents.btree:$!\n";
    binmode $extentsFile;
    my $allocFile= IO::File->new("alloc.bitmap", "r") or die "alloc.bitmap:$!\n";
    binmode $allocFile;
    my $volhdrFile= IO::File->new("volhdr.nb", "r") or die "volhdr.nb:$!\n";
    binmode $volhdrFile;
    my $volhdr;
    $volhdrFile->read($volhdr, 0x200);
    $volhdrFile->close();
    my $vol= HFSVolume->new(
        catalogFile=>$catalogFile,
        extentsFile=>$extentsFile,
        allocFile=>$allocFile,
        volhdr=>$volhdr,
        disk=>$hd
    );
}
