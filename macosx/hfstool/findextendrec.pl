#!perl -w
use strict;
$|=1;
# see http://developer.apple.com/technotes/tn/tn1150.html
# or http://fxr.watson.org/fxr/source/bsd/hfs/hfs_format.h?v=xnu-792
sub opendisk {
    open HD, '</dev/disk0s2' or die qq(disk0s2: $!);
    binmode HD;
}
sub closedisk {
    close HD;
}
sub readSector {
    my ($sectornr, $n)= @_;
    $n=1 unless defined $n;
    return "" if $n==0;
    sysseek(HD, $sectornr*0x200, 0) or die "invalid sector $sectornr";
    my $data;
    sysread(HD,$data,0x200*$n) or die "error reading sector $sectornr";
    return $data;
}
my %tests= (
"\x00\x0a\x00\x00\x00\x07\xed\x89\x00\x00\x05\x55"=>0xb,
"\x00\x0a\x00\x00\x00\x07\xed\x8a\x00\x00\x86\x75"=>0x5,
"\x00\x0a\x00\x00\x00\x08\x42\xbf\x00\x00\x03\x45"=>0x2,
"\x00\x0a\x00\x00\x00\x08\x99\x37\x00\x00\x1a\x00"=>0x6,
"\x00\x0a\x00\x00\x00\x12\x08\xb3\x00\x00\x02\x2a"=>0x4,
"\x00\x0a\x00\x00\x00\x12\x12\x00\x00\x00\x1c\x0a"=>0x7,
"\x00\x0a\x00\x00\x00\x12\x72\xfa\x00\x00\x0d\x58"=>0x1,
"\x00\x0a\x00\x00\x00\x12\xa8\x3d\x00\x00\x02\xcc"=>0x9,
"\x00\x0a\x00\x00\x00\x15\x65\x78\x00\x00\x1a\x00"=>0x8,
"\x00\x0a\x00\x00\x00\x19\x12\xaf\x00\x00\x00\x4b"=>0xc,
"\x00\x0a\x00\x00\x00\x19\x12\xaf\x00\x00\x02\xe0"=>0xa,
);
opendisk();
for (my $n=0 ; $n<0x1600000 ; $n++) {
    my $sect= readSector($n*8);
    my $s8= substr($sect,14,12);
    if (exists $tests{$s8}) {
        printf("block %08lx: found node %08lx: %s\n", $n, $tests{$s8}, unpack("H*", substr($sect, 0, 32)));
    }
    if (!($n&0xfff)) {
        printf("%08lx\r", $n);
    }
}

__END__
