use strict;
use warnings;
use Getopt::Long;
use IO::File;
use Harddisk;
use HFSVolume;
use Hexdump;
my $diskname= "/dev/rdisk0s2";
my $savefilename;
# todo: add '-a' to use ascdump instead of hexdump
GetOptions(
    "disk=s"=>\$diskname,
    "o=s"=>\$savefilename,
);
my $hd= Harddisk->new($diskname);
my $vol= HFSVolume->new($hd);

my $oh= IO::File->new($savefilename, "w") or die "$savefilename:$!\n" if ($savefilename);
binmode $oh if ($oh);
for my $arg (@ARGV) {
    printf("---%s\n", $arg);
    if ($arg =~ /^0x/) {
        my $block= eval($arg);
        my $data= $vol->readblock($block);
        hexdump($data) unless ($oh);
        $oh->print($data) if ($oh);
    }
    elsif ($arg =~ /^blk/) {
        my @chunks=split /,/, $arg;
        my $ofs=0;
        for my $chk (@chunks) {
            if ($chk =~ /blk(\w+)(?::(\w+))?/) {
                my ($blk, $cnt)=(hex($1), defined $2?hex($2):1);
                my $data= $vol->readblock($blk, $cnt);
                hexdump($data, $ofs) unless ($oh);
                $oh->print($data) if ($oh);
                $ofs+=$cnt*$vol->blocksize;
            }
        }
    }
}
$oh->close() if ($oh);
